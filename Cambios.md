# 📋 Registro de Cambios - Lavandería San Juan

Este documento resume todos los cambios, mejoras y nuevas funcionalidades implementadas en el proyecto **Lavandería San Juan**.

---

## 1. 👥 Interfaz y Rol de Empleado (`HomeEmpleadoScreen`)
- **Nuevo Rol `UserRole.empleado`**: Creado e integrado en el enum de usuarios (`usuario.dart`).
- **Navegación Restringida**: Creación de `HomeEmpleadoScreen`, una vista limpia que solo expone dos pestañas (**Panel** y **Pedidos**), ocultando las vistas de Clientes y Servicios.
- **Filtro de Métricas Financieras**: En el dashboard de empleados se oculta la tarjeta de "Ingresos" manteniendo únicamente las estadísticas operativas (*Pedidos de Hoy*, *Entregas Activas*, *Cancelados*).
- **Insignia y Perfil Adaptativo**: En la vista de perfil se muestra la etiqueta e ícono distintivo de **EMPLEADO**.

---

## 2. 🔄 Jerarquía y Secuencia Lógica en Estados de Pedidos
- **Matriz de Transiciones Válidas**: Implementación de `_esTransicionValida` en `actualizar_estado_screen.dart` para garantizar una progresión coherente:
  - `Recibido` ➔ `Repartidor Asignado` ➔ `En Planta` ➔ `Lavando` ➔ `Secando y Doblado` ➔ `Listo` ➔ `En Camino` ➔ `Entregado`.
- **Deshabilitación de Estados Inválidos**: Los estados que rompen la jerarquía lógica se muestran deshabilitados y atenuados con opacidad (0.4).
- **Bloqueo de Modificación en Estados Finales**: Si un pedido se encuentra en `Entregado` o `Cancelado`, se deshabilita el botón de cambiar estado.
- **Soporte de Estado Alerta (Atención)**: Permite marcar alertas manuales y retornar a cualquier estado operativo una vez solventado el inconveniente.

---

## 3. 🚫 Vista Restringida para Pedidos Cancelados
- **Scaffold de Lectura Única**: Si un pedido entra en estado `Cancelado`, `order_detail_screen.dart` reemplaza toda la pantalla con una tarjeta informativa prominente.
- **Ocultamiento de Operaciones**: Se remueven los desgloses de artículos, repartidores asignados, resúmenes de cobro y botones de modificación.
- **Detalles del Motivo**: Se muestra únicamente la información básica de contacto y el motivo exacto por el cual fue cancelado el pedido.

---

## 4. 💵 Método de Pago en Efectivo
- **Soporte en Reserva**: Integración de "Efectivo contra entrega" en `AgendarRecoleccionProvider`.
- **Selección en Pantalla**: Incorporación de la opción seleccionable "Efectivo contra entrega" al inicio de `SeleccionarMetodoPagoScreen`.
- **Adaptación Visual**: `agendar_recoleccion_screen.dart` actualiza dinámicamente la tarjeta de pago mostrando el ícono de billetes y la etiqueta correspondiente.
- **Mapeo a la Base de Datos**: Mapeo transparente hacia el campo `metodoPago` del pedido en Supabase/Backend.

---

## 5. 🛠️ Gestión Completa de Empleados por el Administrador
- **Selector de Pestañas en Directorio**: Pestañas interactivas entre **Clientes** y **Empleados** en `customers_view.dart`.
- **Operaciones CRUD de Personal**: El Administrador puede crear, editar y eliminar accesos de empleados directamente desde la app.
- **Detección Automática de Rol**: El correo de los empleados registrados se valida automáticamente en `AdminProvider` asignándoles el rol de empleado al iniciar sesión.

---

## 6. 🔐 Persistencia de Sesión al Cerrar la App
- **Integración con SharedPreferences**: Guardado automático del usuario autenticado en el dispositivo.
- **Cargador Inicial (`AuthWrapper`)**: Widget en `main.dart` que verifica al iniciar la app si hay una sesión guardada y redirige de forma transparente al panel correspondiente sin solicitar credenciales nuevamente.
- **Cierre de Sesión Limpio**: Al hacer clic en "Cerrar Sesión", la clave almacenada se destruye y regresa limpiamente a la pantalla de login.

---

## 7. 💲 Modelo de Precio Único por Servicio
- **Simplificación Tarifaria**: Eliminación de cobros adicionales según opciones de acabado (doblado/planchado).
- **Cálculo Transparente**: Cada servicio cuenta con un precio único de referencia, garantizando transparencia para el cliente.

---

## 8. 🚚 Interfaz para Repartidores (`HomeRepartidorScreen`)
- **Nuevo Rol `UserRole.repartidor`**: Creado para la gestión logística.
- **Pantalla Especializada**: Diseñada con la línea gráfica de la app (`AppColors`, `GoogleFonts.inter` y bento grid).
- **Pestañas Operativas**:
  - 📥 **Recoger**: Muestra solo los pedidos listos para recolección (`recibido` / `asignado`).
  - 🚚 **Entregar**: Muestra solo los pedidos listos para llevar al cliente (`listo` / `enCamino`).
  - ✅ **Listos**: Historial de entregas completadas.
- **Acciones de Repartidor**:
  - Botón **"MARCAR COMO RECOGIDO"**: Cambia el estado del pedido a `En Planta`.
  - Botón **"MARCAR COMO ENTREGADO"**: Cambia el estado del pedido a `Entregado`.
- **Ruteo Automático**: Integrado en `LoginScreen` y `AuthWrapper`.
