using System.Security.Claims;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PedidosController : ControllerBase
{
    private readonly SupabaseDataService _data;
    private readonly PromocionValidationService _validacionPromo;

    public PedidosController(SupabaseDataService data, PromocionValidationService validacionPromo)
    {
        _data = data;
        _validacionPromo = validacionPromo;
    }

    private string? CallerId => User.FindFirstValue(ClaimTypes.NameIdentifier);
    private string? CallerRol => User.FindFirstValue(ClaimTypes.Role);
    private bool EsStaff => CallerRol is "administrador" or "empleado";

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? clienteId)
    {
        try
        {
            // Un cliente solo puede listar sus propios pedidos, sin importar
            // qué clienteId haya mandado en la URL. Solo el staff puede ver
            // los de todos (o filtrar por cualquier cliente).
            var idEfectivo = EsStaff ? clienteId : CallerId;
            var filter = string.IsNullOrWhiteSpace(idEfectivo)
                ? "order=created_at.desc"
                : $"cliente_id=eq.{E(idEfectivo)}&order=created_at.desc";
            var rows = await _data.ListAsync("pedidos", filter);
            return Ok(rows.OfType<JsonObject>().Select(Map));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> Obtener(string id)
    {
        try
        {
            var row = await _data.FindOneAsync("pedidos", $"id=eq.{E(id)}&limit=1");
            if (row is null) return NotFound(new { message = "Pedido no encontrado" });
            if (!EsStaff && row["cliente_id"]?.ToString() != CallerId)
            {
                return NotFound(new { message = "Pedido no encontrado" });
            }
            return Ok(Map(row));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] CrearPedidoRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.ClienteId))
            return BadRequest(new { message = "El cliente es obligatorio" });
        if (string.IsNullOrWhiteSpace(request.Servicio))
            return BadRequest(new { message = "El servicio es obligatorio" });

        // Un cliente solo puede crear pedidos a su propio nombre, nunca en
        // nombre de otro usuario.
        if (!EsStaff && request.ClienteId != CallerId)
        {
            return Forbid();
        }

        string? codigoPromocion = null;
        JsonObject? promocionAplicada = null;
        if (!string.IsNullOrWhiteSpace(request.CodigoPromocion))
        {
            // Se vuelve a validar aquí (vigencia, cantidad mínima, usos por
            // cliente) aunque el cliente ya lo haya "aplicado" antes en la
            // pantalla: entre ese momento y el envío del pedido pudo haberse
            // agotado, desactivado o vencido, y no queremos que el total con
            // descuento se cobre sin que el código siga siendo válido.
            try
            {
                var validacion = await _validacionPromo.ValidarAsync(
                    request.CodigoPromocion, request.ClienteId, request.Servicio, request.CantidadAproximada);
                if (!validacion.Success)
                {
                    return BadRequest(new { message = validacion.ErrorMessage });
                }
                codigoPromocion = request.CodigoPromocion.Trim().ToUpperInvariant();
                promocionAplicada = validacion.Promocion;
            }
            catch (SupabaseDataException ex) { return DataError(ex); }
        }

        try
        {
            // El celular muestra una estimación, pero el servidor vuelve a
            // calcular precio, acabado y descuento con la configuración real.
            var servicio = await _data.FindOneAsync(
                "servicios", $"nombre=eq.{E(request.Servicio)}&activo=eq.true&limit=1");
            if (servicio is null)
                return BadRequest(new { message = "El servicio seleccionado ya no está disponible" });

            var precioBase = M(servicio, "precio") ?? 0m;
            var cantidad = Math.Max(request.CantidadAproximada ?? 1, 1);
            var precioAcabado = 0m;
            if (!string.IsNullOrWhiteSpace(request.OpcionAcabado))
            {
                var opcion = await _data.FindOneAsync(
                    "opciones", $"nombre=eq.{E(request.OpcionAcabado)}&activa=eq.true&limit=1");
                var opcionId = opcion?["id"]?.ToString();
                var referencias = servicio["opciones_acabado"] as JsonArray;
                var referencia = referencias?.OfType<JsonObject>().FirstOrDefault(r =>
                    string.Equals(r["opcionId"]?.ToString(), opcionId, StringComparison.OrdinalIgnoreCase));
                if (opcion is null || referencia is null)
                    return BadRequest(new { message = "La opción de acabado ya no está disponible para este servicio" });
                precioAcabado = M(referencia, "precioAdicional") ?? 0m;
            }

            var subtotal = precioBase * cantidad + precioAcabado;
            var descuento = promocionAplicada is null
                ? 0m
                : Math.Clamp(M(promocionAplicada, "descuento_porcentaje") ?? 0m, 0m, 100m);
            var totalCalculado = Math.Round(
                subtotal * (1m - descuento / 100m), 2, MidpointRounding.AwayFromZero);

            var row = await _data.InsertAsync("pedidos", new JsonObject
            {
                ["cliente_id"] = request.ClienteId,
                ["cliente_nombre"] = request.ClienteNombre ?? "Cliente",
                ["cliente_email"] = request.ClienteEmail,
                ["cliente_telefono"] = request.ClienteTelefono,
                ["servicio"] = request.Servicio,
                ["fecha"] = string.IsNullOrWhiteSpace(request.Fecha) ? DateTime.UtcNow.ToString("O") : request.Fecha,
                ["franja_horaria"] = request.FranjaHoraria ?? "Tarde",
                ["direccion"] = request.Direccion ?? "Sin dirección",
                ["instrucciones"] = request.Instrucciones ?? string.Empty,
                ["fragancia"] = request.Fragancia,
                ["cantidad_aproximada"] = request.CantidadAproximada,
                ["metodo_pago"] = request.MetodoPago,
                ["opcion_acabado"] = request.OpcionAcabado,
                ["precio_acabado"] = precioAcabado,
                ["codigo_promocion"] = codigoPromocion,
                ["total"] = totalCalculado,
                ["estado"] = "Recibido"
            });
            var dto = Map(row);
            return CreatedAtAction(nameof(Obtener), new { id = dto.Id }, dto);
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}/estado")]
    [Authorize(Roles = "administrador,empleado")]
    public Task<IActionResult> ActualizarEstado(string id, [FromBody] ActualizarEstadoRequest request) =>
        UpdatePedido(id, new JsonObject { ["estado"] = request.Estado }, "No se pudo actualizar el estado");

    [HttpPut("{id}/repartidor")]
    [Authorize(Roles = "administrador,empleado")]
    public async Task<IActionResult> AsignarRepartidor(string id, [FromBody] AsignarRepartidorRequest request)
    {
        try
        {
            var current = await _data.FindOneAsync("pedidos", $"id=eq.{E(id)}&limit=1");
            if (current is null) return NotFound(new { message = "Pedido no encontrado" });
            var payload = new JsonObject { ["repartidor"] = request.Repartidor };
            if (current["estado"]?.ToString() == "Recibido") payload["estado"] = "Asignado";
            var row = await _data.UpdateAsync("pedidos", $"id=eq.{E(id)}", payload);
            return Ok(Map(row!));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}/confirmar-precio")]
    [Authorize(Roles = "administrador,empleado")]
    public Task<IActionResult> ConfirmarPrecio(string id, [FromBody] ConfirmarPrecioRequest request) =>
        UpdatePedido(id, new JsonObject
        {
            ["peso_confirmado"] = request.PesoConfirmado,
            ["total_confirmado"] = request.TotalConfirmado
        }, "No se pudo confirmar el precio");

    [HttpPost("{id}/cancelar")]
    public async Task<IActionResult> Cancelar(string id, [FromBody] CancelarPedidoRequest request)
    {
        var bloqueado = await BloqueadoSiNoEsPropioAsync(id);
        if (bloqueado is not null) return bloqueado;

        try
        {
            var actual = await _data.FindOneAsync("pedidos", $"id=eq.{E(id)}&limit=1");
            if (actual is null) return NotFound(new { message = "Pedido no encontrado" });
            var estado = actual["estado"]?.ToString() ?? string.Empty;
            var cancelables = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "Recibido", "Asignado", "Repartidor Asignado"
            };
            if (!cancelables.Contains(estado))
            {
                return Conflict(new
                {
                    message = "Este pedido ya está en una etapa avanzada y no puede cancelarse desde la app. Comunícate con la lavandería."
                });
            }
        }
        catch (SupabaseDataException ex) { return DataError(ex); }

        return await UpdatePedido(id, new JsonObject
        {
            ["estado"] = "Cancelado",
            ["razon_cancelacion"] = request.Razon ?? "Otro",
            ["comentarios_cancelacion"] = request.Comentarios ?? string.Empty
        }, "No se pudo cancelar el pedido");
    }

    [HttpPost("{id}/calificar")]
    public async Task<IActionResult> Calificar(string id, [FromBody] CalificarPedidoRequest request)
    {
        var bloqueado = await BloqueadoSiNoEsPropioAsync(id);
        if (bloqueado is not null) return bloqueado;
        return await UpdatePedido(id, new JsonObject
        {
            ["calificacion"] = request.CalificacionGeneral,
            ["resena"] = request.Resena ?? string.Empty
        }, "No se pudo guardar la calificación");
    }

    [HttpPost("{id}/reportar")]
    public async Task<IActionResult> Reportar(string id, [FromBody] ReportarPedidoRequest request)
    {
        var bloqueado = await BloqueadoSiNoEsPropioAsync(id);
        if (bloqueado is not null) return bloqueado;
        return await UpdatePedido(id, new JsonObject
        {
            ["reporte_tipo"] = request.Tipo ?? "Otro problema",
            ["reporte_detalles"] = request.Detalles ?? string.Empty,
            ["estado"] = "Atención"
        }, "No se pudo guardar el reporte");
    }

    /// Un cliente solo puede cancelar/calificar/reportar SUS PROPIOS pedidos;
    /// el staff puede hacerlo sobre cualquiera. Devuelve null si puede seguir;
    /// si no, ya trae el IActionResult a devolver (404 si no es dueño o no
    /// existe -para no filtrar esa información-, o el error controlado si
    /// falla la consulta a Supabase).
    private async Task<IActionResult?> BloqueadoSiNoEsPropioAsync(string id)
    {
        if (EsStaff) return null;
        try
        {
            var row = await _data.FindOneAsync("pedidos", $"id=eq.{E(id)}&limit=1");
            if (row is not null && row["cliente_id"]?.ToString() == CallerId) return null;
            return NotFound(new { message = "Pedido no encontrado" });
        }
        catch (SupabaseDataException ex)
        {
            return DataError(ex);
        }
    }

    private async Task<IActionResult> UpdatePedido(string id, JsonObject payload, string fallback)
    {
        try
        {
            var row = await _data.UpdateAsync("pedidos", $"id=eq.{E(id)}", payload);
            return row is null ? NotFound(new { message = "Pedido no encontrado" }) : Ok(Map(row));
        }
        catch (SupabaseDataException ex)
        {
            return StatusCode(ex.StatusCode, new { message = string.IsNullOrWhiteSpace(ex.Message) ? fallback : ex.Message });
        }
    }

    private static PedidoDto Map(JsonObject row) => new()
    {
        Id = S(row, "id"),
        NumeroOrden = long.TryParse(S(row, "numero_orden"), out var numeroOrden) ? numeroOrden : 0,
        ClienteId = S(row, "cliente_id"),
        ClienteNombre = S(row, "cliente_nombre"),
        ClienteEmail = S(row, "cliente_email"),
        ClienteTelefono = S(row, "cliente_telefono"),
        Servicio = S(row, "servicio"),
        Fecha = S(row, "fecha"),
        FranjaHoraria = S(row, "franja_horaria"),
        Direccion = S(row, "direccion"),
        Instrucciones = S(row, "instrucciones"),
        Fragancia = S(row, "fragancia"),
        CantidadAproximada = I(row, "cantidad_aproximada"),
        MetodoPago = S(row, "metodo_pago"),
        OpcionAcabado = S(row, "opcion_acabado"),
        PrecioAcabado = M(row, "precio_acabado"),
        CodigoPromocion = S(row, "codigo_promocion"),
        Repartidor = S(row, "repartidor"),
        PesoConfirmado = N(row, "peso_confirmado"),
        TotalConfirmado = M(row, "total_confirmado"),
        Total = M(row, "total") ?? 0m,
        Estado = S(row, "estado"),
        RazonCancelacion = S(row, "razon_cancelacion"),
        ComentariosCancelacion = S(row, "comentarios_cancelacion"),
        Calificacion = I(row, "calificacion"),
        Resena = S(row, "resena"),
        ReporteTipo = S(row, "reporte_tipo"),
        ReporteDetalles = S(row, "reporte_detalles"),
        CreatedAt = S(row, "created_at")
    };

    private ObjectResult DataError(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });
    private static string E(string value) => Uri.EscapeDataString(value);
    private static string? S(JsonObject row, string key) => row[key]?.ToString();
    private static bool B(JsonObject row, string key) => bool.TryParse(S(row, key), out var value) && value;
    private static int? I(JsonObject row, string key) => int.TryParse(S(row, key), out var value) ? value : null;
    private static double? N(JsonObject row, string key) => double.TryParse(S(row, key), out var value) ? value : null;
    private static decimal? M(JsonObject row, string key) => decimal.TryParse(S(row, key), out var value) ? value : null;
}

public class CrearPedidoRequest
{
    public string? ClienteId { get; set; }
    public string? ClienteNombre { get; set; }
    public string? ClienteEmail { get; set; }
    public string? ClienteTelefono { get; set; }
    public string? Servicio { get; set; }
    public string? Fecha { get; set; }
    public string? FranjaHoraria { get; set; }
    public string? Direccion { get; set; }
    public string? Instrucciones { get; set; }
    public string? Fragancia { get; set; }
    public int? CantidadAproximada { get; set; }
    public string? MetodoPago { get; set; }
    public string? OpcionAcabado { get; set; }
    public decimal? PrecioAcabado { get; set; }
    public string? CodigoPromocion { get; set; }
    public decimal? Total { get; set; }
}

public class ActualizarEstadoRequest { public string? Estado { get; set; } }
public class AsignarRepartidorRequest { public string? Repartidor { get; set; } }
public class ConfirmarPrecioRequest { public double? PesoConfirmado { get; set; } public decimal TotalConfirmado { get; set; } }
public class CancelarPedidoRequest { public string? Razon { get; set; } public string? Comentarios { get; set; } }
public class CalificarPedidoRequest { public int CalificacionGeneral { get; set; } public string? Resena { get; set; } }
public class ReportarPedidoRequest { public string? Tipo { get; set; } public string? Detalles { get; set; } }

public class PedidoDto
{
    public string? Id { get; set; }

    /// Folio corto y legible (1, 2, 3...) para mostrar al cliente/admin en
    /// vez del uuid interno de [Id].
    public long NumeroOrden { get; set; }
    public string? ClienteId { get; set; }
    public string? ClienteNombre { get; set; }
    public string? ClienteEmail { get; set; }
    public string? ClienteTelefono { get; set; }
    public string? Servicio { get; set; }
    public string? Fecha { get; set; }
    public string? FranjaHoraria { get; set; }
    public string? Direccion { get; set; }
    public string? Instrucciones { get; set; }
    public string? Fragancia { get; set; }
    public int? CantidadAproximada { get; set; }
    public string? MetodoPago { get; set; }
    public string? OpcionAcabado { get; set; }
    public decimal? PrecioAcabado { get; set; }
    public string? CodigoPromocion { get; set; }
    public string? Repartidor { get; set; }
    public double? PesoConfirmado { get; set; }
    public decimal? TotalConfirmado { get; set; }
    public decimal Total { get; set; }
    public string? Estado { get; set; }
    public string? RazonCancelacion { get; set; }
    public string? ComentariosCancelacion { get; set; }
    public int? Calificacion { get; set; }
    public string? Resena { get; set; }
    public string? ReporteTipo { get; set; }
    public string? ReporteDetalles { get; set; }

    /// Cuándo se creó el pedido (distinto de [Fecha], que es la fecha de
    /// recolección que eligió el cliente). Es lo que define si un pedido
    /// cuenta como "de hoy" en el panel del admin.
    public string? CreatedAt { get; set; }
}
