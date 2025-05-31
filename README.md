# 🐳 LAB 2  

## Cel zadania

Celem zadania było opracowanie łańcucha CI/CD (pipeline) z wykorzystaniem GitHub Actions, który:

- Buduje obraz kontenera na podstawie aplikacji napisanej w Go (Lab 1)
- Wykorzystuje `Dockerfile`
- Wspiera wiele architektur: `linux/amd64` oraz `linux/arm64`
- Wykonuje skanowanie obrazu na obecność luk bezpieczeństwa (CVE)
- Wysyła obraz do publicznego rejestru kontenerów GitHub (`ghcr.io`)
- Wykorzystuje cache warstw Docker BuildKit z rejestrem DockerHub (`mode=max`)

---

##  Konfiguracja i wykonanie

### 📁 Struktura repozytorium

```
.
├── Dockerfile
├── main.go
├── static/
└── .github/
    └── workflows/
        └── docker-build.yml
```

### Plik workflow: `.github/workflows/docker-build.yml`

Workflow wykonuje następujące kroki:

1. **Checkout repozytorium**
```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

2. **Konfiguracja QEMU i Docker Buildx (wspiera wiele architektur)**
```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
```

3. **Logowanie do DockerHub i GitHub Container Registry**
```yaml
- name: Log in to DockerHub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}

- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

4. **Budowanie tymczasowego obrazu tylko dla `linux/amd64` do lokalnego skanowania Trivy**
```yaml
- name: Build image for Trivy scan (amd64 only)
  uses: docker/build-push-action@v5
  with:
    context: .
    platforms: linux/amd64
    load: true
    tags: ${{ env.IMAGE_NAME }}:main
    cache-from: type=registry,ref=${{ env.CACHE_REPO }}:cache
    cache-to: type=registry,ref=${{ env.CACHE_REPO }}:cache,mode=max
```

5. **Skanowanie obrazu pod kątem podatności `CRITICAL` i `HIGH`**
```yaml
- name: Scan image for CVEs (critical/high)
  uses: aquasecurity/trivy-action@0.11.2
  with:
    image-ref: ${{ env.IMAGE_NAME }}:main
    format: "table"
    exit-code: "1"
    severity: "CRITICAL,HIGH"
```

6. **Budowanie i wypychanie multiarch (`linux/amd64`, `linux/arm64`) obrazu do GHCR**
```yaml
- name: Build and push multi-arch image
  if: success()
  uses: docker/build-push-action@v5
  with:
    context: .
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    cache-from: type=registry,ref=${{ env.CACHE_REPO }}:cache
    cache-to: type=registry,ref=${{ env.CACHE_REPO }}:cache,mode=max
```

7. **Wykorzystanie cache przez DockerHub (`registry`, `mode=max`)**
Cache używany jest w etapach budowania:
```yaml
cache-from: type=registry,ref=${{ env.CACHE_REPO }}:cache
cache-to: type=registry,ref=${{ env.CACHE_REPO }}:cache,mode=max
```

---

## Sekrety w GitHub Actions

Repozytorium zawiera dwa sekrety:

- `DOCKERHUB_USERNAME` – nazwa użytkownika DockerHub
- `DOCKERHUB_TOKEN` – access token z uprawnieniami **Read & Write**

---

## Potwierdzenie działania

Workflow został uruchomiony w gałęzi `main` i zakończył się sukcesem. Obraz został opublikowany do:

[ghcr.io/vladyslav-crunch/pawcho_lab_obw](https://github.com/vladyslav-crunch/PAwChO_LAB_OBW/pkgs/container/pawcho_lab_obw)

Zbudowane architektury:
- `linux/amd64`
- `linux/arm64`

---

## Sposób tagowania obrazów

Obrazy są tagowane za pomocą akcji [`docker/metadata-action`](https://github.com/docker/metadata-action), zgodnie z poniższym schematem:

- `:main` – tag domyślny dla gałęzi produkcyjnej
- `:sha-<skrót>` – unikalny identyfikator obrazu powiązany z konkretnym commitem

**Zalety:**
- Możliwość rollbacku do konkretnej wersji (`sha`)
- Spójność nazw wersji z historią git

---

## Tagowanie cache

Cache przechowywany jest w publicznym repozytorium DockerHub:

```
docker.io/nerocrunch/cache:cache
```

Używany format:

```yaml
cache-from: type=registry,ref=docker.io/nerocrunch/cache:cache
cache-to: type=registry,ref=docker.io/nerocrunch/cache:cache,mode=max
```

Zastosowanie `mode=max` gwarantuje, że zachowane zostaną wszystkie możliwe warstwy builda — co maksymalizuje wydajność przy kolejnych budowach.

Źródło: [Docker BuildKit Registry Cache](https://docs.docker.com/build/cache/backends/registry/)

---

## ✅ Podsumowanie

| Wymaganie                                   | Status |
|--------------------------------------------|--------|
| Build z Dockerfile                         | ✅     |
| Obsługa architektur `linux/amd64`, `arm64` | ✅     |
| Skanowanie CVE (`CRITICAL`, `HIGH`)        | ✅     |
| Push tylko gdy brak krytycznych podatności | ✅     |
| Cache registry z `mode=max`                | ✅     |
| Publiczne repozytorium GHCR                | ✅     |

---

## 📸 Zrzut ekranu z GHCR

![Zrut GHCR](/images/ghcr.png)




