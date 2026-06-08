#!/bin/sh
# Uruchamiany automatycznie przez entrypoint obrazu nginx (/docker-entrypoint.d/).
# Wypełnia szablon strony danymi runtime: adresem IP i hostname kontenera.
# Wersja (__VERSION__) jest już wstrzyknieta na etapie budowy (ARG VERSION).
set -e

TEMPLATE=/usr/share/nginx/template/index.html.template
OUT=/usr/share/nginx/html/index.html

IP=$(hostname -i 2>/dev/null | awk '{print $1}')
HOST=$(hostname)

sed -e "s/__IP__/${IP}/g" \
    -e "s/__HOSTNAME__/${HOST}/g" \
    "$TEMPLATE" > "$OUT"

echo "[40-generate-index] strona startowa wygenerowana (ip=${IP}, host=${HOST})"
