# Etapa 1: usamos Node para instalar dependencias y compilar React.
FROM node:22-alpine AS compilacion

# Carpeta de trabajo dentro de esta etapa de construccion.
WORKDIR /app

# Copiamos los archivos de npm para instalar las versiones del lockfile.
COPY package.json package-lock.json ./
RUN npm ci

# Copiamos el codigo del frontend.
COPY . .

# Direccion de la API y universidad predeterminada que se incorporan al frontend.
ARG VITE_API_URL=/api
ARG VITE_INSTITUTION_SLUG=uphn
ENV VITE_API_URL=${VITE_API_URL}
ENV VITE_INSTITUTION_SLUG=${VITE_INSTITUTION_SLUG}

# Generamos los archivos estaticos de produccion en /app/dist.
RUN npm run build

# Etapa 2: un servidor estatico sencillo entrega React; el proxy vive fuera de esta app.
FROM node:22-alpine
WORKDIR /app
RUN npm install --global serve
COPY --from=compilacion /app/dist ./dist

# Puerto interno del servidor de archivos del frontend.
EXPOSE 80

CMD ["serve", "--single", "--listen", "tcp://0.0.0.0:80", "dist"]
