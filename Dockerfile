## Two-stage build for minimal Flutter web static server (Caddy runtime)
# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# Copy pubspec first for better layer caching
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the project
COPY . .

# Ensure no host caches leak into the container
RUN rm -rf .dart_tool build && \
	flutter pub get && \
	flutter gen-l10n && \
	flutter build web --release -O4 --wasm

# Stage 2: Caddy (Alpine) to serve static files with SPA fallback
FROM caddy:2-alpine AS runtime
WORKDIR /usr/share/caddy
# Copy built web assets
COPY --from=build /app/build/web/ /usr/share/caddy/
# Write Caddyfile inline (listens on :8080 and SPA fallback)
RUN cat > /etc/caddy/Caddyfile <<'CADDY'
{
	admin off
}

:8080 {
	root * /usr/share/caddy
	encode zstd gzip
	# SPA fallback: serve index.html if file not found
	try_files {path} /index.html
	file_server
}
CADDY
EXPOSE 8080
