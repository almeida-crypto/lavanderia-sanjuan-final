# Checklist de demostración

Haz esta prueba completa al menos un día antes y repítela el 22 de julio.

## Antes de abrir la app

- [ ] Render aparece como **Live**.
- [ ] La URL `/health` muestra `"databaseConfigured": true`.
- [ ] Ambos celulares tienen el APK construido con la misma URL de Render.
- [ ] Un celular tiene la cuenta cliente y el otro la cuenta administradora.

## Flujo del cliente

- [ ] Registrar o iniciar sesión.
- [ ] Agregar, editar, elegir como predeterminada y eliminar una dirección.
- [ ] Agregar una tarjeta de demostración, elegirla como principal y eliminarla.
- [ ] Agendar una recolección con dirección, fecha, horario y pago.
- [ ] Abrir el pedido desde **Mis Pedidos**.
- [ ] Copiar el resumen de factura.
- [ ] Reportar un problema, cancelar o calificar cuando el estado lo permita.

## Flujo del administrador

- [ ] Abrir el panel en una pantalla angosta sin que quede en blanco.
- [ ] Actualizar la lista y encontrar el pedido del cliente.
- [ ] Abrir el detalle, asignar repartidor y cambiar el estado.
- [ ] Confirmar peso y precio final.
- [ ] Copiar el ticket.
- [ ] Agregar o editar un servicio y activar/desactivar su disponibilidad.

## Persistencia entre celulares

- [ ] El cliente actualiza **Mis Pedidos** y ve el cambio hecho por el admin.
- [ ] Cerrar y abrir las dos apps conserva direcciones, tarjetas y pedidos.
- [ ] No apagar ni pausar manualmente Supabase o Render antes de exponer.

Si Render estuvo inactivo, la primera petición puede tardar. Abre `/health`
dos minutos antes de presentar para despertarlo.
