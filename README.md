# PAwChO — Laboratorium 5 i 6 (pawcho6)

Aplikacja webowa serwowana przez **Nginx**, budowana metodą **wieloetapową**
(multi-stage). Repozytorium zawiera rozwiązanie zadania obowiązkowego z lab. 5
oraz zadania nieobowiązkowego z lab. 6 (BuildKit frontend, kontekst SSH,
publikacja obrazu na `ghcr.io`).

- **Etap 1 (builder, `alpine`)** — „buduje" aplikację: wstrzykuje wersję
  (`ARG VERSION`) do szablonu strony.
- **Etap 2 (`nginx`)** — serwuje stronę jako domyślną (startową); przy starcie
  kontenera uzupełnia **adres IP** i **hostname**; ma **HEALTHCHECK**.

Strona wyświetla: adres IP serwera, nazwę serwera (hostname) i wersję aplikacji.

---

## Lab 5 — zadanie obowiązkowe

### Treść Dockerfile
Patrz [`Dockerfile`](./Dockerfile). Kluczowe elementy:
- multi-stage: `FROM alpine AS builder` → `FROM nginx:1.27-alpine`,
- `ARG VERSION` przekazywany w `docker build --build-arg VERSION=...`,
- strona ustawiona jako domyślna (`/usr/share/nginx/html/index.html`),
- `HEALTHCHECK` (`wget` do `http://127.0.0.1/`).

### Budowa obrazu i wynik
```bash
docker build --build-arg VERSION=1.0.0 -t pawcho6:1.0.0 .
# ... [builder 4/4] RUN sed -i "s/__VERSION__/1.0.0/g" ...
# ... naming to docker.io/library/pawcho6:1.0.0  DONE
```

### Uruchomienie serwera
```bash
docker run -d -p 8080:80 --name testweb pawcho6:1.0.0
```

### Potwierdzenie działania kontenera i aplikacji
```bash
docker ps --filter name=testweb
# NAMES     STATUS                    PORTS
# testweb   Up 19 seconds (healthy)   0.0.0.0:8080->80/tcp

curl http://localhost:8080/
```
Wynik (fragment) — aplikacja realizuje wymaganą funkcjonalność:

| Pole | Wartość |
|------|---------|
| Adres IP serwera | `172.17.0.2` |
| Nazwa serwera (hostname) | `0623aeeb7564` |
| Wersja aplikacji | `1.0.0` |

Status `healthy` potwierdza poprawne działanie `HEALTHCHECK`.

---

## Lab 6 — zadanie nieobowiązkowe

### a) Rozszerzony frontend BuildKit
Pierwsza linia obu Dockerfile to dyrektywa frontendu:
```dockerfile
# syntax=docker/dockerfile:1
```

### b) Pobranie repo `pawcho6` przez SSH wewnątrz builda
Patrz [`Dockerfile.ssh`](./Dockerfile.ssh) — etap `source` klonuje repozytorium
przez SSH **wewnątrz** procesu budowania, bez `--build-arg`:
```dockerfile
RUN --mount=type=ssh \
    git clone git@github.com:TadekBudowlaniec/pawcho6.git /src
```
Budowa z forwardingiem agenta SSH i tagiem `lab6`:
```bash
docker build --ssh default -f Dockerfile.ssh \
    --build-arg VERSION=lab6 \
    -t ghcr.io/tadekbudowlaniec/pawcho6:lab6 .
```

### c) Publikacja na ghcr.io
```bash
echo $CR_PAT | docker login ghcr.io -u tadekbudowlaniec --password-stdin
docker push ghcr.io/tadekbudowlaniec/pawcho6:lab6
```
Następnie: widoczność pakietu zmieniona z **private** na **public**, a pakiet
powiązany z tym repozytorium git przez etykietę
`org.opencontainers.image.source` (ustawioną w Dockerfile).

> Pełna procedura krok po kroku (logowanie `gh`, klucz SSH, PAT, push, public):
> patrz [`RUNBOOK.md`](./RUNBOOK.md).
