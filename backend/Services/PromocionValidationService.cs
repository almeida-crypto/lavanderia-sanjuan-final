using System.Text.Json.Nodes;

namespace backend;

public record PromocionValidationResult(bool Success, string? ErrorMessage, JsonObject? Promocion);

/// Valida un código promocional contra lo que el admin realmente configuró
/// (vigencia, servicio, cantidad mínima de prendas y usos por cliente), en
/// vez de confiar en lo que la app cliente calcule por su cuenta. La usan
/// tanto PromocionesController (para que el cliente vea si su código sirve
/// antes de pagar) como PedidosController (para que, al crear el pedido de
/// verdad, no se pueda colar un código inválido o ya agotado).
public class PromocionValidationService
{
    private readonly SupabaseDataService _data;

    public PromocionValidationService(SupabaseDataService data)
    {
        _data = data;
    }

    public async Task<PromocionValidationResult> ValidarAsync(string codigo, string clienteId, string? servicio, int? cantidad)
    {
        var codigoNormalizado = codigo.Trim().ToUpperInvariant();
        var rows = await _data.ListAsync("promociones", $"codigo=eq.{Uri.EscapeDataString(codigoNormalizado)}&limit=1");
        var promo = rows.FirstOrDefault() as JsonObject;
        if (promo is null)
        {
            return new PromocionValidationResult(false, "Código promocional no válido", null);
        }

        var activa = promo["activa"]?.GetValue<bool>() ?? true;
        var fechaInicio = DateTimeOffset.TryParse(promo["fecha_inicio"]?.ToString(), out var fi) ? fi : DateTimeOffset.MinValue;
        var fechaFin = DateTimeOffset.TryParse(promo["fecha_fin"]?.ToString(), out var ff) ? (DateTimeOffset?)ff : null;
        var ahora = DateTimeOffset.UtcNow;
        if (!activa || ahora < fechaInicio || (fechaFin is not null && ahora > fechaFin))
        {
            return new PromocionValidationResult(false, "Ese código ya no está vigente", null);
        }

        var servicioAplicable = promo["servicio_aplicable"]?.ToString();
        if (!string.IsNullOrWhiteSpace(servicioAplicable) &&
            !string.Equals(servicioAplicable, servicio, StringComparison.OrdinalIgnoreCase))
        {
            return new PromocionValidationResult(false, $"Ese código no aplica para \"{servicio}\"", null);
        }

        var cantidadMinima = int.TryParse(promo["cantidad_minima"]?.ToString(), out var cm) ? (int?)cm : null;
        if (cantidadMinima is not null && (cantidad ?? 0) < cantidadMinima)
        {
            return new PromocionValidationResult(false, $"Este código requiere al menos {cantidadMinima} prenda(s)", null);
        }

        var usosPorCliente = int.TryParse(promo["usos_por_cliente"]?.ToString(), out var upc) ? (int?)upc : null;
        if (usosPorCliente is not null)
        {
            var previos = await _data.ListAsync(
                "pedidos",
                $"cliente_id=eq.{Uri.EscapeDataString(clienteId)}&codigo_promocion=eq.{Uri.EscapeDataString(codigoNormalizado)}&select=id");
            if (previos.Count >= usosPorCliente)
            {
                return new PromocionValidationResult(false, "Ya usaste este código el máximo de veces permitido", null);
            }
        }

        return new PromocionValidationResult(true, null, promo);
    }
}
