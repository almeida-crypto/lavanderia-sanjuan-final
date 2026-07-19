using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/promociones")]
public class PromocionesController : ControllerBase
{
    private readonly SupabaseDataService _data;
    public PromocionesController(SupabaseDataService data) => _data = data;

    [HttpGet]
    public async Task<IActionResult> Listar()
    {
        try
        {
            var rows = await _data.ListAsync("promociones", "order=created_at.desc");
            return Ok(rows.OfType<JsonObject>().Select(Map));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    [HttpPost]
    [Authorize(Roles = "administrador")]
    public async Task<IActionResult> Crear([FromBody] PromocionRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Titulo))
            return BadRequest(new { message = "El código y el título son obligatorios" });
        if (request.DescuentoPorcentaje < 0 || request.DescuentoPorcentaje > 100)
            return BadRequest(new { message = "El descuento debe estar entre 0 y 100" });
        try
        {
            var row = await _data.InsertAsync("promociones", Payload(request));
            return StatusCode(StatusCodes.Status201Created, Map(row));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "administrador")]
    public async Task<IActionResult> Actualizar(string id, [FromBody] PromocionRequest request)
    {
        try
        {
            var row = await _data.UpdateAsync("promociones", $"id=eq.{Uri.EscapeDataString(id)}", Payload(request));
            return row is null ? NotFound(new { message = "Promoción no encontrada" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    private static JsonObject Payload(PromocionRequest request) => new()
    {
        ["codigo"] = request.Codigo?.Trim().ToUpperInvariant(),
        ["titulo"] = request.Titulo?.Trim(),
        ["descripcion"] = request.Descripcion ?? string.Empty,
        ["descuento_porcentaje"] = request.DescuentoPorcentaje,
        ["servicio_aplicable"] = string.IsNullOrWhiteSpace(request.ServicioAplicable) ? null : request.ServicioAplicable!.Trim(),
        ["fecha_inicio"] = request.FechaInicio ?? DateTime.UtcNow.ToString("O"),
        ["fecha_fin"] = request.FechaFin,
        ["activa"] = request.Activa
    };

    private static PromocionDto Map(JsonObject row) => new()
    {
        Id = row["id"]?.ToString() ?? string.Empty,
        Codigo = row["codigo"]?.ToString() ?? string.Empty,
        Titulo = row["titulo"]?.ToString() ?? string.Empty,
        Descripcion = row["descripcion"]?.ToString() ?? string.Empty,
        DescuentoPorcentaje = double.TryParse(row["descuento_porcentaje"]?.ToString(), out var descuento) ? descuento : 0,
        ServicioAplicable = row["servicio_aplicable"]?.ToString(),
        FechaInicio = row["fecha_inicio"]?.ToString() ?? string.Empty,
        FechaFin = row["fecha_fin"]?.ToString(),
        Activa = row["activa"]?.GetValue<bool>() ?? true
    };

    private ObjectResult Error(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });
}

public class PromocionRequest
{
    public string? Codigo { get; set; }
    public string? Titulo { get; set; }
    public string? Descripcion { get; set; }
    public double DescuentoPorcentaje { get; set; }
    public string? ServicioAplicable { get; set; }
    public string? FechaInicio { get; set; }
    public string? FechaFin { get; set; }
    public bool Activa { get; set; } = true;
}

public class PromocionDto
{
    public string Id { get; set; } = string.Empty;
    public string Codigo { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public double DescuentoPorcentaje { get; set; }
    public string? ServicioAplicable { get; set; }
    public string FechaInicio { get; set; } = string.Empty;
    public string? FechaFin { get; set; }
    public bool Activa { get; set; }
}
