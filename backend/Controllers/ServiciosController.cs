using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/servicios")]
public class ServiciosController : ControllerBase
{
    private readonly SupabaseDataService _data;
    public ServiciosController(SupabaseDataService data) => _data = data;

    [HttpGet]
    public async Task<IActionResult> Listar()
    {
        try
        {
            var rows = await _data.ListAsync("servicios", "order=created_at.asc");
            return Ok(rows.OfType<JsonObject>().Select(Map));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] ServicioRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Nombre) || request.Precio < 0)
            return BadRequest(new { message = "Nombre y precio son obligatorios" });
        try
        {
            var row = await _data.InsertAsync("servicios", Payload(request));
            return StatusCode(StatusCodes.Status201Created, Map(row));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Actualizar(string id, [FromBody] ServicioRequest request)
    {
        try
        {
            var row = await _data.UpdateAsync("servicios", $"id=eq.{Uri.EscapeDataString(id)}", Payload(request));
            return row is null ? NotFound(new { message = "Servicio no encontrado" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return Error(ex); }
    }

    private static JsonObject Payload(ServicioRequest request) => new()
    {
        ["nombre"] = request.Nombre?.Trim(),
        ["icono"] = request.Icono ?? "local_laundry_service",
        ["precio"] = request.Precio,
        ["unidad"] = request.Unidad ?? "kg",
        ["descripcion"] = request.Descripcion ?? string.Empty,
        ["activo"] = request.Activo,
        ["como_funciona"] = request.ComoFunciona ?? string.Empty,
        ["tiempo_estimado"] = request.TiempoEstimado ?? string.Empty,
        ["items_sugeridos"] = JsonSerializer.SerializeToNode(request.ItemsSugeridos ?? []),
        ["beneficios"] = JsonSerializer.SerializeToNode(request.Beneficios ?? []),
        ["opciones_acabado"] = JsonSerializer.SerializeToNode(request.OpcionesAcabado ?? [])
    };

    private static ServicioDto Map(JsonObject row) => new()
    {
        Id = row["id"]?.ToString() ?? string.Empty,
        Nombre = row["nombre"]?.ToString() ?? "Servicio",
        Icono = row["icono"]?.ToString() ?? "local_laundry_service",
        Precio = double.TryParse(row["precio"]?.ToString(), out var precio) ? precio : 0,
        Unidad = row["unidad"]?.ToString() ?? "kg",
        Descripcion = row["descripcion"]?.ToString() ?? string.Empty,
        Activo = row["activo"]?.GetValue<bool>() ?? true,
        ComoFunciona = row["como_funciona"]?.ToString() ?? string.Empty,
        TiempoEstimado = row["tiempo_estimado"]?.ToString() ?? string.Empty,
        ItemsSugeridos = row["items_sugeridos"]?.Deserialize<List<string>>() ?? [],
        Beneficios = row["beneficios"]?.Deserialize<List<BeneficioServicioDto>>() ?? [],
        OpcionesAcabado = row["opciones_acabado"]?.Deserialize<List<OpcionAcabadoDto>>() ?? []
    };

    private ObjectResult Error(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });
}

public class ServicioRequest
{
    public string? Nombre { get; set; }
    public string? Icono { get; set; }
    public double Precio { get; set; }
    public string? Unidad { get; set; }
    public string? Descripcion { get; set; }
    public bool Activo { get; set; } = true;
    public string? ComoFunciona { get; set; }
    public string? TiempoEstimado { get; set; }
    public List<string>? ItemsSugeridos { get; set; }
    public List<BeneficioServicioDto>? Beneficios { get; set; }
    public List<OpcionAcabadoDto>? OpcionesAcabado { get; set; }
}

public class ServicioDto
{
    public string Id { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Icono { get; set; } = string.Empty;
    public double Precio { get; set; }
    public string Unidad { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Activo { get; set; }
    public string ComoFunciona { get; set; } = string.Empty;
    public string TiempoEstimado { get; set; } = string.Empty;
    public List<string> ItemsSugeridos { get; set; } = [];
    public List<BeneficioServicioDto> Beneficios { get; set; } = [];
    public List<OpcionAcabadoDto> OpcionesAcabado { get; set; } = [];
}

public class BeneficioServicioDto
{
    public string Icono { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
}

/// Cubre tanto "opciones de doblado"/"modo de entrega" como niveles de
/// tarifa (ej. Básica/Premium/Luxury): todas son una opción con un cargo
/// adicional sobre el precio base que el cliente elige antes de agendar.
public class OpcionAcabadoDto
{
    public string Nombre { get; set; } = string.Empty;
    public double PrecioAdicional { get; set; }
    public string Descripcion { get; set; } = string.Empty;
}
