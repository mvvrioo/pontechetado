# =====================================================================
#  Imagen de la app web de PonteChetado (Flutter Web + Nginx)
#  1) Compila la app Flutter para web.
#  2) La sirve con Nginx en http://localhost:8081 (ver docker-compose.yml)
# =====================================================================

# ---------- Etapa 1: compilar la app ----------
FROM ghcr.io/cirruslabs/flutter:stable AS compilar

# Dirección de la API que usará la app (la del contenedor "api")
ARG API_URL=http://localhost:8080/PonteChetado/api

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# ---------- Etapa 2: servir los archivos ----------
FROM nginx:alpine
COPY --from=compilar /app/build/web /usr/share/nginx/html
EXPOSE 80
