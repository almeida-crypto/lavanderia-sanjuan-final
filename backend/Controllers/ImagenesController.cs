using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers;

[ApiController]
[Route("api/imagenes")]
[Authorize]
public class ImagenesController : ControllerBase
{
    private readonly SupabaseStorageService _storage;
    public ImagenesController(SupabaseStorageService storage) => _storage = storage;

    [HttpPost]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<IActionResult> Subir([FromForm] IFormFile? archivo, [FromForm] string carpeta = "perfil")
    {
        if (archivo is null) return BadRequest(new { message = "Selecciona una imagen" });
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "usuario";
        var rol = User.FindFirstValue(ClaimTypes.Role);
        carpeta = carpeta.Trim().ToLowerInvariant();
        if (carpeta is not ("perfil" or "servicios" or "promociones" or "evidencias"))
            return BadRequest(new { message = "La carpeta de imagen no es válida" });
        if (carpeta is "servicios" or "promociones" && rol != "administrador") return Forbid();
        if (carpeta is "evidencias" && rol is not ("repartidor" or "administrador" or "empleado")) return Forbid();

        try
        {
            var url = await _storage.UploadImageAsync(archivo, carpeta, userId);
            return Ok(new { url });
        }
        catch (SupabaseDataException ex)
        {
            return StatusCode(ex.StatusCode, new { message = ex.Message });
        }
    }
}
