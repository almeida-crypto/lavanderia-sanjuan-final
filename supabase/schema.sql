create extension if not exists pgcrypto;

create table if not exists public.direcciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id text not null,
  titulo text not null,
  calle text not null default '',
  depto text,
  colonia text not null default '',
  entre_calles text,
  ciudad text not null default '',
  estado text not null default '',
  codigo_postal text not null default '',
  telefono text,
  nota text,
  predeterminada boolean not null default false,
  created_at timestamptz not null default now()
);

-- Si la tabla ya existía (base desplegada antes de este cambio), agrega las
-- columnas nuevas sin perder las direcciones guardadas. "lineas" queda como
-- columna huérfana sin usar (no se borra para no perder datos existentes).
alter table public.direcciones add column if not exists calle text not null default '';
alter table public.direcciones add column if not exists depto text;
alter table public.direcciones add column if not exists colonia text not null default '';
alter table public.direcciones add column if not exists entre_calles text;
alter table public.direcciones add column if not exists ciudad text not null default '';
alter table public.direcciones add column if not exists estado text not null default '';
alter table public.direcciones add column if not exists codigo_postal text not null default '';

-- Catálogo real de códigos postales de México (datos oficiales de SEPOMEX,
-- ~145,900 filas: cada CP puede tener varias colonias). Se usa para que al
-- escribir el código postal en el formulario de dirección se rellenen solos
-- estado/ciudad y se sugieran las colonias reales de ese CP, y para poder
-- avisar si el cliente escribió un CP que no existe. La tabla se crea vacía
-- aquí; los datos se importan una sola vez desde
-- supabase/codigos_postales.csv usando el importador de CSV del Table
-- Editor de Supabase (demasiadas filas para un insert por SQL).
create table if not exists public.codigos_postales (
  id bigint generated always as identity primary key,
  codigo_postal text not null,
  estado text not null,
  municipio text not null,
  ciudad text not null default '',
  colonia text not null,
  tipo_asentamiento text
);
create index if not exists codigos_postales_por_cp on public.codigos_postales(codigo_postal);

create table if not exists public.metodos_pago (
  id uuid primary key default gen_random_uuid(),
  usuario_id text not null,
  marca text not null check (marca in ('visa', 'mastercard')),
  ultimos_digitos char(4) not null check (ultimos_digitos ~ '^[0-9]{4}$'),
  expira char(5) not null,
  principal boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.servicios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  icono text not null default 'local_laundry_service',
  precio numeric(10,2) not null default 0 check (precio >= 0),
  unidad text not null default 'kg',
  descripcion text not null default '',
  activo boolean not null default true,
  como_funciona text not null default '',
  tiempo_estimado text not null default '',
  items_sugeridos jsonb not null default '[]'::jsonb,
  beneficios jsonb not null default '[]'::jsonb,
  opciones_acabado jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

-- Si la tabla ya existía (base desplegada antes de este cambio), agrega las
-- columnas nuevas del contenido editable del servicio.
alter table public.servicios add column if not exists como_funciona text not null default '';
alter table public.servicios add column if not exists tiempo_estimado text not null default '';
alter table public.servicios add column if not exists items_sugeridos jsonb not null default '[]'::jsonb;
alter table public.servicios add column if not exists beneficios jsonb not null default '[]'::jsonb;
alter table public.servicios add column if not exists opciones_acabado jsonb not null default '[]'::jsonb;
alter table public.servicios add column if not exists imagen_url text;

-- Catálogo global de opciones (ej. "Doblado en Gancho"): se definen UNA vez
-- aquí y cada servicio en "servicios.opciones_acabado" solo guarda una
-- referencia {"opcionId": ..., "precioAdicional": ...} a estas filas, para
-- no tener que redefinir "Doblado" por separado en cada servicio que lo
-- ofrezca (y que el mismo Doblado pueda costar distinto según el servicio).
create table if not exists public.opciones (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  descripcion text not null default '',
  activa boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.pedidos (
  id uuid primary key default gen_random_uuid(),
  numero_orden bigserial unique,
  cliente_id text not null,
  cliente_nombre text not null default 'Cliente',
  cliente_email text,
  cliente_telefono text,
  servicio text not null,
  fecha text not null,
  franja_horaria text not null default 'Tarde',
  direccion text not null default 'Sin dirección',
  instrucciones text not null default '',
  fragancia text,
  cantidad_aproximada integer,
  metodo_pago text,
  opcion_acabado text,
  precio_acabado numeric(10,2),
  repartidor text,
  repartidor_id text,
  peso_confirmado numeric(10,2),
  total numeric(10,2) not null default 0,
  total_confirmado numeric(10,2),
  estado text not null default 'Recibido',
  razon_cancelacion text,
  comentarios_cancelacion text,
  calificacion integer check (calificacion between 1 and 5),
  resena text,
  reporte_tipo text,
  reporte_detalles text,
  reporte_estado text,
  reporte_respuesta text,
  reporte_actualizado_at timestamptz,
  created_at timestamptz not null default now()
);

-- Si la tabla ya existía, agrega la opción de acabado elegida por el cliente
-- (ej. "Doblado en Gancho" para Lavado, o el nivel de tarifa de Tintorería).
alter table public.pedidos add column if not exists opcion_acabado text;
alter table public.pedidos add column if not exists precio_acabado numeric(10,2);
alter table public.pedidos add column if not exists repartidor_id text;
alter table public.pedidos add column if not exists reporte_estado text;
alter table public.pedidos add column if not exists reporte_respuesta text;
alter table public.pedidos add column if not exists reporte_actualizado_at timestamptz;

-- Los reportes son incidencias separadas del avance del pedido. Versiones
-- anteriores reemplazaban la etapa por "Atención" y el pedido parecía quedar
-- sin terminar; se recuperan como solicitudes abiertas sin bloquear el flujo.
update public.pedidos
set reporte_estado = 'Abierto'
where reporte_tipo is not null and reporte_estado is null;

update public.pedidos
set estado = 'Pedido recibido'
where estado = 'Atención' and reporte_tipo is not null;

-- Número de orden corto y legible (1, 2, 3...) en vez del uuid interno, que
-- es horrible de mostrarle al cliente/admin. "bigserial" ya lo asigna solo
-- en cada fila nueva; esto solo hace falta para que las filas existentes
-- también tengan uno.
alter table public.pedidos add column if not exists numero_orden bigserial unique;

-- Código de promoción aplicado a este pedido (si el cliente usó uno), en
-- mayúsculas para que contar cuántas veces lo ha usado un cliente sea una
-- comparación exacta sin importar cómo lo haya tecleado.
alter table public.pedidos add column if not exists codigo_promocion text;

create table if not exists public.promociones (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  titulo text not null,
  descripcion text not null default '',
  descuento_porcentaje numeric(5,2) not null default 0 check (descuento_porcentaje >= 0 and descuento_porcentaje <= 100),
  servicio_aplicable text,
  fecha_inicio timestamptz not null default now(),
  fecha_fin timestamptz,
  activa boolean not null default true,
  created_at timestamptz not null default now()
);

-- Límite de usos por cliente (null = sin límite) y cantidad mínima de
-- prendas/kg para que el código aplique (null = sin mínimo). Ambos se
-- validan de verdad en el backend, no solo en la pantalla del cliente.
alter table public.promociones add column if not exists usos_por_cliente integer check (usos_por_cliente is null or usos_por_cliente > 0);
alter table public.promociones add column if not exists cantidad_minima integer check (cantidad_minima is null or cantidad_minima > 0);
alter table public.promociones add column if not exists imagen_url text;

-- Imágenes públicas de perfil, servicios y promociones. Las escrituras se
-- hacen únicamente desde el backend autenticado con service role; el celular
-- solo recibe la URL pública resultante.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'app-images',
  'app-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create unique index if not exists una_direccion_principal_por_usuario
  on public.direcciones(usuario_id) where predeterminada;
create unique index if not exists una_tarjeta_principal_por_usuario
  on public.metodos_pago(usuario_id) where principal;
create index if not exists pedidos_por_cliente on public.pedidos(cliente_id);
create index if not exists pedidos_por_repartidor on public.pedidos(repartidor_id);
create index if not exists pedidos_recientes on public.pedidos(created_at desc);

alter table public.direcciones enable row level security;
alter table public.metodos_pago enable row level security;
alter table public.servicios enable row level security;
alter table public.pedidos enable row level security;
alter table public.promociones enable row level security;
alter table public.opciones enable row level security;
alter table public.codigos_postales enable row level security;

insert into public.opciones (nombre, descripcion) values
  ('Doblado Estándar', 'Perfecto para el uso diario, doblado y apilado con cuidado.'),
  ('Doblado en Gancho', 'Ideal para camisas y vestidos, evita las arrugas.'),
  ('Doblado Especial', 'Manejo delicado para telas de lujo o piezas grandes.'),
  ('Tarifa Premium', 'Desmanchado profundo, vaporizado manual y seguro de prenda.'),
  ('Tarifa Luxury', 'Cuidado de pedrería y entrega en percha premium.')
on conflict (nombre) do update set descripcion = excluded.descripcion;

insert into public.servicios
  (nombre, icono, precio, unidad, descripcion, activo, como_funciona, tiempo_estimado, items_sugeridos, beneficios, opciones_acabado)
values (
  'Tintorería', 'dry_cleaning', 5.00, 'prenda', 'Limpieza en seco para prendas delicadas.', true,
  'Cuidado experto para tus prendas más delicadas. Revisamos cada prenda para identificar manchas y áreas de cuidado especial, aplicamos solventes biodegradables y técnicas de desmanchado artesanal, y terminamos con planchado profesional al vapor y empaque en fundas protectoras transpirables.',
  '24-48 horas',
  '["Trajes","Abrigos","Vestidos Seda","Diseñador"]'::jsonb,
  '[{"icono":"eco","titulo":"Proceso Ecológico","descripcion":"Solventes biodegradables que cuidan tus prendas."},{"icono":"shield","titulo":"Garantía de Calidad","descripcion":"Revisamos cada prenda antes de entregarla."}]'::jsonb,
  jsonb_build_array(
    jsonb_build_object('opcionId', (select id from public.opciones where nombre = 'Tarifa Premium'), 'precioAdicional', 15),
    jsonb_build_object('opcionId', (select id from public.opciones where nombre = 'Tarifa Luxury'), 'precioAdicional', 35)
  )
)
on conflict (nombre) do update set
  icono = excluded.icono, precio = excluded.precio, unidad = excluded.unidad, descripcion = excluded.descripcion,
  como_funciona = excluded.como_funciona, tiempo_estimado = excluded.tiempo_estimado,
  items_sugeridos = excluded.items_sugeridos, beneficios = excluded.beneficios, opciones_acabado = excluded.opciones_acabado;

insert into public.servicios
  (nombre, icono, precio, unidad, descripcion, activo, como_funciona, tiempo_estimado, items_sugeridos, beneficios, opciones_acabado)
values (
  'Planchado', 'iron', 1.00, 'prenda', 'Planchado profesional.', true,
  'Acabado impecable y cuidado profesional para que tus prendas luzcan como nuevas. Utilizamos vaporización avanzada para proteger las fibras.',
  '12-24 horas',
  '[]'::jsonb,
  '[{"icono":"eco","titulo":"Cuidado de Telas","descripcion":"Ajustamos temperatura y vapor según cada prenda."},{"icono":"checkroom","titulo":"Entrega en Gancho","descripcion":"Listas para colgar directo en tu clóset."}]'::jsonb,
  jsonb_build_array(
    jsonb_build_object('opcionId', (select id from public.opciones where nombre = 'Doblado en Gancho'), 'precioAdicional', 0),
    jsonb_build_object('opcionId', (select id from public.opciones where nombre = 'Doblado Estándar'), 'precioAdicional', 0)
  )
)
on conflict (nombre) do update set
  icono = excluded.icono, precio = excluded.precio, unidad = excluded.unidad, descripcion = excluded.descripcion,
  como_funciona = excluded.como_funciona, tiempo_estimado = excluded.tiempo_estimado,
  items_sugeridos = excluded.items_sugeridos, beneficios = excluded.beneficios, opciones_acabado = excluded.opciones_acabado;

insert into public.servicios
  (nombre, icono, precio, unidad, descripcion, activo, como_funciona, tiempo_estimado, items_sugeridos, beneficios, opciones_acabado)
values (
  'Edredones', 'bed', 12.00, 'pieza', 'Limpieza profunda para ropa de cama.', true,
  'Limpieza profunda para piezas de gran volumen. Eliminación de ácaros y secado delicado para mantener la suavidad.',
  '48 horas',
  '[]'::jsonb,
  '[{"icono":"sanitizer","titulo":"Sanitizado Profundo","descripcion":"Elimina ácaros, alérgenos y bacterias del relleno."},{"icono":"inventory","titulo":"Empaque Especial","descripcion":"Empaque protector transpirable para guardarlo."},{"icono":"waves","titulo":"Secado Delicado","descripcion":"Temperatura controlada para mantener la textura."}]'::jsonb,
  '[]'::jsonb
)
on conflict (nombre) do update set
  icono = excluded.icono, precio = excluded.precio, unidad = excluded.unidad, descripcion = excluded.descripcion,
  como_funciona = excluded.como_funciona, tiempo_estimado = excluded.tiempo_estimado,
  items_sugeridos = excluded.items_sugeridos, beneficios = excluded.beneficios, opciones_acabado = excluded.opciones_acabado;

insert into public.promociones (codigo, titulo, descripcion, descuento_porcentaje, servicio_aplicable, fecha_inicio, fecha_fin, activa)
values (
  'FRESH20',
  '20% OFF en Tintorería',
  'Aprovecha nuestra oferta semanal en todas tus prendas delicadas.',
  20,
  'Tintorería',
  now(),
  now() + interval '30 days',
  true
)
on conflict (codigo) do nothing;

-- Ejecuta esta línea DESPUÉS de registrar la cuenta administradora en la app.
-- Sustituye el correo antes de ejecutarla:
-- update auth.users
-- set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"rol":"administrador"}'::jsonb
-- where email = 'administrador@correo.com';
