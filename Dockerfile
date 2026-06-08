# syntax=docker/dockerfile:1
# ^ Rozszerzony frontend BuildKit (lab 6). MUSI byc pierwsza linia pliku.

# =============================================================================
#  PAwChO Lab 5/6 - aplikacja webowa na Nginx, budowana metoda wieloetapowa.
# =============================================================================

# ---- Etap 1 (stage 1): builder ---------------------------------------------
# Obraz bazowy alpine (dopuszczony przez instrukcje obok scratch).
# "Buduje" aplikacje: wstrzykuje wersje (z ARG VERSION) do szablonu strony.
FROM alpine:3.20 AS builder

ARG VERSION=dev
WORKDIR /build

COPY web/ ./web/

RUN sed -i "s/__VERSION__/${VERSION}/g" web/index.html.template \
    && chmod +x web/40-generate-index.sh

# ---- Etap 2 (stage 2): serwer HTTP -----------------------------------------
# Obraz bazowy Nginx serwuje aplikacje jako strone domyslna (startowa).
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="pawcho6" \
      org.opencontainers.image.description="Aplikacja webowa (IP, hostname, wersja) na Nginx - PAwChO Lab 5/6" \
      org.opencontainers.image.authors="Cezary Prusak" \
      org.opencontainers.image.source="https://github.com/TadekBudowlaniec/pawcho6"

# Szablon strony + generator (IP/hostname uzupelniane przy starcie kontenera).
COPY --from=builder /build/web/index.html.template /usr/share/nginx/template/index.html.template
COPY --from=builder /build/web/40-generate-index.sh /docker-entrypoint.d/40-generate-index.sh

EXPOSE 80

# Automatyczna kontrola poprawnosci dzialania aplikacji.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1

# nginx:alpine ma domyslny ENTRYPOINT, ktory uruchamia skrypty z
# /docker-entrypoint.d/ a nastepnie startuje serwer w trybie foreground.
