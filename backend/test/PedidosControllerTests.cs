using backend;
using backend.Controllers;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace backend.tests;

public class PedidosControllerTests
{
    [Fact]
    public async Task CancelarPedido_SinSupabase_DeberiaRetornarErrorControlado()
    {
        var config = new ConfigurationBuilder().Build();
        var data = new SupabaseDataService(config, new FakeHttpClientFactory());
        var controller = new PedidosController(data);

        var result = await controller.Cancelar("1", new CancelarPedidoRequest
        {
            Razon = "Otro",
            Comentarios = "Necesito cancelar"
        });

        var error = Assert.IsType<ObjectResult>(result);
        Assert.Equal(502, error.StatusCode);
    }
}
