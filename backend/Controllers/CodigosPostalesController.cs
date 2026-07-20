using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

/// Consulta el catálogo real de SEPOMEX (importado una sola vez a
/// public.codigos_postales) para que el formulario de dirección se rellene
/// solo con el código postal: estado, municipio/ciudad y las colonias
/// reales que existen en ese CP. Si el CP no aparece en el catálogo, es una
/// señal real de que probablemente está mal escrito.
[ApiController]
[Route("api/codigos-postales")]
public class CodigosPostalesController : ControllerBase
{
    private readonly SupabaseDataService _data;

    public CodigosPostalesController(SupabaseDataService data)
    {
        _data = data;
    }

    [HttpGet("{cp}")]
    public async Task<IActionResult> Buscar(string cp)
    {
        var cpLimpio = cp.Trim();
        if (cpLimpio.Length != 5 || !cpLimpio.All(char.IsDigit))
        {
            return BadRequest(new { message = "El código postal debe tener 5 dígitos" });
        }

        try
        {
            var rows = await _data.ListAsync(
                "codigos_postales",
                $"codigo_postal=eq.{Uri.EscapeDataString(cpLimpio)}&order=colonia.asc");

            if (rows.Count == 0)
            {
                return NotFound(new { message = "Ese código postal no existe en el catálogo de SEPOMEX" });
            }

            var primero = (JsonObject)rows[0]!;
            var colonias = rows
                .OfType<JsonObject>()
                .Select(r => r["colonia"]?.ToString())
                .Where(c => !string.IsNullOrWhiteSpace(c))
                .Distinct()
                .OrderBy(c => c)
                .ToList();

            return Ok(new
            {
                codigoPostal = cpLimpio,
                estado = primero["estado"]?.ToString(),
                municipio = primero["municipio"]?.ToString(),
                ciudad = string.IsNullOrWhiteSpace(primero["ciudad"]?.ToString())
                    ? primero["municipio"]?.ToString()
                    : primero["ciudad"]?.ToString(),
                colonias
            });
        }
        catch (SupabaseDataException ex)
        {
            return StatusCode(ex.StatusCode >= 400 && ex.StatusCode < 600 ? ex.StatusCode : 502, new { message = ex.Message });
        }
    }
}
