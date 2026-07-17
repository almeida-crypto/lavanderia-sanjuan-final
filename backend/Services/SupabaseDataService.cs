using System.Net.Http.Headers;
using System.Text;
using System.Text.Json.Nodes;

namespace backend;

/// Acceso del backend a las tablas de Supabase mediante PostgREST.
/// La service-role key vive únicamente en las variables del servidor.
public sealed class SupabaseDataService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    public SupabaseDataService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    private string? Url => _configuration["Supabase:Url"]?.TrimEnd('/');
    private string? ServiceRoleKey => _configuration["Supabase:ServiceRoleKey"];

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(Url) && !string.IsNullOrWhiteSpace(ServiceRoleKey);

    public Task<JsonArray> ListAsync(string table, string query = "") =>
        SendForArrayAsync(HttpMethod.Get, table, query, null);

    public async Task<JsonObject?> FindOneAsync(string table, string query)
    {
        var rows = await ListAsync(table, query);
        return rows.FirstOrDefault() as JsonObject;
    }

    public async Task<JsonObject> InsertAsync(string table, JsonObject payload)
    {
        var rows = await SendForArrayAsync(HttpMethod.Post, table, string.Empty, payload);
        return rows.FirstOrDefault() as JsonObject
            ?? throw new SupabaseDataException("Supabase no devolvió el registro creado");
    }

    public async Task<JsonObject?> UpdateAsync(string table, string query, JsonObject payload)
    {
        var rows = await SendForArrayAsync(HttpMethod.Patch, table, query, payload);
        return rows.FirstOrDefault() as JsonObject;
    }

    public async Task<bool> DeleteAsync(string table, string query)
    {
        var rows = await SendForArrayAsync(HttpMethod.Delete, table, query, null);
        return rows.Count > 0;
    }

    private async Task<JsonArray> SendForArrayAsync(
        HttpMethod method,
        string table,
        string query,
        JsonObject? payload)
    {
        if (!IsConfigured)
        {
            throw new SupabaseDataException(
                "Faltan Supabase:Url y Supabase:ServiceRoleKey en el backend");
        }

        var suffix = string.IsNullOrWhiteSpace(query) ? string.Empty : $"?{query}";
        var request = new HttpRequestMessage(method, $"{Url}/rest/v1/{table}{suffix}");
        request.Headers.Add("apikey", ServiceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ServiceRoleKey);
        request.Headers.Add("Prefer", "return=representation");
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        if (payload is not null)
        {
            request.Content = new StringContent(payload.ToJsonString(), Encoding.UTF8, "application/json");
        }

        var client = _httpClientFactory.CreateClient();
        var response = await client.SendAsync(request);
        var content = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            var message = "No se pudo completar la operación en Supabase";
            try
            {
                var error = JsonNode.Parse(content);
                message = error?["message"]?.ToString()
                    ?? error?["details"]?.ToString()
                    ?? message;
            }
            catch
            {
                // Conserva el mensaje seguro y no expone credenciales.
            }

            throw new SupabaseDataException(message, (int)response.StatusCode);
        }

        if (string.IsNullOrWhiteSpace(content))
        {
            return new JsonArray();
        }

        return JsonNode.Parse(content) as JsonArray ?? new JsonArray();
    }
}

public sealed class SupabaseDataException : Exception
{
    public SupabaseDataException(string message, int statusCode = 502) : base(message)
    {
        StatusCode = statusCode;
    }

    public int StatusCode { get; }
}
