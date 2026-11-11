# SIGMA Fleet 2.0 — Adaptación de arquitectura SILOG

Sistema web para mantenimiento de vehículos y maquinaria pesada. Se tomó como referencia la estructura Node.js + Express + PostgreSQL, autenticación por sesión, roles, interfaz estática y despliegue Railway del proyecto SILOG. Se retiraron los módulos logísticos/mineros ajenos a mantenimiento.

## Módulos incluidos
- Dashboard: disponibilidad, PM vencidos/próximos, OT abiertas, costos y MTTR/MTBF básicos.
- Flota: vehículos/maquinaria, placa/código, marca/modelo, tipo, horómetro y kilometraje.
- Plan PM: intervalos por días, kilómetros u horas y siguiente vencimiento.
- Órdenes de trabajo: correctivas/preventivas, prioridad, técnico, fechas, estado, costo y observaciones.
- Repuestos: stock, stock mínimo, movimientos y consumo por OT.
- Combustible: carga, litros, costo, odómetro y proveedor.
- Neumáticos: posición, serie, instalación, retiro y kilometraje.
- Usuarios y auditoría.

## Ejecutar localmente
1. Instalar Node.js 20 o superior y PostgreSQL.
2. Copiar `.env.example` a `.env` y configurar `DATABASE_URL`, `SESSION_SECRET`, `ADMIN_USERNAME` y `ADMIN_PASSWORD`.
3. `npm install`
4. `npm start`
5. Abrir `http://localhost:3000`

El esquema se crea automáticamente al iniciar. La cuenta inicial se crea solo si no existe. Configure una contraseña privada antes de publicar.

## Railway + GitHub
1. Suba el contenido de esta carpeta a un repositorio GitHub.
2. En Railway cree un proyecto desde ese repositorio.
3. Añada PostgreSQL al proyecto.
4. En variables del servicio configure `DATABASE_URL` (referencia de PostgreSQL), `SESSION_SECRET` (secreto largo aleatorio), `ADMIN_USERNAME` y `ADMIN_PASSWORD` (contraseña privada).
5. Railway detectará Node y ejecutará `npm start`.

## Seguridad y alcance
- Contraseñas con scrypt y sesiones almacenadas en PostgreSQL; cookie HttpOnly/SameSite.
- Roles ADMIN, SUPERVISOR, TECNICO y OPERADOR.
- Las rutas de escritura requieren sesión y validan datos.
- No incluye telemetría GPS, conexión ECU/CAN, sensores IoT ni integración con proveedores externos. Para eso se requieren dispositivos, protocolo, API y credenciales reales.
- Los indicadores son operativos y dependen de que los datos se registren correctamente. MTBF/MTTR son aproximaciones calculadas con órdenes cerradas y fallas registradas.
