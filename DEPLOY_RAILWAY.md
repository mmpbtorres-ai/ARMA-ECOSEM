# Corrección de despliegue SIGMA Fleet V1.1.1 — Railway

Esta versión corrige el error de arranque `npm: command not found` incorporando un `Dockerfile` basado en `node:20-bookworm-slim`. La imagen oficial contiene Node.js y npm; las dependencias se instalan dentro del contenedor durante la construcción.

## IMPORTANTE: estructura del repositorio

Carga **el contenido de esta carpeta en la raíz del repositorio GitHub**, no la carpeta contenedora completa. Al abrir la página principal del repositorio, deben verse directamente estos elementos:

- `Dockerfile`
- `package.json`
- `railway.json`
- `server/`
- `public/`
- `database/`

Si prefieres conservar el proyecto dentro de una subcarpeta, configura Railway → Settings → Build → Root Directory con la ruta exacta de esa subcarpeta. El `Dockerfile` y el `package.json` deben quedar dentro de ese Root Directory.

## Configuración del servicio en Railway

1. Abre el servicio de la aplicación (no el servicio PostgreSQL).
2. En Settings → Build, selecciona el builder Dockerfile o deja que Railway detecte el archivo `Dockerfile` de la raíz.
3. Dockerfile Path: `Dockerfile`.
4. Root Directory: vacío/`/` si cargaste los archivos directamente en la raíz; si no, usa la ruta de la subcarpeta del proyecto.
5. Build Command: dejar vacío.
6. Start Command: dejar vacío para usar `CMD ["npm", "start"]` del Dockerfile. También funcionará `npm start` porque la imagen ya incluye npm.
7. En Variables, conserva `DATABASE_URL` apuntando al PostgreSQL que ya utilizas. Conserva también `ADMIN_USERNAME`, `ADMIN_PASSWORD` y `NODE_ENV=production`.
8. No fijes manualmente `PORT`; Railway lo inyecta.
9. Haz Commit/Push en GitHub y revisa los nuevos logs de construcción.

## Qué debes ver en los logs

Durante la construcción, Railway debe indicar que detectó/usó el Dockerfile y ejecutar los pasos `RUN npm install ...` sin errores.

Durante el arranque, el servidor debe registrar `SIGMA Fleet escuchando en <puerto>`.

Luego verifica `https://TU-DOMINIO/api/health`. Una respuesta `{"ok":true,...}` confirma que la aplicación y PostgreSQL responden.

## Conservación de la base de datos

- No elimines el servicio PostgreSQL existente.
- No cambies `DATABASE_URL` por una base nueva.
- No borres ni recrees volúmenes.
- Realiza un respaldo antes del despliegue.
- La aplicación ejecuta su inicialización SQL al arrancar. No se requiere eliminar datos existentes.

## Diagnóstico de `npm: command not found`

El error ocurre antes de que Node pueda iniciar: el contenedor o directorio de construcción/ejecución seleccionado no contiene npm. Las causas frecuentes son que Railway no está construyendo desde la carpeta donde está `package.json`, o que el servicio está usando un builder/imagen que no es Node. Este paquete fuerza una imagen oficial de Node mediante Dockerfile y deja los archivos de la aplicación en la raíz del paquete ZIP para evitar el error por carpeta anidada.
