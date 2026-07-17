# Lavandería San Juan

Aplicación escolar de lavandería con dos interfaces:

- Cliente: registro, inicio de sesión, direcciones, métodos de pago,
  recolecciones, pedidos y perfil.
- Administrador: panel, pedidos, clientes y catálogo de servicios.

La aplicación Flutter está en `frontend/` y la API .NET en `backend/`.
Supabase guarda usuarios y datos; Render publica la API para que el mismo APK
funcione en dos o más celulares sin depender de una computadora encendida.

## Preparar la entrega

Sigue en orden [`GUIA_ENTREGA_22_JULIO.md`](GUIA_ENTREGA_22_JULIO.md). Ahí
están los pasos para:

1. crear el proyecto gratuito de Supabase;
2. crear sus tablas con `supabase/schema.sql`;
3. publicar gratis el backend mediante `render.yaml`;
4. crear las cuentas cliente y administrador;
5. generar e instalar el APK en ambos celulares.

No hay cuentas ni contraseñas fijas dentro del código. Las cuentas se crean
en el Supabase de quien presente el proyecto.

## Comprobación local del backend

```bash
cd backend
dotnet build
dotnet run
```

Sin credenciales, `/health` funciona pero las operaciones de datos responden
con un error controlado. En Render, `/health` debe indicar
`"databaseConfigured": true`.

## Compilar el APK publicado

```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://TU-SERVICIO.onrender.com/api
```

La llave `service_role` de Supabase es secreta. Debe existir solamente como
variable privada de Render; nunca se agrega al APK ni al repositorio.
