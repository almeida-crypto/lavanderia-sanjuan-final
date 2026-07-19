using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

/// Gestión de cuentas de staff (empleado/administrador) por parte del admin.
/// Nunca toca ni expone cuentas con rol "cliente" — el admin solo administra
/// las cuentas de trabajo que él mismo crea aquí.
[ApiController]
[Route("api/empleados")]
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

        var empleados = await _supabaseService.ListStaffUsersAsync();
        return Ok(empleados);
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
            return BadRequest(new { message = "Nombre, correo y contraseña son obligatorios" });
        }

        var rol = NormalizarRol(request.Rol) ?? "empleado";
        if (!RolesValidos.Contains(rol))
        {
            return BadRequest(new { message = "Rol inválido, usa 'empleado' o 'administrador'" });
        }

        var result = await _supabaseService.CreateUserAsync(request.Nombre, request.Correo, request.Password, rol);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage ?? "No se pudo crear la cuenta" });
        }

        return StatusCode(StatusCodes.Status201Created, result.Usuario);
    }

    [HttpPut("{id}/rol")]
    public async Task<IActionResult> CambiarRol(string id, [FromBody] CambiarRolRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (!string.IsNullOrWhiteSpace(request.ActorId) && string.Equals(request.ActorId, id, StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "No puedes cambiar tu propio rol" });
        }

        var rol = NormalizarRol(request.Rol);
        if (rol is null || !RolesValidos.Contains(rol))
        {
            return BadRequest(new { message = "Rol inválido, usa 'empleado' o 'administrador'" });
        }

        if (rol != RolAdministrador)
        {
            var bloqueo = await BloqueadoPorSerUltimoAdminAsync(id);
            if (bloqueo is not null) return bloqueo;
        }

        var result = await _supabaseService.UpdateRoleAsync(id, rol);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage ?? "No se pudo actualizar el rol" });
        }

        return Ok(result.Usuario);
    }

    [HttpPut("{id}/estado")]
    public async Task<IActionResult> CambiarEstado(string id, [FromBody] CambiarEstadoRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (!string.IsNullOrWhiteSpace(request.ActorId) && string.Equals(request.ActorId, id, StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "No puedes desactivar tu propia cuenta" });
        }

        if (!request.Activa)
        {
            var bloqueo = await BloqueadoPorSerUltimoAdminAsync(id);
            if (bloqueo is not null) return bloqueo;
        }

        var result = await _supabaseService.SetActivaAsync(id, request.Activa);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage ?? "No se pudo actualizar el estado de la cuenta" });
        }

        return Ok(result.Usuario);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Eliminar(string id, [FromQuery] string? actorId)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (!string.IsNullOrWhiteSpace(actorId) && string.Equals(actorId, id, StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "No puedes eliminar tu propia cuenta" });
        }

        var bloqueo = await BloqueadoPorSerUltimoAdminAsync(id);
        if (bloqueo is not null) return bloqueo;

        var result = await _supabaseService.DeleteUserAsync(id);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage ?? "No se pudo eliminar la cuenta" });
        }

        return Ok(new { message = "Cuenta eliminada" });
    }

    /// Evita quedarse sin ningún administrador activo (por eliminación,
    /// desactivación, o degradar su rol): si "id" es el único admin activo
    /// que queda, la operación se rechaza.
    private async Task<IActionResult?> BloqueadoPorSerUltimoAdminAsync(string id)
    {
        var staff = await _supabaseService.ListStaffUsersAsync();
        var target = staff.FirstOrDefault(u => string.Equals(u.Id, id, StringComparison.OrdinalIgnoreCase));
        if (target is null || !string.Equals(target.Rol, RolAdministrador, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var otrosAdminsActivos = staff.Any(u =>
            !string.Equals(u.Id, id, StringComparison.OrdinalIgnoreCase) &&
            string.Equals(u.Rol, RolAdministrador, StringComparison.OrdinalIgnoreCase) &&
            u.Activa);

        if (!otrosAdminsActivos)
        {
            return BadRequest(new { message = "No puedes eliminar, desactivar ni degradar al último administrador activo" });
        }

        return null;
    }

    private static string? NormalizarRol(string? rol) =>
        string.IsNullOrWhiteSpace(rol) ? null : rol.Trim().ToLowerInvariant();
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
