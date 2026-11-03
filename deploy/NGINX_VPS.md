# Despliegue en VPS con Nginx compartido

El VPS usa un solo contenedor de Nginx, `nginx-recepcionista`, para las aplicaciones. CampusFlow aporta dos contenedores: `campusflow-frontend` y `campusflow-backend`. Los tres se conectan a la red Docker externa `red-saas`; solo el proxy publica los puertos 80 y 443.

El Compose de CampusFlow esta en `deploy/compose.vps.yaml`. No inicia ni reconstruye el proxy. Antes de levantar CampusFlow, la red debe existir:

```bash
docker network inspect red-saas
```

El servicio Nginx compartido debe tener `red-saas` en su seccion `networks` y su configuracion debe enviar:

- `/` a `http://campusflow-frontend:80`
- `/api/` y `/uploads/` a `http://campusflow-backend:8000`

La configuracion de referencia esta en `deploy/nginx-campusflow.conf`. Al integrarla con la configuracion existente, conserva los bloques de los otros dominios y los certificados que ya estan instalados. Verifica y recarga el proxy sin recrearlo:

```bash
docker exec nginx-recepcionista nginx -t
docker exec nginx-recepcionista nginx -s reload
```

## Dominios y HTTPS

Los dos dominios DuckDNS deben apuntar a la IP publica del VPS:

- CampusFlow: `campusuphflow.duckdns.org`
- TiendaMGR: `tiendamgr.duckdns.org`

Emite un certificado SAN que cubra ambos dominios con Certbot y webroot:

```bash
mkdir -p /srv/certbot-www
docker run --rm \
  -v /srv/certbot-www:/var/www/certbot \
  -v /etc/letsencrypt:/etc/letsencrypt \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  --register-unsafely-without-email --agree-tos --no-eff-email \
  -d campusuphflow.duckdns.org -d tiendamgr.duckdns.org
```

El Nginx usa ese certificado para ambos sitios y redirige HTTP a HTTPS, excepto la ruta de validacion ACME.

## Configurar CampusFlow

Configura la API para el dominio final en `/srv/proyectos/CampusFlow/.env`:

```dotenv
APP_ENV=production
COOKIE_SECURE=true
FRONTEND_ORIGINS=https://campusuphflow.duckdns.org
```

El despliegue de CampusFlow levanta o reemplaza solo sus dos servicios:

```bash
docker compose -f /srv/proyectos/CampusFlow/deploy/compose.vps.yaml up -d api frontend
```

## Renovacion automatica

Copia `renovar-certificados.sh` a `/usr/local/sbin/renovar-campusflow-certificados` y dale permiso de ejecucion. Agrega esta tarea a `/etc/cron.d/campusflow-certificados`:

```cron
17 3,15 * * * root /usr/local/sbin/renovar-campusflow-certificados >> /var/log/campusflow-certificados.log 2>&1
```

El script renueva cuando corresponde y recarga Nginx para que use los certificados actualizados.

## Paddle Sandbox

Registra esta URL como destino de notificaciones en Paddle Sandbox:

```text
https://campusuphflow.duckdns.org/api/payments/paddle/webhook
```

Copia el secreto que Paddle entrega a `PADDLE_WEBHOOK_SECRET` en el `.env` del VPS y recrea la API. El alta de una universidad se activa solo cuando llega el webhook firmado que confirma el pago inicial.
