using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/metodos-pago")]
public class MetodosPagoController : ControllerBase
{
    private readonly SupabaseDataService _data;

    public MetodosPagoController(SupabaseDataService data) => _data = data;

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? usuarioId)
    {
        if (string.IsNullOrWhiteSpace(usuarioId))
            return BadRequest(new { message = "usuarioId es obligatorio" });

        try
        {
            var rows = await _data.ListAsync(
                "metodos_pago",
                $"usuario_id=eq.{E(usuarioId)}&order=principal.desc,created_at.asc");
            return Ok(rows.OfType<JsonObject>().Select(Map));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] CrearMetodoPagoRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UsuarioId))
            return BadRequest(new { message = "El usuario es obligatorio" });
        if (request.UltimosDigitos?.Length != 4 || !request.UltimosDigitos.All(char.IsDigit))
            return BadRequest(new { message = "Los últimos cuatro dígitos no son válidos" });

        try
        {
            var existing = await _data.ListAsync("metodos_pago", $"usuario_id=eq.{E(request.UsuarioId)}&select=id&limit=1");
            var principal = request.Principal || existing.Count == 0;
            if (principal) await QuitarPrincipal(request.UsuarioId);

            var row = await _data.InsertAsync("metodos_pago", new JsonObject
            {
                ["usuario_id"] = request.UsuarioId,
                ["marca"] = request.Marca?.ToLowerInvariant() == "mastercard" ? "mastercard" : "visa",
                ["ultimos_digitos"] = request.UltimosDigitos,
                ["expira"] = request.Expira,
                ["principal"] = principal
            });
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
            var row = await _data.FindOneAsync("metodos_pago", $"id=eq.{E(id)}&limit=1");
            return row is null ? NotFound(new { message = "Método de pago no encontrado" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}/principal")]
    public async Task<IActionResult> MarcarPrincipal(string id, [FromBody] MarcarPrincipalRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UsuarioId))
            return BadRequest(new { message = "El usuario es obligatorio" });

        try
        {
            await QuitarPrincipal(request.UsuarioId);
            var row = await _data.UpdateAsync(
                "metodos_pago",
                $"id=eq.{E(id)}&usuario_id=eq.{E(request.UsuarioId)}",
                new JsonObject { ["principal"] = true });
            return row is null ? NotFound(new { message = "Método de pago no encontrado" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Eliminar(string id)
    {
        try
        {
            var deleted = await _data.DeleteAsync("metodos_pago", $"id=eq.{E(id)}");
            return deleted ? Ok(new { message = "Método de pago eliminado" }) : NotFound(new { message = "Método de pago no encontrado" });
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    private Task QuitarPrincipal(string usuarioId) => _data.UpdateAsync(
        "metodos_pago",
        $"usuario_id=eq.{E(usuarioId)}&principal=eq.true",
        new JsonObject { ["principal"] = false });

    private static MetodoPagoDto Map(JsonObject row) => new()
    {
        Id = row["id"]?.ToString(),
        Marca = row["marca"]?.ToString(),
        UltimosDigitos = row["ultimos_digitos"]?.ToString(),
        Expira = row["expira"]?.ToString(),
        Principal = row["principal"]?.GetValue<bool>() ?? false
    };

    private ObjectResult DataError(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });

    private static string E(string value) => Uri.EscapeDataString(value);
}

public class CrearMetodoPagoRequest
{
    public string? UsuarioId { get; set; }
    public string? Marca { get; set; }
    public string? UltimosDigitos { get; set; }
    public string? Expira { get; set; }
    public bool Principal { get; set; }
}

public class MarcarPrincipalRequest
{
    public string? UsuarioId { get; set; }
}

public class MetodoPagoDto
{
    public string? Id { get; set; }
    public string? Marca { get; set; }
    public string? UltimosDigitos { get; set; }
    public string? Expira { get; set; }
    public bool Principal { get; set; }
}
