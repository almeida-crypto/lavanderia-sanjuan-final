using System.Net.Http.Headers;

namespace backend;

/// Sube imágenes a Supabase Storage desde el backend. La service-role key
/// nunca sale de Render ni se entrega a la aplicación móvil.
public sealed class SupabaseStorageService
{
    private const string Bucket = "app-images";
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    public SupabaseStorageService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    private string? Url => _configuration["Supabase:Url"]?.TrimEnd('/');
    private string? ServiceRoleKey => _configuration["Supabase:ServiceRoleKey"];

    public async Task<string> UploadImageAsync(IFormFile file, string folder, string ownerId)
    {
        if (string.IsNullOrWhiteSpace(Url) || string.IsNullOrWhiteSpace(ServiceRoleKey))
            throw new SupabaseDataException("Supabase Storage no está configurado", 503);
        if (file.Length == 0 || file.Length > 5 * 1024 * 1024)
            throw new SupabaseDataException("La imagen debe pesar menos de 5 MB", 400);

        var extensionArchivo = Path.GetExtension(file.FileName).ToLowerInvariant();
        var extension = file.ContentType.ToLowerInvariant() switch
        {
            "image/jpeg" => ".jpg",
            "image/png" => ".png",
            "image/webp" => ".webp",
            "application/octet-stream" when extensionArchivo is ".jpg" or ".jpeg" => ".jpg",
            "application/octet-stream" when extensionArchivo == ".png" => ".png",
            "application/octet-stream" when extensionArchivo == ".webp" => ".webp",
            _ => throw new SupabaseDataException("Solo se aceptan imágenes JPG, PNG o WebP", 400)
        };
        var safeFolder = new string(folder.ToLowerInvariant().Where(c => char.IsLetterOrDigit(c) || c == '-').ToArray());
        var safeOwner = new string(ownerId.Where(c => char.IsLetterOrDigit(c) || c == '-').ToArray());
        var path = $"{safeFolder}/{safeOwner}/{Guid.NewGuid():N}{extension}";

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"{Url}/storage/v1/object/{Bucket}/{path}");
        request.Headers.Add("apikey", ServiceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ServiceRoleKey);
        request.Headers.Add("x-upsert", "false");
        request.Content = new StreamContent(file.OpenReadStream());
        request.Content.Headers.ContentType = new MediaTypeHeaderValue(extension switch
        {
            ".jpg" => "image/jpeg",
            ".png" => "image/png",
            _ => "image/webp"
        });

        var response = await _httpClientFactory.CreateClient().SendAsync(request);
        if (!response.IsSuccessStatusCode)
            throw new SupabaseDataException("No se pudo guardar la imagen", (int)response.StatusCode);

        return $"{Url}/storage/v1/object/public/{Bucket}/{path}";
    }
}
