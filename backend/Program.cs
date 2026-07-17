using backend;

var builder = WebApplication.CreateBuilder(args);

// Evita depender del Event Log de Windows y mantiene los logs visibles tanto
// en desarrollo como en el contenedor de Render.
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

builder.Services.AddControllers();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddHttpClient();
builder.Services.AddSingleton<SupabaseService>();
builder.Services.AddSingleton<SupabaseDataService>();

var app = builder.Build();

var supabaseService = app.Services.GetRequiredService<SupabaseService>();
if (supabaseService.IsConfigured)
{
    app.Logger.LogInformation("Supabase configurado para URL {SupabaseUrl}", supabaseService.Url);
}
else
{
    app.Logger.LogWarning("Supabase no está configurado. Configure Supabase:Enabled, Supabase:Url, Supabase:AnonKey y Supabase:ServiceRoleKey para habilitarlo.");
}

app.UseCors();
app.UseAuthorization();
app.MapGet("/health", (SupabaseDataService data) => Results.Ok(new
{
    status = "ok",
    databaseConfigured = data.IsConfigured
}));
app.MapControllers();

app.Run();
