using System.Security.Claims;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/soporte")]
[Authorize]
public class SoporteController : ControllerBase
{
    private readonly SupabaseDataService _data;

    public SoporteController(SupabaseDataService data) => _data = data;

    private string CallerId => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
    private string CallerNombre => User.FindFirstValue(ClaimTypes.Name) ?? "Usuario";
    private string CallerRol => User.FindFirstValue(ClaimTypes.Role) ?? "cliente";
    private bool EsStaff => CallerRol is "administrador" or "empleado";

    [HttpGet("mensajes")]
    public async Task<IActionResult> Mensajes([FromQuery] string? clienteId)
    {
        var id = EsStaff ? clienteId?.Trim() : CallerId;
        if (string.IsNullOrWhiteSpace(id)) return BadRequest(new { message = "Selecciona una conversación" });
        try
        {
            var rows = await _data.ListAsync("soporte_mensajes",
                $"cliente_id=eq.{Uri.EscapeDataString(id)}&order=created_at.asc&limit=500");
            return Ok(rows.OfType<JsonObject>().Select(MapMensaje));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpGet("conversaciones")]
    [Authorize(Roles = "administrador,empleado")]
    public async Task<IActionResult> Conversaciones()
    {
        try
        {
            var rows = (await _data.ListAsync("soporte_mensajes", "order=created_at.desc&limit=1000"))
                .OfType<JsonObject>().ToList();
            var conversaciones = rows.GroupBy(r => r["cliente_id"]?.ToString() ?? string.Empty)
                .Where(g => !string.IsNullOrWhiteSpace(g.Key))
                .Select(g => new
                {
                    clienteId = g.Key,
                    clienteNombre = g.First()["cliente_nombre"]?.ToString() ?? "Cliente",
                    ultimoMensaje = g.First()["mensaje"]?.ToString() ?? string.Empty,
                    createdAt = g.First()["created_at"]?.ToString(),
                    noLeidos = g.Count(r => r["autor_rol"]?.ToString() == "cliente" && r["leido"]?.GetValue<bool>() != true),
                });
            return Ok(conversaciones);
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPost("mensajes")]
    public async Task<IActionResult> Enviar([FromBody] EnviarMensajeSoporteRequest request)
    {
        var mensaje = request.Mensaje?.Trim();
        if (string.IsNullOrWhiteSpace(mensaje)) return BadRequest(new { message = "Escribe un mensaje" });
        if (mensaje.Length > 1500) return BadRequest(new { message = "El mensaje es demasiado largo" });

        var clienteId = EsStaff ? request.ClienteId?.Trim() : CallerId;
        if (string.IsNullOrWhiteSpace(clienteId)) return BadRequest(new { message = "Selecciona un cliente" });
        try
        {
            var clienteNombre = CallerNombre;
            if (EsStaff)
            {
                var anterior = await _data.FindOneAsync("soporte_mensajes",
                    $"cliente_id=eq.{Uri.EscapeDataString(clienteId)}&order=created_at.desc&limit=1");
                clienteNombre = anterior?["cliente_nombre"]?.ToString() ?? request.ClienteNombre?.Trim() ?? "Cliente";
            }
            var row = await _data.InsertAsync("soporte_mensajes", new JsonObject
            {
                ["cliente_id"] = clienteId,
                ["cliente_nombre"] = clienteNombre,
                ["autor_id"] = CallerId,
                ["autor_nombre"] = CallerNombre,
                ["autor_rol"] = CallerRol,
                ["mensaje"] = mensaje,
                ["leido"] = false,
            });
            return Ok(MapMensaje(row));
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    [HttpPut("leer")]
    public async Task<IActionResult> MarcarLeidos([FromQuery] string? clienteId)
    {
        var id = EsStaff ? clienteId?.Trim() : CallerId;
        if (string.IsNullOrWhiteSpace(id)) return BadRequest(new { message = "Selecciona una conversación" });
        var autorFiltro = EsStaff ? "autor_rol=eq.cliente" : "autor_rol=neq.cliente";
        try
        {
            await _data.UpdateAsync("soporte_mensajes",
                $"cliente_id=eq.{Uri.EscapeDataString(id)}&{autorFiltro}&leido=eq.false",
                new JsonObject { ["leido"] = true });
            return Ok(new { message = "Mensajes leídos" });
        }
        catch (SupabaseDataException ex) { return DataError(ex); }
    }

    private IActionResult DataError(SupabaseDataException ex) =>
        StatusCode(ex.StatusCode is >= 400 and < 600 ? ex.StatusCode : 502, new { message = ex.Message });

    private static object MapMensaje(JsonObject row) => new
    {
        id = row["id"]?.ToString(),
        clienteId = row["cliente_id"]?.ToString(),
        clienteNombre = row["cliente_nombre"]?.ToString(),
        autorId = row["autor_id"]?.ToString(),
        autorNombre = row["autor_nombre"]?.ToString(),
        autorRol = row["autor_rol"]?.ToString(),
        mensaje = row["mensaje"]?.ToString(),
        leido = row["leido"]?.GetValue<bool>() ?? false,
        createdAt = row["created_at"]?.ToString(),
    };
}

public class EnviarMensajeSoporteRequest
{
    public string? ClienteId { get; set; }
    public string? ClienteNombre { get; set; }
    public string? Mensaje { get; set; }
}
