# SIGMA FLEET ENTERPRISE V1.1 — GitHub + Railway

Sistema web de administración de flota, mantenimiento y control operativo. Esta versión conserva la arquitectura de tu V1: **Node.js + Express + PostgreSQL**. Está preparada para desplegarse desde un repositorio GitHub hacia Railway.

## Módulos incluidos

- Dashboard ejecutivo, disponibilidad, OT abiertas, PM vencidos, repuestos críticos, costos y MTTR.
- Flota: vehículos y maquinaria, condición, kilometraje y horómetro.
- Plan PM por días, kilometraje y horómetro, con generación de OT preventiva.
- Actividades diarias y órdenes de trabajo preventivas, correctivas e inspecciones.
- Programa general de mantenimiento por equipo y programa semanal proyectado (editable).
- Reporte de estatus y actualización de condición operativa diaria por turno/guardia (editable).
- Cronograma de engrase por componente y frecuencia, con vencimiento calculado por días, kilometraje u horómetro; reporte de engrase ejecutado con lectura de KM/horómetro.
- Control documental: presentación inicial, actualizaciones, programas, reportes, cronograma de engrase, informes de salida, hoja de relevo e información solicitada por Costos. Registra frecuencia, evento de actualización, estado, versión, responsable y enlace al archivo.
- Eventos de salida de mantenimiento, retiro de equipos de obra, entrega/recepción y solicitudes de Costos.
- Repuestos, movimientos, combustible, neumáticos, técnicos, costos, presupuestos, reportes y auditoría.
- Usuarios y roles; autenticación por sesión almacenada en PostgreSQL.

## Matriz de entregables y actualización

El módulo de control documental trae estos criterios de referencia; puedes modificar frecuencia, evento, versión, responsable, destinatario y enlace en cada registro:

| Entregable | Frecuencia / condición de actualización |
|---|---|
| Presentación inicial | Inicial y actualización cuando corresponda. |
| Programa general de mantenimiento por equipo | Al registrar el equipo y cuando cambie el programa. |
| Programa semanal de mantenimiento proyectado | Semanal. |
| Reporte de estatus de equipos | Semanal; actualizar ante cambio de fin de guardia. |
| Actualización de condición operativa | Diaria y ante cambio de guardia. |
| Cronograma de engrase | Según el programa de lubricación definido para cada equipo y componente; la frecuencia se ingresa en el sistema. |
| Reporte de engrase ejecutado | Después de cada actividad. |
| Informe de salida de mantenimiento | Cada vez que culmine un mantenimiento. |
| Informe de salida de equipos de obra | Cada vez que un equipo sea retirado. |
| Hoja de relevo de equipos | En cada entrega y recepción. |
| Información solicitada por Costos | Cada vez que sea requerida. |

El sistema genera automáticamente registros documentales al actualizar la condición diaria, registrar engrases ejecutados, cerrar una OT y registrar salidas/retiros/relevos/solicitudes de Costos. El texto “semanal; actualizar ante cambio de fin de guardia” es un criterio configurable para reflejar la instrucción recibida; ajústalo si el área establece otra regla.

## Despliegue desde GitHub a Railway

### 1. Subir el proyecto a GitHub
1. Descomprime este ZIP.
2. Crea un repositorio en GitHub y carga **el contenido de la carpeta** (package.json debe quedar en la raíz del repositorio).
3. Confirma que `.env` no se suba; `.gitignore` ya excluye ese archivo.

### 2. Crear los servicios en Railway
1. Crea un proyecto en Railway y selecciona **Deploy from GitHub Repo**.
2. Autoriza GitHub y selecciona el repositorio SIGMA Fleet. Railway detectará Node.js mediante `package.json`; `railway.json` conserva el comando de inicio y el health check del servicio.
3. Dentro del mismo proyecto crea un servicio **PostgreSQL**.
4. En el servicio de la aplicación, agrega la variable `DATABASE_URL` con la referencia: `${{Postgres.DATABASE_URL}}` (usa el nombre real del servicio PostgreSQL si no se llama `Postgres`).
5. Agrega las variables `ADMIN_USERNAME` y `ADMIN_PASSWORD`. Usa una contraseña robusta. Configura también `NODE_ENV=production`.
6. Ejecuta el despliegue y genera un dominio público en **Settings → Networking → Generate Domain**.

### 3. Variables obligatorias

| Variable | Valor / uso |
|---|---|
| `DATABASE_URL` | Referencia al `DATABASE_URL` del servicio PostgreSQL de Railway. |
| `ADMIN_USERNAME` | Usuario administrador inicial, por ejemplo `admin`. |
| `ADMIN_PASSWORD` | Contraseña inicial segura de al menos 10 caracteres. |
| `NODE_ENV` | `production`. |
| `PORT` | Railway lo inyecta; no fijar valor manual. |

Al primer arranque, SIGMA ejecuta `database/schema.sql` y crea las tablas que falten. El usuario administrador inicial se crea solo si todavía no existe y `ADMIN_PASSWORD` está configurada. No hay una contraseña predeterminada incluida.

## Actualizaciones posteriores

Cada cambio que subas a la rama conectada de GitHub activa un nuevo despliegue en Railway (si la implementación automática está habilitada). La base PostgreSQL conserva los datos entre despliegues. No reemplaces el servicio PostgreSQL ni borres su volumen. Para actualizar, modifica el código y sube los cambios a GitHub; no reinicialices la base.

## Copias de seguridad

Configura backups del servicio PostgreSQL desde Railway y conserva exportaciones fuera del proyecto. Un despliegue nuevo no sustituye una copia de seguridad. Antes de cambios importantes, crea un respaldo de la base.

## Prueba local opcional

Requiere Node.js 20+ y PostgreSQL. Copia `.env.example` a `.env`, completa `DATABASE_URL`, `ADMIN_USERNAME` y `ADMIN_PASSWORD`, y luego ejecuta:

```bash
npm install
npm run verify
npm start
```

Abre `http://localhost:3000`.

## Alcance y límites a tener presentes

- Los registros operativos, usuarios, sesiones e historial se guardan en PostgreSQL compartido. Los usuarios que ingresen al mismo dominio de Railway consultan la misma base.
- El campo “Enlace al archivo” conserva una URL a un repositorio documental externo; este ZIP no almacena archivos PDF/Excel binarios ni incorpora almacenamiento de objetos.
- Los reportes tabulares se exportan a CSV compatible con Excel y los reportes imprimibles se pueden guardar como PDF desde el navegador.
- No incluye GPS, telemetría CAN/ECU, sensores, integración contable ni modo offline.
- La frecuencia y el evento de actualización de cada documento se dejan editables, porque el texto recibido no define una frecuencia inequívoca para todos los entregables.

## Verificación

```bash
npm run verify
```

La configuración incluida solicita Railpack, ejecuta `npm start` y verifica el endpoint `/api/health`. Railway inyecta `PORT`; no lo fijes manualmente.

**Importante para tu despliegue (fecha de referencia: 16/11/2026):** Railway mantiene `railway.json` para servicios existentes solo hasta el **01/12/2026**; después dejará de leerlo. En el despliegue actual el archivo solicita Railpack, `npm start` y `/api/health`. Antes del 01/12/2026, deja también estos valores configurados en el panel de tu servicio Railway: Builder `RAILPACK`, Start Command `npm start`, Healthcheck Path `/api/health` y timeout `300` segundos. No agregué `.railway/railway.ts` porque en un proyecto existente primero se debe importar y revisar la configuración real de recursos con el CLI de Railway; no conviene aplicar una definición inventada que pudiera modificar servicios o base de datos.
