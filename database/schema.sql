
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
 observaciones TEXT, created_by BIGINT REFERENCES users(id), pm_plan_id BIGINT REFERENCES pm_plans(id) ON DELETE SET NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE work_orders ADD COLUMN IF NOT EXISTS pm_plan_id BIGINT REFERENCES pm_plans(id) ON DELETE SET NULL;
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


-- Módulos Enterprise: actividades diarias, técnicos y presupuestos
CREATE TABLE IF NOT EXISTS technicians (
 id BIGSERIAL PRIMARY KEY, codigo TEXT UNIQUE NOT NULL, nombre TEXT NOT NULL,
 especialidad TEXT, telefono TEXT, correo TEXT, estado TEXT NOT NULL DEFAULT 'ACTIVO',
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS daily_activities (
 id BIGSERIAL PRIMARY KEY, fecha DATE NOT NULL DEFAULT CURRENT_DATE,
 vehicle_id BIGINT REFERENCES vehicles(id) ON DELETE SET NULL,
 tecnico_id BIGINT REFERENCES technicians(id) ON DELETE SET NULL,
 tipo TEXT NOT NULL DEFAULT 'INSPECCION', descripcion TEXT NOT NULL,
 kilometraje NUMERIC(14,2), horometro NUMERIC(14,2), hallazgos TEXT,
 estado TEXT NOT NULL DEFAULT 'PENDIENTE', work_order_id BIGINT REFERENCES work_orders(id) ON DELETE SET NULL,
 created_by BIGINT REFERENCES users(id), created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS budgets (
 id BIGSERIAL PRIMARY KEY, periodo TEXT NOT NULL UNIQUE,
 monto_presupuestado NUMERIC(14,2) NOT NULL CHECK(monto_presupuestado>=0),
 observaciones TEXT, created_by BIGINT REFERENCES users(id), created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_daily_date ON daily_activities(fecha DESC);
CREATE INDEX IF NOT EXISTS idx_technicians_active ON technicians(estado);


-- SIGMA Fleet Enterprise 1.1: programación operativa y control documental
CREATE TABLE IF NOT EXISTS maintenance_programs (
 id BIGSERIAL PRIMARY KEY,
 vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
 program_type TEXT NOT NULL CHECK(program_type IN ('GENERAL','SEMANAL')),
 periodo_inicio DATE,
 fecha_programada DATE,
 componente TEXT,
 actividad TEXT NOT NULL,
 prioridad TEXT NOT NULL DEFAULT 'MEDIA',
 responsable TEXT,
 duracion_horas NUMERIC(10,2),
 estado TEXT NOT NULL DEFAULT 'PROGRAMADO' CHECK(estado IN ('PROGRAMADO','EN_PROCESO','EJECUTADO','REPROGRAMADO','CANCELADO')),
 observaciones TEXT,
 created_by BIGINT REFERENCES users(id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_maintenance_programs_date ON maintenance_programs(fecha_programada,program_type);
CREATE INDEX IF NOT EXISTS idx_maintenance_programs_vehicle ON maintenance_programs(vehicle_id);

CREATE TABLE IF NOT EXISTS equipment_status_reports (
 id BIGSERIAL PRIMARY KEY,
 vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
 fecha DATE NOT NULL DEFAULT CURRENT_DATE,
 turno TEXT,
 condicion TEXT NOT NULL CHECK(condicion IN ('OPERATIVO','OPERATIVO_CON_RESTRICCIONES','EN_MANTENIMIENTO','FUERA_DE_SERVICIO')),
 ubicacion TEXT,
 kilometraje NUMERIC(14,2),
 horometro NUMERIC(14,2),
 detalle TEXT,
 accion_requerida TEXT,
 reported_by BIGINT REFERENCES users(id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_equipment_status_date ON equipment_status_reports(fecha DESC,vehicle_id);

CREATE TABLE IF NOT EXISTS grease_schedules (
 id BIGSERIAL PRIMARY KEY,
 vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
 componente TEXT NOT NULL,
 lubricante TEXT,
 cantidad NUMERIC(12,3),
 unidad TEXT DEFAULT 'g',
 intervalo_dias INTEGER,
 intervalo_km NUMERIC(14,2),
 intervalo_horas NUMERIC(14,2),
 ultima_fecha DATE,
 ultimo_km NUMERIC(14,2),
 ultimo_horometro NUMERIC(14,2),
 responsable TEXT,
 activo BOOLEAN NOT NULL DEFAULT TRUE,
 observaciones TEXT,
 created_by BIGINT REFERENCES users(id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS grease_executions (
 id BIGSERIAL PRIMARY KEY,
 schedule_id BIGINT REFERENCES grease_schedules(id) ON DELETE SET NULL,
 vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
 fecha DATE NOT NULL DEFAULT CURRENT_DATE,
 componente TEXT NOT NULL,
 lubricante TEXT,
 cantidad NUMERIC(12,3),
 unidad TEXT DEFAULT 'g',
 kilometraje NUMERIC(14,2),
 horometro NUMERIC(14,2),
 tecnico TEXT,
 resultado TEXT NOT NULL DEFAULT 'EJECUTADO' CHECK(resultado IN ('EJECUTADO','PARCIAL','NO_EJECUTADO')),
 observaciones TEXT,
 created_by BIGINT REFERENCES users(id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_grease_executions_date ON grease_executions(fecha DESC);

CREATE TABLE IF NOT EXISTS operational_documents (
 id BIGSERIAL PRIMARY KEY,
 tipo_documento TEXT NOT NULL,
 vehicle_id BIGINT REFERENCES vehicles(id) ON DELETE SET NULL,
 referencia TEXT,
 fecha_emision DATE NOT NULL DEFAULT CURRENT_DATE,
 fecha_vencimiento DATE,
 frecuencia TEXT,
 evento_actualizacion TEXT,
 estado TEXT NOT NULL DEFAULT 'PENDIENTE' CHECK(estado IN ('PENDIENTE','ELABORADO','PRESENTADO','ACTUALIZADO','OBSERVADO')),
 version TEXT,
 responsable TEXT,
 destinatario TEXT,
 archivo_url TEXT,
 observaciones TEXT,
 created_by BIGINT REFERENCES users(id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_operational_documents_date ON operational_documents(fecha_emision DESC,estado);

CREATE TABLE IF NOT EXISTS equipment_events (
 id BIGSERIAL PRIMARY KEY,
 vehicle_id BIGINT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
 tipo_evento TEXT NOT NULL CHECK(tipo_evento IN ('SALIDA_MANTENIMIENTO','RETIRO_OBRA','RELEVO_ENTREGA','RELEVO_RECEPCION','SOLICITUD_COSTOS')),
 fecha_evento TIMESTAMPTZ NOT NULL DEFAULT now(),
 origen TEXT,
 destino TEXT,
 condicion_equipo TEXT,
 kilometraje NUMERIC(14,2),
 horometro NUMERIC(14,2),
 entregado_por TEXT,
 recibido_por TEXT,
 motivo TEXT,
 referencia_documento TEXT,
 observaciones TEXT,
 created_by BIGINT REFERENCES users(id),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_equipment_events_date ON equipment_events(fecha_evento DESC);
