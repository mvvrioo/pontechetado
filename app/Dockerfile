# =====================================================================
#  Imagen de la app web de PonteChetado (Flutter Web + Nginx)
#  1) Compila la app Flutter para web.
#  2) La sirve con Nginx en http://localhost:8081 (ver docker-compose.yml)
# =====================================================================

# ---------- Etapa 1: compilar la app (misma versión de Flutter del proyecto) ----------
FROM debian:bookworm-slim AS compilar

ARG FLUTTER_VERSION=3.47.6
# Dirección de la API que usará la app (la del contenedor "api")
ARG API_URL=http://localhost:8080/PonteChetado/api

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Flutter oficial, en la versión con la que se desarrolló la app
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN git config --global --add safe.directory /flutter \
    && flutter --disable-analytics \
    && flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# ---------- Etapa 2: servir los archivos ----------
FROM nginx:alpine
COPY --from=compilar /app/build/web /usr/share/nginx/html
EXPOSE 80
