using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using backend.Controllers;
using Microsoft.Extensions.Configuration;

namespace backend;

public class SupabaseService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    public SupabaseService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    public bool IsConfigured => Enabled && !string.IsNullOrWhiteSpace(Url) && !string.IsNullOrWhiteSpace(AnonKey);

    public bool Enabled => bool.TryParse(_configuration["Supabase:Enabled"], out var enabled) ? enabled : false;

    public string? Url => _configuration["Supabase:Url"]?.TrimEnd('/');

    public string? AnonKey => _configuration["Supabase:AnonKey"];

    public string? ServiceRoleKey => _configuration["Supabase:ServiceRoleKey"];

    public async Task<AuthOperationResult> LoginAsync(string correo, string password)
    {
        var payload = new JsonObject
        {
            ["email"] = correo,
            ["password"] = password
        };

        var response = await SendAsync(HttpMethod.Post, "/auth/v1/token?grant_type=password", payload);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "Correo o contraseña incorrectos");
            var statusCode = response.StatusCode == System.Net.HttpStatusCode.BadRequest
                ? StatusCodes.Status401Unauthorized
                : (int)response.StatusCode;

            return new AuthOperationResult(false, statusCode, message, null, null);
        }

        var root = await ReadJsonAsync(response);
        var user = root?["user"];
        var accessToken = root?["access_token"]?.GetValue<string>();

        if (user is null || string.IsNullOrWhiteSpace(accessToken))
        {
            return new AuthOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null, null);
        }

        return new AuthOperationResult(true, StatusCodes.Status200OK, null, MapUser(user), accessToken);
    }

    public async Task<AuthOperationResult> RegisterAsync(string nombre, string apellido, string correo, string telefono, string password)
    {
        var payload = new JsonObject
        {
            ["email"] = correo,
            ["password"] = password,
            ["data"] = new JsonObject
            {
                ["nombre"] = $"{nombre} {apellido}".Trim(),
                ["telefono"] = telefono,
                ["rol"] = "cliente"
            }
        };

        var response = await SendAsync(HttpMethod.Post, "/auth/v1/signup", payload);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo crear la cuenta");
            var statusCode = response.StatusCode == System.Net.HttpStatusCode.UnprocessableEntity
                || response.StatusCode == System.Net.HttpStatusCode.Conflict
                ? StatusCodes.Status409Conflict
                : (int)response.StatusCode;

            return new AuthOperationResult(false, statusCode, message, null, null);
        }

        var root = await ReadJsonAsync(response);
        // Si el proyecto de Supabase pide confirmar el correo (comportamiento por
        // defecto en proyectos nuevos), /signup devuelve el objeto de usuario
        // directamente en la raíz (sin sesión ni el envoltorio "user"), en vez del
        // { user, access_token } que se obtiene cuando la confirmación está desactivada.
        var user = root?["user"] ?? (root?["id"] is not null ? root : null);
        if (user is null)
        {
            return new AuthOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null, null);
        }

        return new AuthOperationResult(true, StatusCodes.Status201Created, null, MapUser(user), null);
    }

    public async Task<UsuarioOperationResult> UpdateProfileAsync(string id, string? nombre, string? correo, string? telefono)
    {
        var currentUserResponse = await SendAsync(HttpMethod.Get, $"/auth/v1/admin/users/{id}", useServiceRole: true);
        if (!currentUserResponse.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(currentUserResponse, "Usuario no encontrado");
            var statusCode = currentUserResponse.StatusCode == System.Net.HttpStatusCode.NotFound
                ? StatusCodes.Status404NotFound
                : (int)currentUserResponse.StatusCode;

            return new UsuarioOperationResult(false, statusCode, message, null);
        }

        var currentRoot = await ReadJsonAsync(currentUserResponse);
        var currentUser = currentRoot?["user"];
        if (currentUser is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        var metadata = currentUser["user_metadata"] as JsonObject ?? new JsonObject();
        if (!string.IsNullOrWhiteSpace(nombre))
        {
            metadata["nombre"] = nombre;
        }
        if (!string.IsNullOrWhiteSpace(telefono))
        {
            metadata["telefono"] = telefono;
        }

        var payload = new JsonObject
        {
            ["email"] = string.IsNullOrWhiteSpace(correo) ? currentUser["email"]?.GetValue<string>() : correo,
            ["user_metadata"] = metadata
        };

        var updateResponse = await SendAsync(HttpMethod.Put, $"/auth/v1/admin/users/{id}", payload, useServiceRole: true);
        if (!updateResponse.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(updateResponse, "No se pudo actualizar el perfil");
            var statusCode = updateResponse.StatusCode == System.Net.HttpStatusCode.Conflict
                ? StatusCodes.Status409Conflict
                : (int)updateResponse.StatusCode;

            return new UsuarioOperationResult(false, statusCode, message, null);
        }

        var updatedRoot = await ReadJsonAsync(updateResponse);
        var updatedUser = updatedRoot?["user"];
        if (updatedUser is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        return new UsuarioOperationResult(true, StatusCodes.Status200OK, null, MapUser(updatedUser));
    }

    public async Task<OperationResult> ChangePasswordAsync(string correo, string passwordActual, string passwordNueva)
    {
        var login = await LoginAsync(correo, passwordActual);
        if (!login.Success || string.IsNullOrWhiteSpace(login.AccessToken))
        {
            var statusCode = login.StatusCode == StatusCodes.Status401Unauthorized
                ? StatusCodes.Status401Unauthorized
                : StatusCodes.Status400BadRequest;
            return new OperationResult(false, statusCode, "La contraseña actual es incorrecta");
        }

        var payload = new JsonObject
        {
            ["password"] = passwordNueva
        };

        var response = await SendAsync(HttpMethod.Put, "/auth/v1/user", payload, accessToken: login.AccessToken);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo actualizar la contraseña");
            return new OperationResult(false, (int)response.StatusCode, message);
        }

        return new OperationResult(true, StatusCodes.Status200OK, null);
    }

    /// Crea una cuenta directamente (correo ya confirmado, sin pasar por el
    /// flujo normal de registro/verificación) con el rol que decida el admin.
    /// Requiere la service_role key porque /auth/v1/admin/users es una
    /// operación privilegiada de Supabase.
    public async Task<UsuarioOperationResult> CreateUserAsync(string nombre, string correo, string password, string rol)
    {
        var payload = new JsonObject
        {
            ["email"] = correo,
            ["password"] = password,
            ["email_confirm"] = true,
            ["user_metadata"] = new JsonObject
            {
                ["nombre"] = nombre,
                ["rol"] = rol
            }
        };

        var response = await SendAsync(HttpMethod.Post, "/auth/v1/admin/users", payload, useServiceRole: true);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo crear la cuenta");
            var statusCode = response.StatusCode == System.Net.HttpStatusCode.UnprocessableEntity
                || response.StatusCode == System.Net.HttpStatusCode.Conflict
                ? StatusCodes.Status409Conflict
                : (int)response.StatusCode;

            return new UsuarioOperationResult(false, statusCode, message, null);
        }

        var root = await ReadJsonAsync(response);
        if (root is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        return new UsuarioOperationResult(true, StatusCodes.Status201Created, null, MapUser(root));
    }

    /// Lista todas las cuentas que no son "cliente" (empleados/admins), para
    /// que el panel de administrador las gestione sin exponer ni mezclar la
    /// lista con los clientes normales.
    public async Task<List<UsuarioDto>> ListStaffUsersAsync()
    {
        var response = await SendAsync(HttpMethod.Get, "/auth/v1/admin/users?per_page=1000", useServiceRole: true);
        if (!response.IsSuccessStatusCode)
        {
            return [];
        }

        var root = await ReadJsonAsync(response);
        var users = root?["users"] as JsonArray;
        if (users is null) return [];

        return users
            .Where(u => u is not null)
            .Select(u => MapUser(u!))
            .Where(u => !string.Equals(u.Rol, "cliente", StringComparison.OrdinalIgnoreCase))
            .ToList();
    }

    /// Cambia el rol de una cuenta ya creada (ej. empleado -> administrador).
    /// A propósito no toca nombre/correo/telefono: es una acción separada y
    /// más sensible que solo el admin real debería poder disparar.
    public async Task<UsuarioOperationResult> UpdateRoleAsync(string id, string nuevoRol)
    {
        var currentUserResponse = await SendAsync(HttpMethod.Get, $"/auth/v1/admin/users/{id}", useServiceRole: true);
        if (!currentUserResponse.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(currentUserResponse, "Usuario no encontrado");
            var statusCode = currentUserResponse.StatusCode == System.Net.HttpStatusCode.NotFound
                ? StatusCodes.Status404NotFound
                : (int)currentUserResponse.StatusCode;

            return new UsuarioOperationResult(false, statusCode, message, null);
        }

        var currentRoot = await ReadJsonAsync(currentUserResponse);
        var currentUser = currentRoot?["user"] ?? currentRoot;
        if (currentUser is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        var metadata = currentUser["user_metadata"] as JsonObject ?? new JsonObject();
        metadata["rol"] = nuevoRol;

        var payload = new JsonObject { ["user_metadata"] = metadata };

        var updateResponse = await SendAsync(HttpMethod.Put, $"/auth/v1/admin/users/{id}", payload, useServiceRole: true);
        if (!updateResponse.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(updateResponse, "No se pudo actualizar el rol");
            return new UsuarioOperationResult(false, (int)updateResponse.StatusCode, message, null);
        }

        var updatedRoot = await ReadJsonAsync(updateResponse);
        if (updatedRoot is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        return new UsuarioOperationResult(true, StatusCodes.Status200OK, null, MapUser(updatedRoot));
    }

    /// Desactiva/reactiva una cuenta usando el "ban" nativo de Supabase Auth:
    /// no borra nada, solo le impide iniciar sesión hasta que se reactive.
    public async Task<UsuarioOperationResult> SetActivaAsync(string id, bool activa)
    {
        var payload = new JsonObject
        {
            // "none" quita el ban; un número de horas muy grande equivale a
            // "desactivada hasta que un admin la reactive a mano".
            ["ban_duration"] = activa ? "none" : "87600h"
        };

        var response = await SendAsync(HttpMethod.Put, $"/auth/v1/admin/users/{id}", payload, useServiceRole: true);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo actualizar el estado de la cuenta");
            return new UsuarioOperationResult(false, (int)response.StatusCode, message, null);
        }

        var root = await ReadJsonAsync(response);
        if (root is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        return new UsuarioOperationResult(true, StatusCodes.Status200OK, null, MapUser(root));
    }

    /// Borra la cuenta por completo (irreversible). A diferencia de
    /// [SetActivaAsync], esto no se puede deshacer desde la app.
    public async Task<OperationResult> DeleteUserAsync(string id)
    {
        var response = await SendAsync(HttpMethod.Delete, $"/auth/v1/admin/users/{id}", useServiceRole: true);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo eliminar la cuenta");
            return new OperationResult(false, (int)response.StatusCode, message);
        }

        return new OperationResult(true, StatusCodes.Status200OK, null);
    }

    public async Task<OperationResult> RequestPasswordRecoveryAsync(string correo)
    {
        var payload = new JsonObject
        {
            ["email"] = correo
        };

        var response = await SendAsync(HttpMethod.Post, "/auth/v1/recover", payload);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo enviar el correo de recuperación");
            return new OperationResult(false, (int)response.StatusCode, message);
        }

        return new OperationResult(true, StatusCodes.Status200OK, null);
    }

    private async Task<HttpResponseMessage> SendAsync(HttpMethod method, string path, JsonObject? payload = null, bool useServiceRole = false, string? accessToken = null)
    {
        if (!IsConfigured)
        {
            throw new InvalidOperationException("Supabase no está configurado");
        }

        var client = _httpClientFactory.CreateClient();
        var request = new HttpRequestMessage(method, $"{Url}{path}");

        var apiKey = useServiceRole && !string.IsNullOrWhiteSpace(ServiceRoleKey)
            ? ServiceRoleKey
            : AnonKey;

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("No hay API key de Supabase configurada");
        }

        request.Headers.Add("apikey", apiKey);

        if (!string.IsNullOrWhiteSpace(accessToken))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        }
        else if (useServiceRole && !string.IsNullOrWhiteSpace(ServiceRoleKey))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ServiceRoleKey);
        }

        if (payload is not null)
        {
            request.Content = new StringContent(payload.ToJsonString(), Encoding.UTF8, "application/json");
        }

        return await client.SendAsync(request);
    }

    private static async Task<JsonNode?> ReadJsonAsync(HttpResponseMessage response)
    {
        var content = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(content))
        {
            return null;
        }

        return JsonNode.Parse(content);
    }

    private static async Task<string> ExtractErrorMessageAsync(HttpResponseMessage response, string fallback)
    {
        var content = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(content))
        {
            return fallback;
        }

        try
        {
            var root = JsonNode.Parse(content);
            var message = root?["msg"]?.GetValue<string>()
                ?? root?["message"]?.GetValue<string>()
                ?? root?["error_description"]?.GetValue<string>()
                ?? fallback;

            return message;
        }
        catch (JsonException)
        {
            return fallback;
        }
    }

    private static UsuarioDto MapUser(JsonNode userNode)
    {
        var metadata = userNode["user_metadata"];
        var correo = userNode["email"]?.GetValue<string>() ?? string.Empty;
        var bannedUntil = userNode["banned_until"]?.GetValue<string>();

        return new UsuarioDto
        {
            Id = userNode["id"]?.GetValue<string>(),
            Nombre = metadata?["nombre"]?.GetValue<string>() ?? correo,
            Correo = correo,
            Telefono = metadata?["telefono"]?.GetValue<string>() ?? userNode["phone"]?.GetValue<string>(),
            Rol = metadata?["rol"]?.GetValue<string>() ?? "cliente",
            // "banned_until" viene vacío para cuentas que nunca se
            // desactivaron, o con una fecha futura mientras SetActivaAsync
            // las mantenga baneadas. Si esa fecha ya pasó, ya no aplica.
            Activa = string.IsNullOrWhiteSpace(bannedUntil) ||
                     (DateTimeOffset.TryParse(bannedUntil, out var hasta) && hasta <= DateTimeOffset.UtcNow)
        };
    }
}

public record OperationResult(bool Success, int StatusCode, string? ErrorMessage);

public record UsuarioOperationResult(bool Success, int StatusCode, string? ErrorMessage, UsuarioDto? Usuario);

public record AuthOperationResult(bool Success, int StatusCode, string? ErrorMessage, UsuarioDto? Usuario, string? AccessToken);
