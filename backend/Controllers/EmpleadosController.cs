using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/empleados")]
[Authorize(Roles = "administrador")]
public class EmpleadosController : ControllerBase
{
    private static readonly string[] RolesValidos = ["empleado", "administrador"];
    private const string RolAdministrador = "administrador";

    private readonly SupabaseService _supabaseService;

    public EmpleadosController(SupabaseService supabaseService)
    {
        _supabaseService = supabaseService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar()
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        var staff = await _supabaseService.ListStaffUsersAsync();
        return Ok(staff);
    }

    [HttpPost]
    public async Task<IActionResult> Crear([FromBody] CrearEmpleadoRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (string.IsNullOrWhiteSpace(request.Nombre) || string.IsNullOrWhiteSpace(request.Correo) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { message = "Nombre, correo y contraseña son requeridos" });
        }

        if (request.Password.Length < 6)
        {
            return BadRequest(new { message = "La contraseña debe tener al menos 6 caracteres" });
        }

        var rol = string.IsNullOrWhiteSpace(request.Rol) ? "empleado" : request.Rol.Trim().ToLowerInvariant();
        if (!RolesValidos.Contains(rol))
        {
            return BadRequest(new { message = "Rol inválido. Debe ser 'empleado' o 'administrador'" });
        }

        var resultado = await _supabaseService.CreateUserAsync(request.Nombre.Trim(), request.Correo.Trim(), request.Password, rol);
        if (!resultado.Success)
        {
            return StatusCode(resultado.StatusCode, new { message = resultado.ErrorMessage ?? "No se pudo crear la cuenta" });
        }

        return Ok(resultado.Usuario);
    }

    [HttpPut("{id}/rol")]
    public async Task<IActionResult> CambiarRol(string id, [FromBody] CambiarRolRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (string.IsNullOrWhiteSpace(request.Rol) || !RolesValidos.Contains(request.Rol.Trim().ToLowerInvariant()))
        {
            return BadRequest(new { message = "Rol inválido. Debe ser 'empleado' o 'administrador'" });
        }

        if (!string.IsNullOrWhiteSpace(request.ActorId) && request.ActorId == id)
        {
            return BadRequest(new { message = "No puedes cambiar tu propio rol" });
        }

        var rol = request.Rol.Trim().ToLowerInvariant();
        if (rol != RolAdministrador)
        {
            var bloqueado = await BloqueadoPorSerUltimoAdminAsync(id);
            if (bloqueado is not null) return bloqueado;
        }

        var resultado = await _supabaseService.UpdateRoleAsync(id, rol);
        if (!resultado.Success)
        {
            return StatusCode(resultado.StatusCode, new { message = resultado.ErrorMessage ?? "No se pudo cambiar el rol" });
        }

        return Ok(resultado.Usuario);
    }

    [HttpPut("{id}/estado")]
    public async Task<IActionResult> CambiarEstado(string id, [FromBody] CambiarEstadoRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (!string.IsNullOrWhiteSpace(request.ActorId) && request.ActorId == id)
        {
            return BadRequest(new { message = "No puedes desactivar tu propia cuenta" });
        }

        if (!request.Activa)
        {
            var bloqueado = await BloqueadoPorSerUltimoAdminAsync(id);
            if (bloqueado is not null) return bloqueado;
        }

        var resultado = await _supabaseService.SetActivaAsync(id, request.Activa);
        if (!resultado.Success)
        {
            return StatusCode(resultado.StatusCode, new { message = resultado.ErrorMessage ?? "No se pudo cambiar el estado de la cuenta" });
        }

        return Ok(resultado.Usuario);
    }

    [HttpPut("{id}/password")]
    public async Task<IActionResult> CambiarPassword(string id, [FromBody] CambiarPasswordEmpleadoRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (string.IsNullOrWhiteSpace(request.NuevaPassword) || request.NuevaPassword.Length < 6)
        {
            return BadRequest(new { message = "La nueva contraseña debe tener al menos 6 caracteres" });
        }

        if (string.IsNullOrWhiteSpace(request.ActorCorreo) || string.IsNullOrWhiteSpace(request.ActorPassword))
        {
            return BadRequest(new { message = "Confirma tu contraseña de administrador para continuar" });
        }

        // Por seguridad, las contraseñas no pueden mostrarse ni recuperarse:
        // Supabase (como cualquier sistema de autenticación correcto) solo
        // guarda un hash irreversible. Lo que sí podemos hacer es permitir
        // que el admin defina una contraseña NUEVA, siempre que primero
        // confirme su propia contraseña de administrador.
        var reautenticacion = await _supabaseService.LoginAsync(request.ActorCorreo, request.ActorPassword);
        if (!reautenticacion.Success)
        {
            return StatusCode(StatusCodes.Status401Unauthorized, new { message = "Tu contraseña de administrador es incorrecta" });
        }

        var resultado = await _supabaseService.SetPasswordAsync(id, request.NuevaPassword);
        if (!resultado.Success)
        {
            return StatusCode(resultado.StatusCode, new { message = resultado.ErrorMessage ?? "No se pudo cambiar la contraseña" });
        }

        return Ok(resultado.Usuario);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Eliminar(string id, [FromQuery] string? actorId)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (!string.IsNullOrWhiteSpace(actorId) && actorId == id)
        {
            return BadRequest(new { message = "No puedes eliminar tu propia cuenta" });
        }

        var bloqueado = await BloqueadoPorSerUltimoAdminAsync(id);
        if (bloqueado is not null) return bloqueado;

        var resultado = await _supabaseService.DeleteUserAsync(id);
        if (!resultado.Success)
        {
            return StatusCode(resultado.StatusCode, new { message = resultado.ErrorMessage ?? "No se pudo eliminar la cuenta" });
        }

        return Ok(new { message = "Cuenta eliminada" });
    }

    private async Task<IActionResult?> BloqueadoPorSerUltimoAdminAsync(string id)
    {
        var staff = await _supabaseService.ListStaffUsersAsync();
        var target = staff.FirstOrDefault(u => u.Id == id);
        if (target is null || target.Rol != RolAdministrador)
        {
            return null;
        }

        var otrosAdminsActivos = staff.Any(u => u.Id != id && u.Rol == RolAdministrador && u.Activa);
        if (!otrosAdminsActivos)
        {
            return BadRequest(new { message = "No puedes eliminar, desactivar ni degradar al último administrador activo" });
        }

        return null;
    }
}

public class CrearEmpleadoRequest
{
    public string? Nombre { get; set; }
    public string? Correo { get; set; }
    public string? Password { get; set; }
    public string? Rol { get; set; }
}

public class CambiarRolRequest
{
    public string? Rol { get; set; }
    public string? ActorId { get; set; }
}

public class CambiarEstadoRequest
{
    public bool Activa { get; set; }
    public string? ActorId { get; set; }
}

public class CambiarPasswordEmpleadoRequest
{
    public string? NuevaPassword { get; set; }
    public string? ActorCorreo { get; set; }
    public string? ActorPassword { get; set; }
}
