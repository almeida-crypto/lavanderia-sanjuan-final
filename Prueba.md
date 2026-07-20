# 🧪 Guía de Pruebas - Lavandería San Juan

Este documento contiene los pasos detallados para probar todas las funcionalidades y roles de la aplicación **Lavandería San Juan**.

---

## 🚀 Cómo Iniciar la Aplicación

Para ejecutar la aplicación localmente en Flutter, abre una terminal en la carpeta `frontend` y corre:

```bash
cd frontend
flutter run -d chrome   # O usa flutter run -d windows
```

---

## 👤 1. Modo Cliente (`cliente`)

### A. Iniciar Sesión o Crear Cuenta
1. En la pantalla de login, presiona **"Crear Cuenta"** o ingresa las credenciales de un cliente.
2. Inicia sesión. Serás redirigido automáticamente a la **HomeClienteScreen**.

### B. Probar Reserva de Recolección y Pago en Efectivo
1. Presiona el botón de **"Agendar Recolección"** o selecciona un servicio (ej. *Lavado y Plegado*).
2. Selecciona la cantidad, aroma y opciones de acabado.
3. En la sección **Método de Pago**, presiona **"Cambiar"** o **"Agregar"**.
4. En la parte superior de la pantalla de métodos de pago, selecciona **"Efectivo contra entrega"**.
5. Presiona **"Confirmar Método de Pago"**. Observa cómo la tarjeta de pago muestra el ícono de billetes y la etiqueta de efectivo.
6. Completa el agendamiento del pedido.

---

## 👑 2. Modo Administrador (`administrador`)

### A. Asignación de Rol
Para probar como Administrador, asegúrate de que tu usuario tenga el metadata `"rol": "administrador"` en Supabase o inicia sesión con una cuenta de administrador.

```sql
UPDATE auth.users
SET raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"rol":"administrador"}'::jsonb
WHERE email = 'tu_admin@correo.com';
```

### B. Probar Gestión de Empleados
1. Inicia sesión como administrador. Verás las 4 pestañas del panel: **Dashboard**, **Pedidos**, **Clientes/Empleados** y **Servicios**.
2. Ve a la pestaña **Clientes**.
3. En la parte superior, presiona la pestaña **"Empleados"**.
4. **Agregar Empleado**: Presiona el botón **"+ Agregar"**, ingresa un Nombre, Correo y Teléfono, y confirma. El empleado aparecerá inmediatamente en la lista.
5. **Editar Empleado**: Presiona el ícono de lápiz ✏️ en la tarjeta de un empleado para modificar sus datos.
6. **Revocar Empleado**: Presiona el ícono de basura 🗑️ para revocar el acceso.

### C. Probar Modificación Jerárquica de Estados
1. Ve a la pestaña **Pedidos** y abre cualquier pedido en estado `Recibido`.
2. Presiona **"Actualizar Estado"**.
3. Observa cómo los estados no válidos o saltos ilógicos están **deshabilitados y atenuados**.
4. Cambia el estado a `Repartidor Asignado` o `En Planta`.
5. Si cambias un pedido a `Cancelado`, regresa a la vista del detalle del pedido. Verás que toda la interfaz se transforma en una pantalla informativa de lectura única (**PEDIDO CANCELADO**), bloqueando cualquier edición.

---

## 👔 3. Modo Empleado (`empleado`)

### A. Iniciar Sesión como Empleado
Inicia sesión con cualquier correo que haya sido registrado en la lista de empleados por el Administrador (o un usuario con metadata `"rol": "empleado"`).

```sql
UPDATE auth.users
SET raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"rol":"empleado"}'::jsonb
WHERE email = 'tu_empleado@correo.com';
```

### B. Verificación de Restricciones
1. Observa que el menú inferior solo cuenta con **2 pestañas**: **Panel** y **Pedidos** (Clientes y Servicios están ocultos).
2. En el **Panel**, la tarjeta de "Ingresos" financieros no se muestra.
3. Ve a la pestaña **Pedidos** y abre un pedido. Puedes avanzar el estado del pedido según el flujo jerárquico permitido.
4. Intenta modificar un pedido cancelado: verás que no se permite ninguna modificación.

---

## 🚚 4. Modo Repartidor (`repartidor`)

### A. Iniciar Sesión como Repartidor
Inicia sesión con un usuario configurado con el rol de repartidor:

```sql
UPDATE auth.users
SET raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"rol":"repartidor"}'::jsonb
WHERE email = 'tu_repartidor@correo.com';
```

### B. Probar Recolecciones y Entregas
1. Al iniciar sesión, entrarás a la **HomeRepartidorScreen**.
2. **Pestaña Recoger**: Verás solo los pedidos pendientes de recolección (`Recibido` / `Asignado`).
   - Observa que se muestra claramente el nombre del cliente, teléfono y la **Ubicación de Recolección**.
   - Presiona **"MARCAR COMO RECOGIDO"** y confirma en el diálogo. El pedido cambiará a `En Planta` y desaparecerá de la lista de recolecciones.
3. **Pestaña Entregar**: Cuando un pedido esté listo (`Listo` / `En Camino`), aparecerá en esta pestaña.
   - Presiona **"MARCAR COMO ENTREGADO"** y confirma. El pedido pasará al historial de **Listos**.

---

## 🔐 5. Prueba de Persistencia de Sesión

1. Inicia sesión en cualquiera de los roles (Cliente, Admin, Empleado o Repartidor).
2. Cierra la ventana del navegador o detén la aplicación.
3. Vuelve a ejecutar `flutter run`.
4. Observa cómo la aplicación verifica la sesión almacenada en `SharedPreferences` y te dirige **directamente a tu panel sin pedir contraseña nuevamente**.
5. Ve al perfil y presiona **"Cerrar Sesión"**. Cierra la app y vuelve a abrirla: ahora te solicitará credenciales en el Login.
