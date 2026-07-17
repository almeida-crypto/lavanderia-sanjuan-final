create extension if not exists pgcrypto;

create table if not exists public.direcciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id text not null,
  titulo text not null,
  lineas jsonb not null default '[]'::jsonb,
  telefono text,
  nota text,
  predeterminada boolean not null default false,
  created_at timestamptz not null default now()
);

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
  created_at timestamptz not null default now()
);

create table if not exists public.pedidos (
  id uuid primary key default gen_random_uuid(),
  cliente_id text not null,
  cliente_nombre text not null default 'Cliente',
  cliente_email text,
  cliente_telefono text,
  servicio text not null,
  fecha text not null,
  franja_horaria text not null default 'Tarde',
  direccion text not null default 'Sin dirección',
  instrucciones text not null default '',
  eco_friendly boolean not null default false,
  fragancia text,
  cantidad_aproximada integer,
  metodo_pago text,
  repartidor text,
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
  created_at timestamptz not null default now()
);

create unique index if not exists una_direccion_principal_por_usuario
  on public.direcciones(usuario_id) where predeterminada;
create unique index if not exists una_tarjeta_principal_por_usuario
  on public.metodos_pago(usuario_id) where principal;
create index if not exists pedidos_por_cliente on public.pedidos(cliente_id);
create index if not exists pedidos_recientes on public.pedidos(created_at desc);

alter table public.direcciones enable row level security;
alter table public.metodos_pago enable row level security;
alter table public.servicios enable row level security;
alter table public.pedidos enable row level security;

insert into public.servicios (nombre, icono, precio, unidad, descripcion, activo)
values
  ('Lavado y Doblado', 'local_laundry_service', 1.50, 'kg', 'Lavado, secado y doblado profesional.', true),
  ('Tintorería', 'dry_cleaning', 5.00, 'prenda', 'Limpieza en seco para prendas delicadas.', true),
  ('Planchado', 'iron', 1.00, 'prenda', 'Planchado profesional.', true),
  ('Edredones', 'bed', 12.00, 'pieza', 'Limpieza profunda para ropa de cama.', true)
on conflict (nombre) do update set
  icono = excluded.icono,
  precio = excluded.precio,
  unidad = excluded.unidad,
  descripcion = excluded.descripcion;

-- Ejecuta esta línea DESPUÉS de registrar la cuenta administradora en la app.
-- Sustituye el correo antes de ejecutarla:
-- update auth.users
-- set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"rol":"administrador"}'::jsonb
-- where email = 'administrador@correo.com';
