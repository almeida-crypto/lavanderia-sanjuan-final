using System.Security.Claims;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/promociones")]
public class PromocionesController : ControllerBase
{
    private readonly SupabaseDataService _data;
    private readonly PromocionValidationService _validacion;

    public PromocionesController(SupabaseDataService data, PromocionValidationService validacion)
    {
        _data = data;
        _validacion = validacion;
    }

    private string? CallerId => User.FindFirstValue(ClaimTypes.NameIdentifier);
    private string? CallerRol => User.FindFirstValue(ClaimTypes.Role);
    private bool EsStaff => CallerRol is "administrador" or "empleado";

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

    /// El cliente llama esto antes de pagar para saber si su código sirve
    /// (vigencia, servicio, cantidad mínima y usos por cliente); PedidosController
    /// vuelve a llamar la misma validación al crear el pedido de verdad, para
    /// que no baste con pasar este chequeo una vez y luego colarse.
    [HttpPost("validar")]
    [Authorize]
    public async Task<IActionResult> Validar([FromBody] ValidarPromoRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo))
        {
            return BadRequest(new { message = "Código requerido" });
        }

        var clienteId = CallerId;
        if (EsStaff && !string.IsNullOrWhiteSpace(request.ClienteId))
        {
            clienteId = request.ClienteId;
        }
        if (string.IsNullOrWhiteSpace(clienteId))
        {
            return BadRequest(new { message = "No se pudo identificar al cliente" });
        }

        try
        {
            var resultado = await _validacion.ValidarAsync(request.Codigo, clienteId, request.Servicio, request.Cantidad);
            if (!resultado.Success)
            {
                return BadRequest(new { message = resultado.ErrorMessage });
            }
            return Ok(Map(resultado.Promocion!));
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
        if (request.UsosPorCliente is not null && request.UsosPorCliente <= 0)
            return BadRequest(new { message = "Los usos por cliente deben ser mayores a 0" });
        if (request.CantidadMinima is not null && request.CantidadMinima <= 0)
            return BadRequest(new { message = "La cantidad mínima debe ser mayor a 0" });
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
        if (request.UsosPorCliente is not null && request.UsosPorCliente <= 0)
            return BadRequest(new { message = "Los usos por cliente deben ser mayores a 0" });
        if (request.CantidadMinima is not null && request.CantidadMinima <= 0)
            return BadRequest(new { message = "La cantidad mínima debe ser mayor a 0" });
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
        ["imagen_url"] = request.ImagenUrl,
        ["descuento_porcentaje"] = request.DescuentoPorcentaje,
        ["servicio_aplicable"] = string.IsNullOrWhiteSpace(request.ServicioAplicable) ? null : request.ServicioAplicable!.Trim(),
        ["fecha_inicio"] = request.FechaInicio ?? DateTime.UtcNow.ToString("O"),
        ["fecha_fin"] = request.FechaFin,
        ["activa"] = request.Activa,
        ["usos_por_cliente"] = request.UsosPorCliente,
        ["cantidad_minima"] = request.CantidadMinima
    };

    private static PromocionDto Map(JsonObject row) => new()
    {
        Id = row["id"]?.ToString() ?? string.Empty,
        Codigo = row["codigo"]?.ToString() ?? string.Empty,
        Titulo = row["titulo"]?.ToString() ?? string.Empty,
        Descripcion = row["descripcion"]?.ToString() ?? string.Empty,
        ImagenUrl = row["imagen_url"]?.ToString(),
        DescuentoPorcentaje = double.TryParse(row["descuento_porcentaje"]?.ToString(), out var descuento) ? descuento : 0,
        ServicioAplicable = row["servicio_aplicable"]?.ToString(),
        FechaInicio = row["fecha_inicio"]?.ToString() ?? string.Empty,
        FechaFin = row["fecha_fin"]?.ToString(),
        Activa = row["activa"]?.GetValue<bool>() ?? true,
        UsosPorCliente = int.TryParse(row["usos_por_cliente"]?.ToString(), out var upc) ? upc : null,
        CantidadMinima = int.TryParse(row["cantidad_minima"]?.ToString(), out var cm) ? cm : null
    };

    private ObjectResult Error(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });
}

public class PromocionRequest
{
    public string? Codigo { get; set; }
    public string? Titulo { get; set; }
    public string? Descripcion { get; set; }
    public string? ImagenUrl { get; set; }
    public double DescuentoPorcentaje { get; set; }
    public string? ServicioAplicable { get; set; }
    public string? FechaInicio { get; set; }
    public string? FechaFin { get; set; }
    public bool Activa { get; set; } = true;
    public int? UsosPorCliente { get; set; }
    public int? CantidadMinima { get; set; }
}

public class ValidarPromoRequest
{
    public string? Codigo { get; set; }
    public string? Servicio { get; set; }
    public int? Cantidad { get; set; }

    /// Solo staff puede mandar esto (para validar en nombre de un cliente);
    /// un cliente siempre se valida contra su propio id, sin importar qué
    /// mande aquí.
    public string? ClienteId { get; set; }
}

public class PromocionDto
{
    public string Id { get; set; } = string.Empty;
    public string Codigo { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string? ImagenUrl { get; set; }
    public double DescuentoPorcentaje { get; set; }
    public string? ServicioAplicable { get; set; }
    public string FechaInicio { get; set; } = string.Empty;
    public string? FechaFin { get; set; }
    public bool Activa { get; set; }
    public int? UsosPorCliente { get; set; }
    public int? CantidadMinima { get; set; }
}
