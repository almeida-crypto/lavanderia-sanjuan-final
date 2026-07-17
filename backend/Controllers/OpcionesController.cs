using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

/// Catálogo global de opciones (ej. "Doblado en Gancho") que un servicio
/// puede ofrecer. Se define una sola vez aquí; cada servicio en
/// ServiciosController solo guarda una referencia a estas filas junto con
/// el precio adicional que le corresponde a ESE servicio.
[ApiController]
[Route("api/opciones")]
public class OpcionesController : ControllerBase
{
    private readonly SupabaseDataService _data;
    public OpcionesController(SupabaseDataService data) => _data = data;

    [HttpGet]
    public async Task<IActionResult> Listar()
    {
        try
        {
            var rows = await _data.ListAsync("opciones", "order=nombre.asc");
            return Ok(rows.OfType<JsonObject>().Select(Map));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] OpcionRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Nombre))
            return BadRequest(new { message = "El nombre es obligatorio" });
        try
        {
            var row = await _data.InsertAsync("opciones", Payload(request));
            return StatusCode(StatusCodes.Status201Created, Map(row));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Actualizar(string id, [FromBody] OpcionRequest request)
    {
        try
        {
            var row = await _data.UpdateAsync("opciones", $"id=eq.{Uri.EscapeDataString(id)}", Payload(request));
            return row is null ? NotFound(new { message = "Opción no encontrada" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    private static JsonObject Payload(OpcionRequest request) => new()
    {
        ["nombre"] = request.Nombre?.Trim(),
        ["descripcion"] = request.Descripcion ?? string.Empty,
        ["activa"] = request.Activa
    };

    private static OpcionDto Map(JsonObject row) => new()
    {
        Id = row["id"]?.ToString() ?? string.Empty,
        Nombre = row["nombre"]?.ToString() ?? string.Empty,
        Descripcion = row["descripcion"]?.ToString() ?? string.Empty,
        Activa = row["activa"]?.GetValue<bool>() ?? true
    };

    private ObjectResult Error(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });
}

public class OpcionRequest
{
    public string? Nombre { get; set; }
    public string? Descripcion { get; set; }
    public bool Activa { get; set; } = true;
}

public class OpcionDto
{
    public string Id { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Activa { get; set; }
}
