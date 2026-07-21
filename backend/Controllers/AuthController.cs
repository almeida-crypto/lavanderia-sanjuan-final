using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly SupabaseService _supabaseService;

    public AuthController(SupabaseService supabaseService)
    {
        _supabaseService = supabaseService;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Correo) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { message = "Correo y contraseña son requeridos" });
        }

        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        var login = await _supabaseService.LoginAsync(request.Correo, request.Password);
        if (!login.Success)
        {
            return StatusCode(login.StatusCode, new { message = login.ErrorMessage ?? "No se pudo iniciar sesión" });
        }

        // El cliente necesita este token para mandarlo como "Authorization:
        // Bearer" en el resto de las peticiones; sin él, el backend no tiene
        // forma de saber quién está llamando ni con qué rol.
        if (login.Usuario is not null)
        {
            login.Usuario.AccessToken = login.AccessToken;
        }

        return Ok(login.Usuario);
    }

    [HttpPost("registro")]
    public async Task<IActionResult> Registro([FromBody] RegistroRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (string.IsNullOrWhiteSpace(request.Nombre) || string.IsNullOrWhiteSpace(request.Apellido) || string.IsNullOrWhiteSpace(request.Correo) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { message = "Faltan datos obligatorios" });
        }

        var registro = await _supabaseService.RegisterAsync(
            request.Nombre,
            request.Apellido,
            request.Correo,
            request.Telefono ?? string.Empty,
            request.Password);

        if (!registro.Success)
        {
            return StatusCode(registro.StatusCode, new { message = registro.ErrorMessage ?? "No se pudo crear la cuenta" });
        }

        return CreatedAtAction(nameof(Login), new { id = registro.Usuario?.Id }, registro.Usuario);
    }

    [HttpPost("recuperar-password")]
    public async Task<IActionResult> RecuperarPassword([FromBody] RecuperarPasswordRequest request)
    {
        if (!_supabaseService.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = "Supabase no está configurado en el backend" });
        }

        if (string.IsNullOrWhiteSpace(request.Correo))
        {
            return BadRequest(new { message = "Correo requerido" });
        }

        var result = await _supabaseService.RequestPasswordRecoveryAsync(request.Correo);
        if (!result.Success)
        {
            return StatusCode(result.StatusCode, new { message = result.ErrorMessage ?? "No se pudo procesar la recuperación" });
        }

        return Ok(new { message = "Si el correo existe, se enviará un enlace de recuperación" });
    }
}

public class LoginRequest
{
    public string? Correo { get; set; }
    public string? Password { get; set; }
}

public class RegistroRequest
{
    public string? Nombre { get; set; }
    public string? Apellido { get; set; }
    public string? Correo { get; set; }
    public string? Telefono { get; set; }
    public string? Password { get; set; }
}

public class RecuperarPasswordRequest
{
    public string? Correo { get; set; }
}

public class UsuarioDto
{
    public string? Id { get; set; }
    public string? Nombre { get; set; }
    public string? Correo { get; set; }
    public string? Telefono { get; set; }
    public string? Password { get; set; }
    public string? Rol { get; set; }
    public bool Activa { get; set; } = true;
    public string? FotoUrl { get; set; }

    /// Solo se llena en la respuesta de /auth/login: el token de Supabase que
    /// el cliente debe reenviar como "Authorization: Bearer" en el resto de
    /// sus peticiones. En cualquier otra respuesta (listar empleados, etc.)
    /// queda null a propósito.
    public string? AccessToken { get; set; }
}
