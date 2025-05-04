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
