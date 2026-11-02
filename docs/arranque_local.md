# Arranque local de CampusFlow

Requisitos: Python 3.14, Node.js 22, npm y una base PostgreSQL accesible.

## Con Docker Compose

El `compose.yaml` de la raiz levanta dos servicios: `api` construida con el `Dockerfile` de la raiz, y `frontend` construida con `frontend/Dockerfile`. El contenedor del frontend compila React y entrega los archivos estaticos con un servidor sencillo; no agrega otro Nginx. Ambos servicios se conectan a `red-saas`. En el VPS, el Nginx compartido tambien se conecta a esa red y recibe el trafico publico.

1. Configura el archivo `.env` de la raiz con `DATABASE_URL` y `SECRET_KEY` validos. Compose usa esos valores para el backend.
2. Construye y arranca los dos servicios desde la raiz:

   ```bash
   docker compose up --build -d
   ```

3. Abre `http://localhost:8080`. Para comprobar la API, abre `http://localhost:8000/docs` o ejecuta `curl -i http://localhost:8000/health`.
4. Consulta estado y logs con `docker compose ps` y `docker compose logs -f`.
5. Deten los servicios con `docker compose down`. Los archivos subidos permanecen en el volumen `uploads`.

El servicio API publica `127.0.0.1:8000` para que el navegador pueda consultarla directamente. El frontend esta en `127.0.0.1:8080`; esta configuracion es solo para desarrollo local. En el VPS, el Nginx compartido dirige `/` al frontend y `/api/` y `/uploads/` a la API.

## Arranque sin Docker

1. Crea el entorno: `python3 -m venv venv`.
2. Instala Python: `venv/bin/python -m pip install -r requirements-dev.txt`.
3. Instala el frontend: `cd frontend && npm ci`.
4. Crea `.env` desde `.env.example`. Pon tu URL real de PostgreSQL en `DATABASE_URL` y genera `SECRET_KEY` con `python3 -c 'import secrets; print(secrets.token_urlsafe(48))'`.
5. Comprueba migraciones: `venv/bin/alembic current`. Si esta detras del head, ejecuta `venv/bin/alembic upgrade head` despues de respaldar la base.
6. Desde la raiz ejecuta `npm run dev`. Abre `http://localhost:5173`; el backend escucha en `http://127.0.0.1:8000`.

`npm run dev` inicia ambos servicios y los detiene al pulsar Ctrl+C. Para usarlos en dos terminales, ejecuta `npm run dev:backend` y `npm run dev:frontend` por separado desde la raiz.

El arranque academico usa PostgreSQL. El registro de universidades con pago requiere ademas las variables de Paddle Sandbox y un webhook publico firmado. Consulta `deploy/PADDLE_SANDBOX.md` antes del despliegue.
