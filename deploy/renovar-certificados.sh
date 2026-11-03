#!/bin/sh
set -eu

docker run --rm \
  -v /srv/certbot-www:/var/www/certbot \
  -v /etc/letsencrypt:/etc/letsencrypt \
  certbot/certbot renew --webroot -w /var/www/certbot --quiet

docker exec nginx-recepcionista nginx -s reload
