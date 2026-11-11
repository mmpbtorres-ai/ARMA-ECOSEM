
CREATE TABLE IF NOT EXISTS users (
 id BIGSERIAL PRIMARY KEY, username TEXT UNIQUE NOT NULL, nombre TEXT NOT NULL,
 rol TEXT NOT NULL CHECK(rol IN ('ADMIN','SUPERVISOR','TECNICO','OPERADOR')),
 password_hash TEXT NOT NULL, activo BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS auth_sessions (
 token_hash TEXT PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 expires_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS vehicles (
 id BIGSERIAL PRIMARY KEY, codigo TEXT UNIQUE NOT NULL, placa TEXT, tipo TEXT NOT NULL DEFAULT 'VEHICULO',
 marca TEXT, modelo TEXT, anio INTEGER, serie TEXT, estado TEXT NOT NULL DEFAULT 'OPERATIVO',
 kilometraje NUMERIC(14,2) NOT NULL DEFAULT 0, horometro NUMERIC(14,2) NOT NULL DEFAULT 0,
 ubicacion TEXT, observaciones TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS pm_plans (
 id BIGSERIAL PRIMARY KEY, vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
 nombre TEXT NOT NULL, intervalo_dias INTEGER, intervalo_km NUMERIC(14,2), intervalo_horas NUMERIC(14,2),
 ultimo_servicio DATE, ultimo_km NUMERIC(14,2), ultimo_horometro NUMERIC(14,2),
 activo BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS work_orders (
 id BIGSERIAL PRIMARY KEY, codigo TEXT UNIQUE NOT NULL, vehicle_id BIGINT NOT NULL REFERENCES vehicles(id),
 tipo TEXT NOT NULL CHECK(tipo IN ('PREVENTIVO','CORRECTIVO','INSPECCION')),
 prioridad TEXT NOT NULL DEFAULT 'MEDIA', estado TEXT NOT NULL DEFAULT 'ABIERTA',
 descripcion TEXT NOT NULL, tecnico TEXT, fecha_programada DATE, fecha_inicio TIMESTAMPTZ,
 fecha_cierre TIMESTAMPTZ, kilometraje NUMERIC(14,2), horometro NUMERIC(14,2),
 costo_mano_obra NUMERIC(14,2) NOT NULL DEFAULT 0, costo_repuestos NUMERIC(14,2) NOT NULL DEFAULT 0,
 observaciones TEXT, created_by BIGINT REFERENCES users(id), created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS parts (
 id BIGSERIAL PRIMARY KEY, codigo TEXT UNIQUE NOT NULL, nombre TEXT NOT NULL, unidad TEXT NOT NULL DEFAULT 'UND',
 stock NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK(stock>=0), stock_minimo NUMERIC(14,2) NOT NULL DEFAULT 0,
 costo_unitario NUMERIC(14,2) NOT NULL DEFAULT 0, ubicacion TEXT, activo BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS part_movements (
 id BIGSERIAL PRIMARY KEY, part_id BIGINT NOT NULL REFERENCES parts(id), work_order_id BIGINT REFERENCES work_orders(id),
 tipo TEXT NOT NULL CHECK(tipo IN ('INGRESO','CONSUMO','AJUSTE')), cantidad NUMERIC(14,2) NOT NULL CHECK(cantidad>0),
 costo_unitario NUMERIC(14,2) NOT NULL DEFAULT 0, usuario BIGINT REFERENCES users(id), created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS fuel_logs (
 id BIGSERIAL PRIMARY KEY, vehicle_id BIGINT NOT NULL REFERENCES vehicles(id), fecha DATE NOT NULL,
 litros NUMERIC(14,2) NOT NULL CHECK(litros>0), costo_total NUMERIC(14,2) NOT NULL CHECK(costo_total>=0),
 odometro NUMERIC(14,2), proveedor TEXT, comprobante TEXT, observaciones TEXT,
 created_by BIGINT REFERENCES users(id), created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS tires (
 id BIGSERIAL PRIMARY KEY, vehicle_id BIGINT NOT NULL REFERENCES vehicles(id), posicion TEXT NOT NULL,
 numero_serie TEXT NOT NULL, marca TEXT, medida TEXT, fecha_instalacion DATE, km_instalacion NUMERIC(14,2),
 fecha_retiro DATE, km_retiro NUMERIC(14,2), estado TEXT NOT NULL DEFAULT 'INSTALADO', observaciones TEXT
);
CREATE TABLE IF NOT EXISTS audit_log (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id), accion TEXT NOT NULL,
 entidad TEXT NOT NULL, entidad_id BIGINT, detalle JSONB NOT NULL DEFAULT '{}'::jsonb,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_wo_vehicle_state ON work_orders(vehicle_id,estado);
CREATE INDEX IF NOT EXISTS idx_pm_vehicle ON pm_plans(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_fuel_vehicle_date ON fuel_logs(vehicle_id,fecha DESC);
