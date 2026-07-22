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
    private readonly SupabaseService? _supabaseService;

    public PedidosController(
        SupabaseDataService data,
        PromocionValidationService validacionPromo,
        SupabaseService? supabaseService = null)
    {
        _data = data;
        _validacionPromo = validacionPromo;
        _supabaseService = supabaseService;
    }

    private string? CallerId => User.FindFirstValue(ClaimTypes.NameIdentifier);
    private string? CallerRol => User.FindFirstValue(ClaimTypes.Role);
    private string CallerNombre => User.FindFirstValue(ClaimTypes.Name) ?? "Usuario";
    private bool EsStaff => CallerRol is "administrador" or "empleado";
    private bool EsRepartidor => CallerRol == "repartidor";

    /// Registra en la bitácora quién hizo qué sobre un pedido (para la
    /// pantalla de actividad del admin). Si falla (ej. la tabla todavía no
    /// se creó en Supabase), no debe tumbar la acción principal que sí se
    /// guardó correctamente.
    private async Task RegistrarEventoAsync(string pedidoId, string accion, string? detalle = null)
    {
        try
        {
            await _data.InsertAsync("pedido_eventos", new JsonObject
            {
                ["pedido_id"] = pedidoId,
                ["actor_id"] = CallerId,
                ["actor_nombre"] = CallerNombre,
                ["actor_rol"] = CallerRol,
                ["accion"] = accion,
                ["detalle"] = detalle,
            });
        }
        catch (SupabaseDataException)
        {
            // No bloquear la acción principal si falla el registro de actividad.
        }
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? clienteId)
    {
        try
        {
            // Un cliente solo puede listar sus propios pedidos, sin importar
            // qué clienteId haya mandado en la URL. Solo el staff puede ver
            // los de todos (o filtrar por cualquier cliente).
            string filter;
            if (EsRepartidor)
            {
                if (string.IsNullOrWhiteSpace(CallerId)) return Forbid();
                filter = $"repartidor_id=eq.{E(CallerId)}&order=created_at.desc";
            }
            else
            {
                var idEfectivo = EsStaff ? clienteId : CallerId;
                filter = string.IsNullOrWhiteSpace(idEfectivo)
                    ? "order=created_at.desc"
                    : $"cliente_id=eq.{E(idEfectivo)}&order=created_at.desc";
            }
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
            var puedeConsultar = EsStaff ||
                (EsRepartidor
                    ? row["repartidor_id"]?.ToString() == CallerId
                    : row["cliente_id"]?.ToString() == CallerId);
            if (!puedeConsultar)
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
                ["estado"] = "Pedido recibido",
                ["recoleccion_en_sucursal"] = request.RecoleccionEnSucursal ?? false,
                ["entrega_en_sucursal"] = request.EntregaEnSucursal ?? false,
            });
            var dto = Map(row);
            return CreatedAtAction(nameof(Obtener), new { id = dto.Id }, dto);
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}/estado")]
    [Authorize(Roles = "administrador,empleado,repartidor")]
    public async Task<IActionResult> ActualizarEstado(string id, [FromBody] ActualizarEstadoRequest request)
    {
        var estado = request.Estado?.Trim();
        if (string.IsNullOrWhiteSpace(estado))
        {
            return BadRequest(new { message = "El estado es obligatorio" });
        }

        if (!EsRepartidor)
        {
            var resultadoStaff = await UpdatePedido(id, new JsonObject { ["estado"] = estado }, "No se pudo actualizar el estado");
            if (resultadoStaff is OkObjectResult)
            {
                await RegistrarEventoAsync(id, "estado_cambiado", $"Cambió el estado a \"{estado}\"");
            }
            return resultadoStaff;
        }

        try
        {
            var actual = await _data.FindOneAsync("pedidos", $"id=eq.{E(id)}&limit=1");
            if (actual is null || actual["repartidor_id"]?.ToString() != CallerId)
            {
                return NotFound(new { message = "Pedido no encontrado" });
            }

            var estadoActual = actual["estado"]?.ToString();
            var transicionValida = (estadoActual is "Asignado" or "Repartidor Asignado" or "Recolector asignado") && estado == "En Planta"
                || (estadoActual is "Listo" or "Repartidor asignado") && estado == "En camino"
                || estadoActual == "En camino" && estado == "Entregado";
            if (!transicionValida)
            {
                return Conflict(new { message = "No puedes aplicar ese cambio de estado a este pedido" });
            }

            var resultadoRepartidor = await UpdatePedido(id, new JsonObject { ["estado"] = estado }, "No se pudo actualizar el estado");
            if (resultadoRepartidor is OkObjectResult)
            {
                var accion = estado == "Entregado" ? "pedido_entregado"
                    : estado == "En Planta" ? "pedido_recibido_en_planta"
                    : "estado_cambiado";
                await RegistrarEventoAsync(id, accion, $"Cambió el estado a \"{estado}\"");
            }
            return resultadoRepartidor;
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}/repartidor")]
    [Authorize(Roles = "administrador,empleado")]
    public async Task<IActionResult> AsignarRepartidor(string id, [FromBody] AsignarRepartidorRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.RepartidorId))
        {
            return BadRequest(new { message = "Selecciona un repartidor" });
        }
        if (_supabaseService is null || !_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "No se pudo validar al repartidor" });
        }

        try
        {
            var current = await _data.FindOneAsync("pedidos", $"id=eq.{E(id)}&limit=1");
            if (current is null) return NotFound(new { message = "Pedido no encontrado" });

            var estadoActual = current["estado"]?.ToString();
            var esRecoleccion = estadoActual is "Recibido" or "Pedido recibido";
            var esEntrega = estadoActual == "Secando y Doblado";
            var recoleccionEnSucursal = B(current, "recoleccion_en_sucursal");
            var entregaEnSucursal = B(current, "entrega_en_sucursal");
            if (esRecoleccion && recoleccionEnSucursal)
            {
                return Conflict(new { message = "El cliente lleva este pedido a la sucursal él mismo; no necesita un recolector." });
            }
            if (esEntrega && entregaEnSucursal)
            {
                return Conflict(new { message = "El cliente recoge este pedido en la sucursal él mismo; no necesita un repartidor." });
            }

            var repartidor = (await _supabaseService.ListStaffUsersAsync()).FirstOrDefault(usuario =>
                usuario.Id == request.RepartidorId && usuario.Rol == "repartidor" && usuario.Activa);
            if (repartidor is null)
            {
                return BadRequest(new { message = "El repartidor seleccionado no está disponible" });
            }

            var payload = new JsonObject
            {
                ["repartidor"] = repartidor.Nombre,
                ["repartidor_id"] = repartidor.Id,
                ["repartidor_telefono"] = repartidor.Telefono,
            };
            if (esRecoleccion)
                payload["estado"] = "Recolector asignado";
            else if (esEntrega)
                payload["estado"] = "Repartidor asignado";
            var row = await _data.UpdateAsync("pedidos", $"id=eq.{E(id)}", payload);
            await RegistrarEventoAsync(id, "repartidor_asignado", $"Asignó a {repartidor.Nombre} como repartidor");
            return Ok(Map(row!));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("{id}/confirmar-precio")]
    [Authorize(Roles = "administrador,empleado")]
    public async Task<IActionResult> ConfirmarPrecio(string id, [FromBody] ConfirmarPrecioRequest request)
    {
        var resultado = await UpdatePedido(id, new JsonObject
        {
            ["peso_confirmado"] = request.PesoConfirmado,
            ["total_confirmado"] = request.TotalConfirmado
        }, "No se pudo confirmar el precio");
        if (resultado is OkObjectResult)
        {
            await RegistrarEventoAsync(id, "precio_confirmado", $"Confirmó el precio final: ${request.TotalConfirmado:0.00}");
        }
        return resultado;
    }

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
                "Recibido", "Pedido recibido", "Asignado", "Repartidor Asignado", "Recolector asignado"
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
        var resultado = await UpdatePedido(id, new JsonObject
        {
            ["reporte_tipo"] = request.Tipo ?? "Otro problema",
            ["reporte_detalles"] = request.Detalles ?? string.Empty,
            ["reporte_estado"] = "Abierto",
            ["reporte_respuesta"] = null,
            ["reporte_actualizado_at"] = DateTime.UtcNow.ToString("O")
        }, "No se pudo guardar el reporte");
        if (resultado is OkObjectResult)
        {
            await RegistrarEventoAsync(id, "reporte_creado", $"Cliente reportó: {request.Tipo ?? "Otro problema"}");
        }
        return resultado;
    }

    [HttpPut("{id}/reporte")]
    [Authorize(Roles = "administrador,empleado")]
    public async Task<IActionResult> ActualizarReporte(string id, [FromBody] ActualizarReporteRequest request)
    {
        var estado = request.Estado?.Trim();
        if (estado is not ("En revisión" or "Resuelto"))
            return BadRequest(new { message = "El estado del reporte no es válido" });
        if (estado == "Resuelto" && string.IsNullOrWhiteSpace(request.Respuesta))
            return BadRequest(new { message = "Escribe una respuesta para el cliente" });

        var resultado = await UpdatePedido(id, new JsonObject
        {
            ["reporte_estado"] = estado,
            ["reporte_respuesta"] = request.Respuesta?.Trim(),
            ["reporte_actualizado_at"] = DateTime.UtcNow.ToString("O")
        }, "No se pudo actualizar el reporte");
        if (resultado is OkObjectResult)
        {
            await RegistrarEventoAsync(
                id,
                estado == "Resuelto" ? "reporte_resuelto" : "reporte_en_revision",
                estado == "Resuelto" ? $"Respuesta al cliente: {request.Respuesta?.Trim()}" : "El equipo comenzó a revisar el reporte");
        }
        return resultado;
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
        RepartidorId = S(row, "repartidor_id"),
        RepartidorTelefono = S(row, "repartidor_telefono"),
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
        ReporteEstado = S(row, "reporte_estado"),
        ReporteRespuesta = S(row, "reporte_respuesta"),
        RecoleccionEnSucursal = B(row, "recoleccion_en_sucursal"),
        EntregaEnSucursal = B(row, "entrega_en_sucursal"),
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
    public bool? RecoleccionEnSucursal { get; set; }
    public bool? EntregaEnSucursal { get; set; }
}

public class ActualizarEstadoRequest { public string? Estado { get; set; } }
public class AsignarRepartidorRequest { public string? RepartidorId { get; set; } }
public class ConfirmarPrecioRequest { public double? PesoConfirmado { get; set; } public decimal TotalConfirmado { get; set; } }
public class CancelarPedidoRequest { public string? Razon { get; set; } public string? Comentarios { get; set; } }
public class CalificarPedidoRequest { public int CalificacionGeneral { get; set; } public string? Resena { get; set; } }
public class ReportarPedidoRequest { public string? Tipo { get; set; } public string? Detalles { get; set; } }
public class ActualizarReporteRequest { public string? Estado { get; set; } public string? Respuesta { get; set; } }

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
    public string? RepartidorId { get; set; }
    public string? RepartidorTelefono { get; set; }
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
    public string? ReporteEstado { get; set; }
    public string? ReporteRespuesta { get; set; }

    /// Cuándo se creó el pedido (distinto de [Fecha], que es la fecha de
    /// recolección que eligió el cliente). Es lo que define si un pedido
    /// cuenta como "de hoy" en el panel del admin.
    public bool RecoleccionEnSucursal { get; set; }
    public bool EntregaEnSucursal { get; set; }
    public string? CreatedAt { get; set; }
}
