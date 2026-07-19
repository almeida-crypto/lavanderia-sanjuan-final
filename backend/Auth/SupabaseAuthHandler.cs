using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace backend.Auth;

/// Autentica cada petición validando el "Authorization: Bearer <token>"
/// directamente contra Supabase (GET /auth/v1/user), y arma un
/// ClaimsPrincipal con el id, correo y rol reales de esa cuenta. A partir de
/// aquí, [Authorize] y [Authorize(Roles = "administrador")] en los
/// controladores ya reflejan quién es realmente el que llama, en vez de
/// confiar en lo que la app cliente diga que es.
public class SupabaseAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly SupabaseService _supabaseService;

    public SupabaseAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        SupabaseService supabaseService)
        : base(options, logger, encoder)
    {
        _supabaseService = supabaseService;
    }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("Authorization", out var authHeader))
        {
            return AuthenticateResult.NoResult();
        }

        var raw = authHeader.ToString();
        if (!raw.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return AuthenticateResult.NoResult();
        }

        var token = raw["Bearer ".Length..].Trim();
        if (string.IsNullOrWhiteSpace(token))
        {
            return AuthenticateResult.NoResult();
        }

        var usuario = await _supabaseService.GetUserFromTokenAsync(token);
        if (usuario is null || string.IsNullOrWhiteSpace(usuario.Id))
        {
            return AuthenticateResult.Fail("Token inválido o expirado");
        }

        if (!usuario.Activa)
        {
            return AuthenticateResult.Fail("Esta cuenta está desactivada");
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, usuario.Id),
            new Claim(ClaimTypes.Email, usuario.Correo ?? string.Empty),
            new Claim(ClaimTypes.Role, usuario.Rol ?? "cliente"),
        };
        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme.Name);
        return AuthenticateResult.Success(ticket);
    }
}
