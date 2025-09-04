# syntax=docker/dockerfile:1.7-labs
## Two-stage build for minimal Flutter web static server (Caddy runtime)
# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# Copy pubspec first for better layer caching
COPY pubspec.* ./
# Use BuildKit cache for Dart pub cache
RUN --mount=type=cache,target=/root/.pub-cache \
	flutter pub get

# Copy the rest of the project
COPY . .

# Ensure no host caches leak into the container; use BuildKit caches for pub and Flutter
RUN --mount=type=cache,target=/root/.pub-cache \
    --mount=type=cache,target=/sdks/flutter/bin/cache \
    rm -rf .dart_tool build && \
	flutter pub get && \
	flutter gen-l10n && \
	flutter build web --release -O4 --wasm

# Stage 2: Caddy (Alpine) to serve static files with SPA fallback
FROM caddy:2-alpine AS runtime
WORKDIR /usr/share/caddy
# Copy built web assets
COPY --from=build /app/build/web/ /usr/share/caddy/
# Write Caddyfile inline (listens on :8080 and SPA fallback)
ENV PORT=8080
RUN cat > /etc/caddy/Caddyfile <<'CADDY'
{
	admin off
}

:{$PORT} {
	root * /usr/share/caddy
	encode zstd gzip
	# SPA fallback: serve index.html if file not found
	try_files {path} /index.html
	file_server
}
CADDY
# Some platforms (e.g., gVisor/Firecracker like Render) forbid file capabilities; strip and copy to a clean path
USER root
RUN apk add --no-cache libcap && \
	(setcap -r /usr/bin/caddy || true) && \
	install -m 0755 /usr/bin/caddy /caddy && \
	apk del libcap
# Use numeric UID/GID for caddy to avoid passwd lookup issues across platforms
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
