
# Zadanie dodatkowe (2)

## 0. Sprawdzenie obrazu na zagrozenia
```
docker scout cves --only-severity critical,high weather-app

```

### Wynik

```

                    │       Analyzed Image
────────────────────┼──────────────────────────────
  Target            │  weather-app:latest 
    digest          │  2ed289d3aec2 
    platform        │ linux/amd64
    vulnerabilities │    0C     0H     0M     0L 
    size            │ 5.1 MB
    packages        │ 19
```

## 1. **Skrypt budujący obraz multiarch **

```
# Parametry konfiguracyjne
$IMAGE_NAME = "nerocrunch/academy-repo"
$IMAGE_TAG = "weather-app"
$CACHE_NAME = "${IMAGE_NAME}:buildcache"

# Sprawdź, czy builder istnieje
$builderName = "multiarch-builder"
$builderExists = docker buildx ls | Select-String $builderName

if (-not $builderExists) {
    Write-Host "Tworzenie buildera '$builderName'..."
    docker buildx create --name $builderName --driver docker-container --use
}
else {
    Write-Host "Builder '$builderName' już istnieje, używam go."
    docker buildx use $builderName
}

# Zaloguj się do Docker Hub
Write-Host "Logowanie do Docker Hub..."
docker login

# Budowa obrazu
Write-Host "Rozpoczynanie budowy obrazu multiarch..."
docker buildx build `
  --platform linux/amd64,linux/arm64 `
  --tag "${IMAGE_NAME}:${IMAGE_TAG}" `
  --push `
  --cache-from type=registry,ref=${CACHE_NAME} `
  --cache-to type=registry,ref=${CACHE_NAME},mode=max `
  --provenance=true `
  --progress=plain `
  .

# Inspekcja manifestu
Write-Host "Inspekcja manifestu:"
docker buildx imagetools inspect "${IMAGE_NAME}:${IMAGE_TAG}"

```

## 2. **Manifest zawiera deklaracje dla dwóch platform**

Podczas budowy obrazu z użyciem `docker buildx`, proces został skonfigurowany do obsługi dwóch platform sprzętowych: `linux/amd64` oraz `linux/arm64`. Aby potwierdzić, że manifest zawiera te deklaracje, wykonano następujące kroki:

### Inspekcja manifestu

Po zbudowaniu obrazu, użyto polecenia:

```bash
docker buildx imagetools inspect nerocrunch/academy-repo:weather-app
```

W wyniku tego polecenia otrzymano następujące informacje o dostępnych platformach:

```
Name:      docker.io/nerocrunch/academy-repo:weather-app
...

Manifests:
  Name:        docker.io/nerocrunch/academy-repo:weather-app@sha256:98b45e8d2aad66aaf69f619dceb296c29fc71e7cb062df65e5e8971c7727c65d
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    linux/amd64

  Name:        docker.io/nerocrunch/academy-repo:weather-app@sha256:baddd15d3026c18e01e28426cc7008d3e34d533eff91a4ee6f0286e333c39470
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    linux/arm64
```

Wyniki te potwierdzają, że obraz kontenera obsługuje zarówno platformę `linux/amd64`, jak i `linux/arm64`.

## 3. **Wykorzystanie cache w procesie budowy obrazu**

W celu przyspieszenia procesu budowy obrazu, podczas jego tworzenia użyto danych cache. Cache został skonfigurowany zarówno do pobierania (`--cache-from`), jak i zapisywania (`--cache-to`) do zewnętrznego rejestru.

### Konfiguracja cache

W trakcie budowy obrazu zastosowano następujące parametry dla cache:

```bash
--cache-from type=registry,ref=nerocrunch/academy-repo:buildcache
--cache-to type=registry,ref=nerocrunch/academy-repo:buildcache,mode=max
```

Te opcje pozwalają na używanie cache z zewnętrznego rejestru Docker (`nerocrunch/academy-repo:buildcache`), co ma na celu przyspieszenie procesu budowy, zwłaszcza podczas wielokrotnego budowania obrazu.

### Potwierdzenie działania cache

Podczas drugiego uruchomienia procesu budowy obrazu, w logach pojawiła się informacja o wykorzystaniu cache:

```
#5 CACHED
#6 CACHED
#7 CACHED
```

Oznacza to, że proces budowy obrazu wykorzystał wcześniej zapisane dane cache, co przyspieszyło jego czas wykonania.

## Podsumowanie

1. **Manifest obrazu** zawiera deklaracje dla dwóch platform (`linux/amd64` i `linux/arm64`), co zostało potwierdzone przez inspekcję manifestu.
2. **Cache** zostało poprawnie wykorzystane w procesie budowy obrazu, co zostało potwierdzone poprzez szybszy czas budowy i logi wskazujące na wykorzystanie cache.

Tym samym zostały spełnione wszystkie wymagania zadania.
