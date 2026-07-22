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

            return new AuthOperationResult(false, statusCode, message, null, null, null);
        }

        var root = await ReadJsonAsync(response);
        var user = root?["user"];
        var accessToken = root?["access_token"]?.GetValue<string>();
        var refreshToken = root?["refresh_token"]?.GetValue<string>();

        if (user is null || string.IsNullOrWhiteSpace(accessToken))
        {
            return new AuthOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null, null, null);
        }

        return new AuthOperationResult(true, StatusCodes.Status200OK, null, MapUser(user), accessToken, refreshToken);
    }

    public async Task<AuthOperationResult> RefreshSessionAsync(string refreshToken)
    {
        var payload = new JsonObject { ["refresh_token"] = refreshToken };
        var response = await SendAsync(HttpMethod.Post, "/auth/v1/token?grant_type=refresh_token", payload);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "La sesión venció");
            return new AuthOperationResult(false, (int)response.StatusCode, message, null, null, null);
        }

        var root = await ReadJsonAsync(response);
        var user = root?["user"];
        var accessToken = root?["access_token"]?.GetValue<string>();
        var nextRefreshToken = root?["refresh_token"]?.GetValue<string>();
        if (user is null || string.IsNullOrWhiteSpace(accessToken))
            return new AuthOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null, null, null);

        return new AuthOperationResult(true, StatusCodes.Status200OK, null, MapUser(user), accessToken, nextRefreshToken);
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

            return new AuthOperationResult(false, statusCode, message, null, null, null);
        }

        var root = await ReadJsonAsync(response);
        // Si el proyecto de Supabase pide confirmar el correo (comportamiento por
        // defecto en proyectos nuevos), /signup devuelve el objeto de usuario
        // directamente en la raíz (sin sesión ni el envoltorio "user"), en vez del
        // { user, access_token } que se obtiene cuando la confirmación está desactivada.
        var user = root?["user"] ?? (root?["id"] is not null ? root : null);
        if (user is null)
        {
            return new AuthOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null, null, null);
        }

        return new AuthOperationResult(true, StatusCodes.Status201Created, null, MapUser(user), null, null);
    }

    public async Task<UsuarioOperationResult> UpdateProfileAsync(
        string id, string? nombre, string? correo, string? telefono, string? fotoUrl = null)
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
        // GoTrue puede devolver el usuario directamente o dentro de { user }.
        // Aceptamos ambas formas para no convertir una respuesta válida en 502.
        var currentUser = currentRoot?["user"] ?? (currentRoot?["id"] is not null ? currentRoot : null);
        if (currentUser is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        // Este nodo pertenece al JSON de la respuesta. Hay que clonarlo antes
        // de insertarlo en otro árbol o JsonNode lanza "already has a parent".
        var metadata = currentUser["user_metadata"]?.DeepClone() as JsonObject ?? new JsonObject();
        if (!string.IsNullOrWhiteSpace(nombre))
        {
            metadata["nombre"] = nombre.Trim();
        }
        if (!string.IsNullOrWhiteSpace(telefono))
        {
            metadata["telefono"] = telefono.Trim();
        }
        if (!string.IsNullOrWhiteSpace(fotoUrl))
        {
            metadata["foto_url"] = fotoUrl.Trim();
        }

        var payload = new JsonObject
        {
            ["user_metadata"] = metadata
        };

        // Reenviar el mismo correo que ya tiene la cuenta (sin cambios) hace
        // que el API de administración de Supabase lo trate como un intento
        // de cambiar a un correo "ya registrado" (por esa misma cuenta) y
        // responda 409. Por eso solo se manda "email" cuando de verdad cambió.
        var correoActual = currentUser["email"]?.GetValue<string>();
        if (!string.IsNullOrWhiteSpace(correo) &&
            !string.Equals(correo.Trim(), correoActual?.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            payload["email"] = correo.Trim();
        }

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
        var updatedUser = updatedRoot?["user"] ?? (updatedRoot?["id"] is not null ? updatedRoot : null);
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

    public async Task<AuthOperationResult> CreateUserAsync(string nombre, string correo, string password, string rol, string? telefono = null)
    {
        var payload = new JsonObject
        {
            ["email"] = correo,
            ["password"] = password,
            ["email_confirm"] = true,
            ["user_metadata"] = new JsonObject
            {
                ["nombre"] = nombre,
                ["rol"] = rol,
                ["telefono"] = telefono
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

            return new AuthOperationResult(false, statusCode, message, null, null, null);
        }

        var root = await ReadJsonAsync(response);
        if (root is null)
        {
            return new AuthOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null, null, null);
        }

        return new AuthOperationResult(true, StatusCodes.Status201Created, null, MapUser(root), null, null);
    }

    public async Task<List<UsuarioDto>> ListStaffUsersAsync()
    {
        var response = await SendAsync(HttpMethod.Get, "/auth/v1/admin/users?per_page=1000", useServiceRole: true);
        if (!response.IsSuccessStatusCode)
        {
            return [];
        }

        var root = await ReadJsonAsync(response);
        var users = root?["users"] as JsonArray;
        if (users is null)
        {
            return [];
        }

        var staff = new List<UsuarioDto>();
        foreach (var userNode in users)
        {
            if (userNode is null) continue;
            var mapped = MapUser(userNode);
            if (mapped.Rol != "cliente")
            {
                staff.Add(mapped);
            }
        }

        return staff;
    }

    public async Task<UsuarioOperationResult> UpdateRoleAsync(string id, string rol)
    {
        var currentUserResponse = await SendAsync(HttpMethod.Get, $"/auth/v1/admin/users/{id}", useServiceRole: true);
        if (!currentUserResponse.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(currentUserResponse, "Usuario no encontrado");
            return new UsuarioOperationResult(false, (int)currentUserResponse.StatusCode, message, null);
        }

        var currentRoot = await ReadJsonAsync(currentUserResponse);
        var currentUser = currentRoot?["user"] ?? currentRoot;
        var metadata = currentUser?["user_metadata"] as JsonObject ?? new JsonObject();
        metadata["rol"] = rol;

        var payload = new JsonObject { ["user_metadata"] = metadata };
        var updateResponse = await SendAsync(HttpMethod.Put, $"/auth/v1/admin/users/{id}", payload, useServiceRole: true);
        if (!updateResponse.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(updateResponse, "No se pudo cambiar el rol");
            return new UsuarioOperationResult(false, (int)updateResponse.StatusCode, message, null);
        }

        var updatedRoot = await ReadJsonAsync(updateResponse);
        var updatedUser = updatedRoot?["user"] ?? updatedRoot;
        if (updatedUser is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        return new UsuarioOperationResult(true, StatusCodes.Status200OK, null, MapUser(updatedUser));
    }

    public async Task<UsuarioOperationResult> SetActivaAsync(string id, bool activa)
    {
        var payload = new JsonObject
        {
            ["ban_duration"] = activa ? "none" : "87600h"
        };

        var response = await SendAsync(HttpMethod.Put, $"/auth/v1/admin/users/{id}", payload, useServiceRole: true);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo cambiar el estado de la cuenta");
            return new UsuarioOperationResult(false, (int)response.StatusCode, message, null);
        }

        var root = await ReadJsonAsync(response);
        var user = root?["user"] ?? root;
        if (user is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        return new UsuarioOperationResult(true, StatusCodes.Status200OK, null, MapUser(user));
    }

    public async Task<UsuarioOperationResult> SetPasswordAsync(string id, string nuevaPassword)
    {
        var payload = new JsonObject
        {
            ["password"] = nuevaPassword
        };

        var response = await SendAsync(HttpMethod.Put, $"/auth/v1/admin/users/{id}", payload, useServiceRole: true);
        if (!response.IsSuccessStatusCode)
        {
            var message = await ExtractErrorMessageAsync(response, "No se pudo cambiar la contraseña");
            return new UsuarioOperationResult(false, (int)response.StatusCode, message, null);
        }

        var root = await ReadJsonAsync(response);
        var user = root?["user"] ?? root;
        if (user is null)
        {
            return new UsuarioOperationResult(false, StatusCodes.Status502BadGateway, "Respuesta inválida de Supabase", null);
        }

        return new UsuarioOperationResult(true, StatusCodes.Status200OK, null, MapUser(user));
    }

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

    /// Valida un access token de Supabase preguntándole directamente al
    /// servidor de autenticación quién es (en vez de verificar la firma del
    /// JWT localmente, para lo cual necesitaríamos el secreto de firma que no
    /// tenemos configurado). Es lo que usa SupabaseAuthHandler para saber
    /// quién llama a la API y con qué rol, en cada petición protegida.
    public async Task<UsuarioDto?> GetUserFromTokenAsync(string accessToken)
    {
        var response = await SendAsync(HttpMethod.Get, "/auth/v1/user", accessToken: accessToken);
        if (!response.IsSuccessStatusCode)
        {
            return null;
        }

        var root = await ReadJsonAsync(response);
        if (root is null)
        {
            return null;
        }

        return MapUser(root);
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
        var activa = string.IsNullOrWhiteSpace(bannedUntil) ||
            (DateTimeOffset.TryParse(bannedUntil, out var hasta) && hasta <= DateTimeOffset.UtcNow);

        return new UsuarioDto
        {
            Id = userNode["id"]?.GetValue<string>(),
            Nombre = metadata?["nombre"]?.GetValue<string>() ?? correo,
            Correo = correo,
            Telefono = metadata?["telefono"]?.GetValue<string>() ?? userNode["phone"]?.GetValue<string>(),
            FotoUrl = metadata?["foto_url"]?.GetValue<string>(),
            Rol = metadata?["rol"]?.GetValue<string>() ?? "cliente",
            Activa = activa
        };
    }
}

public record OperationResult(bool Success, int StatusCode, string? ErrorMessage);

public record UsuarioOperationResult(bool Success, int StatusCode, string? ErrorMessage, UsuarioDto? Usuario);

public record AuthOperationResult(bool Success, int StatusCode, string? ErrorMessage, UsuarioDto? Usuario, string? AccessToken, string? RefreshToken);
