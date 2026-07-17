using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/direcciones")]
public class DireccionesController : ControllerBase
{
    private readonly SupabaseDataService _data;

    public DireccionesController(SupabaseDataService data) => _data = data;

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? usuarioId)
    {
        if (string.IsNullOrWhiteSpace(usuarioId))
            return BadRequest(new { message = "usuarioId es obligatorio" });

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
        if (request.Lineas is null || request.Lineas.Count == 0)
            return BadRequest(new { message = "La dirección es obligatoria" });

        try
        {
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
            return row is null ? NotFound(new { message = "Dirección no encontrada" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Actualizar(string id, [FromBody] CrearDireccionRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UsuarioId))
            return BadRequest(new { message = "El usuario es obligatorio" });

        try
        {
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
            var deleted = await _data.DeleteAsync("direcciones", $"id=eq.{E(id)}");
            return deleted ? Ok(new { message = "Dirección eliminada" }) : NotFound(new { message = "Dirección no encontrada" });
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    private Task QuitarPredeterminada(string usuarioId) => _data.UpdateAsync(
        "direcciones",
        $"usuario_id=eq.{E(usuarioId)}&predeterminada=eq.true",
        new JsonObject { ["predeterminada"] = false });

    private static JsonObject Payload(CrearDireccionRequest request) => new()
    {
        ["usuario_id"] = request.UsuarioId,
        ["titulo"] = string.IsNullOrWhiteSpace(request.Titulo) ? "Nueva dirección" : request.Titulo.Trim(),
        ["lineas"] = new JsonArray(
            (request.Lineas ?? []).Select(value => (JsonNode?)JsonValue.Create(value)).ToArray()),
        ["telefono"] = request.Telefono,
        ["nota"] = request.Nota,
        ["predeterminada"] = request.Predeterminada
    };

    private static DireccionDto Map(JsonObject row) => new()
    {
        Id = row["id"]?.ToString(),
        Titulo = row["titulo"]?.ToString(),
        Lineas = row["lineas"] is JsonArray lines ? lines.Select(x => x?.ToString() ?? "").ToList() : [],
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
    public List<string>? Lineas { get; set; }
    public string? Telefono { get; set; }
    public string? Nota { get; set; }
    public bool Predeterminada { get; set; }
}

public class DireccionDto
{
    public string? Id { get; set; }
    public string? Titulo { get; set; }
    public List<string>? Lineas { get; set; }
    public string? Telefono { get; set; }
    public string? Nota { get; set; }
    public bool Predeterminada { get; set; }
}
