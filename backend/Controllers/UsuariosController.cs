using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsuariosController : ControllerBase
{
    private readonly SupabaseService _supabaseService;

    public UsuariosController(SupabaseService supabaseService)
    {
        _supabaseService = supabaseService;
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> ActualizarPerfil(string id, [FromBody] ActualizarPerfilRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        var update = await _supabaseService.UpdateProfileAsync(id, request.Nombre, request.Correo, request.Telefono);
        if (!update.Success)
        {
            return StatusCode(update.StatusCode, new { message = update.ErrorMessage ?? "No se pudo actualizar el perfil" });
        }

        return Ok(update.Usuario);
    }

    [HttpPost("cambiar-password")]
    public async Task<IActionResult> CambiarPassword([FromBody] CambiarPasswordRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (string.IsNullOrWhiteSpace(request.PasswordActual) || string.IsNullOrWhiteSpace(request.PasswordNueva))
        {
            return BadRequest(new { message = "Se requieren ambas contraseñas" });
        }

        if (string.IsNullOrWhiteSpace(request.Correo))
        {
            return BadRequest(new { message = "Correo requerido para cambiar contraseña" });
        }

        var result = await _supabaseService.ChangePasswordAsync(request.Correo, request.PasswordActual, request.PasswordNueva);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage ?? "No se pudo actualizar la contraseña" });
        }

        return Ok(new { message = "Contraseña actualizada" });
    }
}

public class ActualizarPerfilRequest
{
    public string? Nombre { get; set; }
    public string? Correo { get; set; }
    public string? Telefono { get; set; }
}

public class CambiarPasswordRequest
{
    public string? Correo { get; set; }
    public string? PasswordActual { get; set; }
    public string? PasswordNueva { get; set; }
}
