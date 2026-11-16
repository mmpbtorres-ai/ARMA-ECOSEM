# Checklist de publicación

- [ ] Subir el contenido de esta carpeta a GitHub (package.json en raíz).
- [ ] Crear servicio PostgreSQL en el mismo proyecto Railway.
- [ ] Configurar `DATABASE_URL=${{Postgres.DATABASE_URL}}` (ajustar el nombre del servicio).
- [ ] Configurar `ADMIN_USERNAME`, `ADMIN_PASSWORD`, `NODE_ENV=production`.
- [ ] Desplegar y generar dominio público.
- [ ] Verificar `https://TU-DOMINIO/api/health` y luego iniciar sesión.
- [ ] Confirmar backups de PostgreSQL.

No configures `PORT` manualmente. Railway lo asigna y el servidor ya escucha en `0.0.0.0`.


Nota: el proyecto solicita Railpack y usa `npm start` con health check en `/api/health`. Railway puede inyectar `PORT`; no lo configures manualmente. Conserva el servicio PostgreSQL y su volumen actuales al actualizar una instalación existente.


## Configuración de Railway a partir del 01/12/2026

Railway dejará de leer `railway.json` / `railway.toml` a partir del 01/12/2026, incluso en servicios existentes. Antes de esa fecha, confirma en el panel de la aplicación: Builder `RAILPACK`, Start Command `npm start`, Healthcheck Path `/api/health` y timeout `300` segundos. No importes ni apliques una definición completa de infraestructura sin revisar primero tu proyecto actual con el CLI; conserva el servicio y la base PostgreSQL existentes.
