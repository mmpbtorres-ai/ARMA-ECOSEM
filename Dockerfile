# Imagen oficial de Node.js: incluye Node y npm dentro del contenedor.
FROM node:20-bookworm-slim

ENV NODE_ENV=production
WORKDIR /app

# Instala las dependencias de producción dentro de la imagen.
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund

# Copia la aplicación y los archivos SQL necesarios para inicializar PostgreSQL.
COPY . ./

EXPOSE 3000
CMD ["npm", "start"]
