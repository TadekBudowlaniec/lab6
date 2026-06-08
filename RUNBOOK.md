# RUNBOOK — kroki do wykonania samodzielnie (wymagają Twojego konta GitHub)

To, co dało się zrobić automatycznie, jest już gotowe:
- pliki aplikacji + `Dockerfile` (lab 5) i `Dockerfile.ssh` (lab 6),
- obraz lab 5 zbudowany i przetestowany lokalnie (`healthy`),
- `gh` (GitHub CLI) zainstalowane,
- wygenerowany dedykowany klucz SSH `~/.ssh/gh_pawcho_ed25519`,
- repo git zainicjalizowane z pierwszym commitem.

Poniższe kroki wymagają zalogowanego konta GitHub — wykonaj je sam.
Login GitHub: **TadekBudowlaniec**. Polecenia w **PowerShell**.

---

## 1. Dodanie klucza publicznego SSH do konta GitHub

```powershell
# uruchom agenta SSH (jednorazowo; może poprosić o uprawnienia administratora)
Start-Service ssh-agent
ssh-add $HOME\.ssh\gh_pawcho_ed25519
```

Klucz publiczny do wklejenia (Settings → SSH and GPG keys → New SSH key):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGv64xvHm0Z5WM8FNijPM38kfp3dFqtfLe1+u385gkp ghostek.kontakt@gmail.com
```
Albo od razu przez `gh` (po kroku 2):
```powershell
gh ssh-key add $HOME\.ssh\gh_pawcho_ed25519.pub --title "pawcho6 ed25519"
```

Test połączenia:
```powershell
ssh -T git@github.com    # oczekiwane: "Hi TadekBudowlaniec! You've successfully authenticated..."
```

---

## 2. Logowanie do GitHub przez gh CLI

Tryb interaktywny:
```powershell
gh auth login
# Where do you use GitHub?      -> GitHub.com
# Preferred protocol            -> SSH
# Upload your SSH public key    -> $HOME\.ssh\gh_pawcho_ed25519.pub
# How to authenticate           -> Login with a web browser (lub: Paste a token)
```

Sprawdzenie:
```powershell
gh auth status
```

---

## 3. Utworzenie publicznego repo pawcho6 i powiązanie z katalogiem

Z katalogu `pawcho6` (jest tu już commit):
```powershell
cd "C:\Users\s1016\Pulpit\Programming\sem6\docker\lab6\pawcho6"
gh repo create pawcho6 --public --source=. --remote=origin --push
```
Weryfikacja:
```powershell
gh repo view --web
gh repo list | Select-String pawcho6
```

---

## 4. Personal Access Token (PAT classic) dla ghcr.io

GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)**
→ Generate new token (classic). Zakres (scope) minimum:
- `write:packages`, `read:packages`, `delete:packages`
- `repo`

Zapisz token do zmiennej (sesyjnej):
```powershell
$env:CR_PAT = "ghp_...twoj_token..."
```

---

## 5. Logowanie do rejestru ghcr.io (Docker Desktop musi działać)

```powershell
$env:CR_PAT | docker login ghcr.io -u tadekbudowlaniec --password-stdin
# oczekiwane: Login Succeeded
```

---

## 6. Budowa obrazu z kontekstem SSH i push na ghcr.io

Obraz pobierze zawartość repo pawcho6 przez SSH (krok 1 musi być wykonany —
agent z dodanym kluczem):
```powershell
cd "C:\Users\s1016\Pulpit\Programming\sem6\docker\lab6\pawcho6"
docker build --ssh default -f Dockerfile.ssh `
    --build-arg VERSION=lab6 `
    -t ghcr.io/tadekbudowlaniec/pawcho6:lab6 .

docker push ghcr.io/tadekbudowlaniec/pawcho6:lab6
```

> Uwaga: nazwa obrazu na ghcr.io **musi być małymi literami**
> (`tadekbudowlaniec`, nie `TadekBudowlaniec`).

Szybki test obrazu lokalnie:
```powershell
docker run -d -p 8080:80 --name lab6web ghcr.io/tadekbudowlaniec/pawcho6:lab6
curl http://localhost:8080/
docker rm -f lab6web
```

---

## 7. Zmiana widoczności pakietu na public + powiązanie z repo

GitHub → profil → **Packages** → `pawcho6`:
- **Package settings** → Danger Zone → **Change visibility** → Public.
- **Connect repository** → wybierz repo `pawcho6` (lub działa to automatycznie
  przez etykietę `org.opencontainers.image.source` ustawioną w Dockerfile).

---

## Po zajęciach (sale laboratoryjne)
- usuń klucze/tokeny z komputera, wyloguj się: `gh auth logout`, `docker logout ghcr.io`,
- klucz `gh_pawcho_ed25519` zachowaj w bezpiecznym miejscu (lub usuń i wygeneruj ponownie).
