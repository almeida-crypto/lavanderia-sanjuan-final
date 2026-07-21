using System.Security.Claims;
using backend;
using backend.Controllers;
using Microsoft.AspNetCore.Http;
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
        var validacionPromo = new PromocionValidationService(data);
        var controller = new PedidosController(data, validacionPromo)
        {
            // En producción, [Authorize] ya deja el ClaimsPrincipal armado
            // antes de que la acción se ejecute; acá lo simulamos como un
            // cliente autenticado para poder probar el controlador solo.
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(
                        [
                            new Claim(ClaimTypes.NameIdentifier, "cliente-1"),
                            new Claim(ClaimTypes.Role, "cliente"),
                        ],
                        "TestAuth"))
                }
            }
        };

        var result = await controller.Cancelar("1", new CancelarPedidoRequest
        {
            Razon = "Otro",
            Comentarios = "Necesito cancelar"
        });

        var error = Assert.IsType<ObjectResult>(result);
        Assert.Equal(502, error.StatusCode);
    }
}
