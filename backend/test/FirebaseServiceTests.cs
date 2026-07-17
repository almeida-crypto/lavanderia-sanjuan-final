using backend;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace backend.tests;

public class SupabaseServiceTests
{
    [Fact]
    public void Inicializacion_ConSupabaseDeshabilitado_NoDebeConfigurar()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Supabase:Enabled"] = "false",
                ["Supabase:Url"] = "https://demo.supabase.co",
                ["Supabase:AnonKey"] = "anon-demo"
            })
            .Build();

        var factory = new FakeHttpClientFactory();
        var service = new SupabaseService(config, factory);

        Assert.False(service.IsConfigured);
        Assert.Equal("https://demo.supabase.co", service.Url);
    }
}

internal sealed class FakeHttpClientFactory : IHttpClientFactory
{
    public HttpClient CreateClient(string name) => new();
}
