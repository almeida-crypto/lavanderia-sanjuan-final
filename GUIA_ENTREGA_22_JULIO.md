# Preparación de la entrega del 22 de julio

## 1. Crear Supabase

1. Crea un proyecto gratuito en <https://supabase.com/dashboard>.
2. Abre **SQL Editor**, crea una consulta y pega todo el contenido de
   `supabase/schema.sql`. Pulsa **Run**.
3. En **Authentication > Providers > Email**, desactiva temporalmente
   **Confirm email** para que las cuentas de demostración entren inmediatamente.
4. Copia de **Project Settings > API** estos tres valores (para esta entrega,
   usa las llaves JWT heredadas que empiezan con `eyJ` si Supabase muestra
   también llaves nuevas):
   - Project URL.
   - `anon` / publishable key.
   - `service_role` / secret key.

La `service_role` es secreta: se pega únicamente en Render, nunca en Flutter,
GitHub, capturas ni chats.

## 2. Publicar el backend gratis en Render

1. Entra a <https://dashboard.render.com/> con GitHub.
2. Elige **New > Blueprint** y selecciona este repositorio.
3. Render detectará `render.yaml`. Elige el plan **Free**.
4. Cuando pida variables, pega:
   - `Supabase__Url`: Project URL.
   - `Supabase__AnonKey`: anon/publishable key.
   - `Supabase__ServiceRoleKey`: service_role/secret key.
5. Espera a que aparezca **Live**. Abre la URL terminada en `/health` y
   confirma que muestre `{"status":"ok","databaseConfigured":true}`.

## 3. Crear cuentas de demostración

1. Genera primero un APK apuntando a la URL de Render (paso 4).
2. Registra desde la app una cuenta de cliente y una de administrador.
3. En Supabase abre **SQL Editor** y ejecuta, cambiando el correo:

```sql
update auth.users
set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb)
  || '{"rol":"administrador"}'::jsonb
where email = 'CORREO_DEL_ADMIN';
```

4. Cierra sesión y vuelve a entrar con la cuenta administradora.

## 4. Generar el APK

Desde la carpeta `frontend`, reemplaza la URL por la URL real de Render:

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://TU-SERVICIO.onrender.com/api
```

El archivo queda en:

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

Instala el mismo APK en los dos celulares. Cada uno entra con una cuenta
distinta y ambos comparten los mismos datos de Supabase.

## 5. Ensayo antes de la entrega

Render gratuito se duerme después de un periodo sin tráfico. Dos minutos antes
de presentar, abre `https://TU-SERVICIO.onrender.com/health` y espera la
respuesta.

Prueba en este orden:

1. Cliente inicia sesión y agrega una dirección.
2. Cliente agrega una tarjeta de demostración. Solo se guardan marca, últimos
   cuatro dígitos y vencimiento; el número completo y el CVV se descartan.
3. Cliente agenda un pedido.
4. Administrador actualiza el panel y ve el pedido.
5. Administrador cambia estado, asigna repartidor y confirma precio.
6. Cliente desliza para actualizar **Mis Pedidos** y ve el cambio.
7. Reinicia ambas apps y confirma que los datos continúan.
