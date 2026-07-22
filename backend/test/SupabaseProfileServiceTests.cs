using System.Net;
using System.Text;
using System.Text.Json.Nodes;
using backend;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace backend.tests;

public class SupabaseProfileServiceTests
{
    [Fact]
    public async Task UpdateProfile_AcceptsDirectUserResponse_AndPreservesMetadata()
    {
        string? updateBody = null;
        var handler = new QueueHttpMessageHandler(
            _ => Task.FromResult(Json(HttpStatusCode.OK, """
                {
                  "id": "user-1",
                  "email": "cliente@example.com",
                  "user_metadata": { "rol": "cliente", "dato_existente": "se conserva" }
                }
                """)),
            async request =>
            {
                updateBody = await request.Content!.ReadAsStringAsync();
                return Json(HttpStatusCode.OK, """
                    {
                      "id": "user-1",
                      "email": "cliente@example.com",
                      "user_metadata": {
                        "nombre": "Cliente",
                        "telefono": "4491234567",
                        "foto_url": "https://example.com/perfil.jpg",
                        "rol": "cliente"
                      }
                    }
                    """);
            });
        var service = CreateService(handler);

        var result = await service.UpdateProfileAsync(
            "user-1", " Cliente ", "cliente@example.com", "4491234567", " https://example.com/perfil.jpg ");

        Assert.True(result.Success);
        Assert.Equal("4491234567", result.Usuario?.Telefono);
        Assert.Equal("https://example.com/perfil.jpg", result.Usuario?.FotoUrl);

        var payload = JsonNode.Parse(updateBody!)!;
        Assert.Equal("Cliente", payload["user_metadata"]?["nombre"]?.GetValue<string>());
        Assert.Equal("se conserva", payload["user_metadata"]?["dato_existente"]?.GetValue<string>());
        Assert.Null(payload["email"]);
    }

    private static SupabaseService CreateService(HttpMessageHandler handler)
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Supabase:Enabled"] = "true",
                ["Supabase:Url"] = "https://demo.supabase.co",
                ["Supabase:AnonKey"] = "anon-demo",
                ["Supabase:ServiceRoleKey"] = "service-demo"
            })
            .Build();

        return new SupabaseService(config, new ProfileHttpClientFactory(handler));
    }

    private static HttpResponseMessage Json(HttpStatusCode statusCode, string body) => new(statusCode)
    {
        Content = new StringContent(body, Encoding.UTF8, "application/json")
    };
}

internal sealed class ProfileHttpClientFactory(HttpMessageHandler handler) : IHttpClientFactory
{
    private readonly HttpClient _client = new(handler);

    public HttpClient CreateClient(string name) => _client;
}

internal sealed class QueueHttpMessageHandler(params Func<HttpRequestMessage, Task<HttpResponseMessage>>[] responses)
    : HttpMessageHandler
{
    private int _index;

    public QueueHttpMessageHandler(params Func<HttpRequestMessage, HttpResponseMessage>[] responses)
        : this(responses.Select<Func<HttpRequestMessage, HttpResponseMessage>, Func<HttpRequestMessage, Task<HttpResponseMessage>>>(
            response => request => Task.FromResult(response(request))).ToArray())
    {
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        if (_index >= responses.Length) throw new InvalidOperationException("No hay respuesta HTTP preparada");
        return responses[_index++](request);
    }
}
