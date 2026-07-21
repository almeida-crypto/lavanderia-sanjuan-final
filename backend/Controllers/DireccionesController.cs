using System.Security.Claims;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/direcciones")]
[Authorize]
public class DireccionesController : ControllerBase
{
    private readonly SupabaseDataService _data;

    public DireccionesController(SupabaseDataService data) => _data = data;

    private string? CallerId => User.FindFirstValue(ClaimTypes.NameIdentifier);

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? usuarioId)
    {
        if (string.IsNullOrWhiteSpace(usuarioId))
            return BadRequest(new { message = "usuarioId es obligatorio" });
        if (usuarioId != CallerId)
            return Forbid();

        try
        {
            var rows = await _data.ListAsync(
                "direcciones",
                $"usuario_id=eq.{E(usuarioId)}&order=predeterminada.desc,created_at.asc");
            return Ok(rows.OfType<JsonObject>().Select(Map));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] CrearDireccionRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UsuarioId))
            return BadRequest(new { message = "El usuario es obligatorio" });
        if (request.UsuarioId != CallerId)
            return Forbid();
        if (string.IsNullOrWhiteSpace(request.Calle) || string.IsNullOrWhiteSpace(request.Colonia) ||
            string.IsNullOrWhiteSpace(request.Ciudad) || string.IsNullOrWhiteSpace(request.Estado) ||
            string.IsNullOrWhiteSpace(request.CodigoPostal))
            return BadRequest(new { message = "Calle, colonia, ciudad, estado y código postal son obligatorios" });

        try
        {
            var errorUbicacion = await ValidarUbicacionAsync(request);
            if (errorUbicacion is not null) return BadRequest(new { message = errorUbicacion });

            if (request.Predeterminada)
                await QuitarPredeterminada(request.UsuarioId);

            var row = await _data.InsertAsync("direcciones", Payload(request));
            var dto = Map(row);
            return CreatedAtAction(nameof(Obtener), new { id = dto.Id }, dto);
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Obtener(string id)
    {
        try
        {
            var row = await _data.FindOneAsync("direcciones", $"id=eq.{E(id)}&limit=1");
            if (row is null) return NotFound(new { message = "Dirección no encontrada" });
            if (row["usuario_id"]?.ToString() != CallerId) return NotFound(new { message = "Dirección no encontrada" });
            return Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Actualizar(string id, [FromBody] CrearDireccionRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UsuarioId))
            return BadRequest(new { message = "El usuario es obligatorio" });
        if (request.UsuarioId != CallerId)
            return Forbid();

        try
        {
            var errorUbicacion = await ValidarUbicacionAsync(request);
            if (errorUbicacion is not null) return BadRequest(new { message = errorUbicacion });

            var existente = await _data.FindOneAsync("direcciones", $"id=eq.{E(id)}&limit=1");
            if (existente is null) return NotFound(new { message = "Dirección no encontrada" });
            if (existente["usuario_id"]?.ToString() != CallerId) return NotFound(new { message = "Dirección no encontrada" });

            if (request.Predeterminada)
                await QuitarPredeterminada(request.UsuarioId);

            var row = await _data.UpdateAsync("direcciones", $"id=eq.{E(id)}", Payload(request));
            return row is null ? NotFound(new { message = "Dirección no encontrada" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Eliminar(string id)
    {
        try
        {
            var existente = await _data.FindOneAsync("direcciones", $"id=eq.{E(id)}&limit=1");
            if (existente is null) return NotFound(new { message = "Dirección no encontrada" });
            if (existente["usuario_id"]?.ToString() != CallerId) return NotFound(new { message = "Dirección no encontrada" });

            var deleted = await _data.DeleteAsync("direcciones", $"id=eq.{E(id)}");
            return deleted ? Ok(new { message = "Dirección eliminada" }) : NotFound(new { message = "Dirección no encontrada" });
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    private Task QuitarPredeterminada(string usuarioId) => _data.UpdateAsync(
        "direcciones",
        $"usuario_id=eq.{E(usuarioId)}&predeterminada=eq.true",
        new JsonObject { ["predeterminada"] = false });

    private async Task<string?> ValidarUbicacionAsync(CrearDireccionRequest request)
    {
        var cp = request.CodigoPostal?.Trim() ?? string.Empty;
        if (cp.Length != 5 || !cp.All(char.IsDigit))
            return "El código postal debe tener 5 dígitos";

        var registros = await _data.ListAsync(
            "codigos_postales",
            $"codigo_postal=eq.{E(cp)}&select=estado,municipio,ciudad,colonia&limit=500");
        var filas = registros.OfType<JsonObject>().ToList();
        if (filas.Count == 0) return "El código postal no existe";

        static bool Igual(string? a, string? b) =>
            string.Equals(a?.Trim(), b?.Trim(), StringComparison.OrdinalIgnoreCase);

        if (!filas.Any(f => Igual(f["colonia"]?.ToString(), request.Colonia)))
            return "La colonia no corresponde al código postal";
        if (!filas.Any(f => Igual(f["estado"]?.ToString(), request.Estado)))
            return "El estado no corresponde al código postal";
        if (!filas.Any(f => Igual(f["municipio"]?.ToString(), request.Ciudad) ||
                          Igual(f["ciudad"]?.ToString(), request.Ciudad)))
            return "La ciudad o municipio no corresponde al código postal";
        return null;
    }

    private static JsonObject Payload(CrearDireccionRequest request) => new()
    {
        ["usuario_id"] = request.UsuarioId,
        ["titulo"] = string.IsNullOrWhiteSpace(request.Titulo) ? "Nueva dirección" : request.Titulo.Trim(),
        ["calle"] = request.Calle?.Trim() ?? string.Empty,
        ["depto"] = request.Depto,
        ["colonia"] = request.Colonia?.Trim() ?? string.Empty,
        ["entre_calles"] = request.EntreCalles,
        ["ciudad"] = request.Ciudad?.Trim() ?? string.Empty,
        ["estado"] = request.Estado?.Trim() ?? string.Empty,
        ["codigo_postal"] = request.CodigoPostal?.Trim() ?? string.Empty,
        ["telefono"] = request.Telefono,
        ["nota"] = request.Nota,
        ["predeterminada"] = request.Predeterminada
    };

    private static DireccionDto Map(JsonObject row) => new()
    {
        Id = row["id"]?.ToString(),
        Titulo = row["titulo"]?.ToString(),
        Calle = row["calle"]?.ToString() ?? string.Empty,
        Depto = row["depto"]?.ToString(),
        Colonia = row["colonia"]?.ToString() ?? string.Empty,
        EntreCalles = row["entre_calles"]?.ToString(),
        Ciudad = row["ciudad"]?.ToString() ?? string.Empty,
        Estado = row["estado"]?.ToString() ?? string.Empty,
        CodigoPostal = row["codigo_postal"]?.ToString() ?? string.Empty,
        Telefono = row["telefono"]?.ToString(),
        Nota = row["nota"]?.ToString(),
        Predeterminada = row["predeterminada"]?.GetValue<bool>() ?? false
    };

    private ObjectResult DataError(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });

    private static string E(string value) => Uri.EscapeDataString(value);
}

public class CrearDireccionRequest
{
    public string? UsuarioId { get; set; }
    public string? Titulo { get; set; }
    public string? Calle { get; set; }
    public string? Depto { get; set; }
    public string? Colonia { get; set; }
    public string? EntreCalles { get; set; }
    public string? Ciudad { get; set; }
    public string? Estado { get; set; }
    public string? CodigoPostal { get; set; }
    public string? Telefono { get; set; }
    public string? Nota { get; set; }
    public bool Predeterminada { get; set; }
}

public class DireccionDto
{
    public string? Id { get; set; }
    public string? Titulo { get; set; }
    public string Calle { get; set; } = string.Empty;
    public string? Depto { get; set; }
    public string Colonia { get; set; } = string.Empty;
    public string? EntreCalles { get; set; }
    public string Ciudad { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string CodigoPostal { get; set; } = string.Empty;
    public string? Telefono { get; set; }
    public string? Nota { get; set; }
    public bool Predeterminada { get; set; }
}
