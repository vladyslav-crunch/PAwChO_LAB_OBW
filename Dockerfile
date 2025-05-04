# --- Build stage ---
FROM golang:1.23.8-alpine AS builder

RUN apk add --no-cache upx

WORKDIR /app

# Copy only source code first
COPY main.go .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o server main.go \
    && upx --best --lzma server

# Now copy static files separately
COPY static/ static/

# --- Final minimal runtime stage ---
FROM alpine:3.19

WORKDIR /app

COPY --from=builder /app/server /app/server
COPY --from=builder /app/static /app/static

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/healthcheck || exit 1

ENTRYPOINT ["/app/server"]
