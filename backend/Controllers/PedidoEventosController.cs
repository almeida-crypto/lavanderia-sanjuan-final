using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

/// Bitácora de actividad sobre pedidos (quién cambió el estado, quién
/// asignó repartidor, quién confirmó el precio), para que el admin pueda
/// ver qué hizo cada empleado/repartidor. Los eventos los registra
/// PedidosController en cada acción exitosa.
[ApiController]
[Route("api/pedidos/eventos")]
[Authorize(Roles = "administrador")]
public class PedidoEventosController : ControllerBase
{
    private readonly SupabaseDataService _data;

    public PedidoEventosController(SupabaseDataService data)
    {
        _data = data;
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? actorId, [FromQuery] int? limit)
    {
        try
        {
            var partes = new List<string>
            {
                "select=*,pedidos(numero_orden,cliente_nombre,evidencia_entrega_url)",
                "order=created_at.desc",
                $"limit={Math.Clamp(limit ?? 200, 1, 500)}",
            };
            if (!string.IsNullOrWhiteSpace(actorId))
            {
                partes.Add($"actor_id=eq.{Uri.EscapeDataString(actorId)}");
            }

            var rows = await _data.ListAsync("pedido_eventos", string.Join("&", partes));
            return Ok(rows.OfType<JsonObject>().Select(Map));
        }
        catch (SupabaseDataException ex)
        {
            return StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });
        }
    }

    private static object Map(JsonObject row)
    {
        var pedido = row["pedidos"] as JsonObject;
        return new
        {
            id = row["id"]?.ToString(),
            pedidoId = row["pedido_id"]?.ToString(),
            pedidoNumero = pedido?["numero_orden"]?.ToString(),
            clienteNombre = pedido?["cliente_nombre"]?.ToString(),
            evidenciaUrl = pedido?["evidencia_entrega_url"]?.ToString(),
            actorId = row["actor_id"]?.ToString(),
            actorNombre = row["actor_nombre"]?.ToString(),
            actorRol = row["actor_rol"]?.ToString(),
            accion = row["accion"]?.ToString(),
            detalle = row["detalle"]?.ToString(),
            createdAt = row["created_at"]?.ToString(),
        };
    }
}
