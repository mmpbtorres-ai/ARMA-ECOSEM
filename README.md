# SIGMA Fleet Cloud

Sistema web de gestión de mantenimiento de flota con Flask y PostgreSQL, preparado para GitHub + Railway.

## Funciones incluidas
- Login con contraseñas hasheadas y sesiones seguras.
- Roles `admin` y `tecnico`; administración de usuarios solo para admin.
- Flota, PM por km/horómetro/fecha, órdenes de trabajo, inventario y KPI.
- Alertas automáticas de PM vencido/próximo y stock mínimo al consultar panel.
- API de salud `/api/health` y panel de datos `/api/dashboard` (requiere login).
- PostgreSQL en Railway; SQLite como modo local de prueba.

## Despliegue en Railway
1. Sube todo el contenido de esta carpeta a un repositorio GitHub.
2. En Railway crea un proyecto: **New Project > Deploy from GitHub Repo** y selecciona el repositorio.
3. Añade un servicio PostgreSQL al mismo proyecto.
4. En Variables del servicio web configura:
   - `SECRET_KEY`: cadena aleatoria larga y privada.
   - `ADMIN_USERNAME`: nombre de usuario administrador.
   - `ADMIN_PASSWORD`: contraseña inicial fuerte (mínimo 10 caracteres).
   - `ADMIN_FULL_NAME`: nombre visible.
   - `COOKIE_SECURE`: `true`.
   - `DATABASE_URL`: referencia a la variable `DATABASE_URL` del servicio PostgreSQL de Railway (usar el selector de variables / reference).
5. Railway detecta `requirements.txt` y `Procfile`; el comando de inicio está también en `railway.json`.
6. Genera un dominio público en Settings > Networking > Generate Domain.

## Primer acceso
Configura `ADMIN_USERNAME=admin` y establece `ADMIN_PASSWORD` con una contraseña privada robusta de al menos 12 caracteres (por ejemplo, genera una nueva y única para tu empresa). Usa exactamente esos valores en el primer acceso. El administrador inicial se crea automáticamente al iniciar la aplicación si no existe. Cambia la contraseña desde Variables de Railway y recrea el usuario solo en una base nueva; el valor de entorno no restablece una cuenta ya creada.

## Ejecución local
```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
set ADMIN_USERNAME=admin
set ADMIN_PASSWORD=UnaClaveLarga-2026!
python app.py
```
Abre http://localhost:5000

## Notas importantes
- Los datos están en PostgreSQL cuando `DATABASE_URL` apunta al servicio PostgreSQL de Railway.
- La aplicación inicializa las tablas con `create_all`; para cambios de esquema en producción, incorporar migraciones Alembic antes de evolucionar modelos.
- No hay integración GPS/ECU real incluida: se requiere proveedor, hardware, credenciales y definición de protocolo. La API queda como punto de integración.
- Los KPI actuales son indicadores operativos iniciales. MTBF/MTTR y cumplimiento PM requieren registrar eventos de falla, duración de reparación y planes ejecutados con más detalle; no deben interpretarse como métricas auditadas.
- Configura copias de seguridad de PostgreSQL desde Railway y conserva exportaciones periódicas.
