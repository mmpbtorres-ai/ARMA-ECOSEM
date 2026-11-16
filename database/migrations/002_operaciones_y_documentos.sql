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
