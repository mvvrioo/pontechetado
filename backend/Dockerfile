# =====================================================================
#  Imagen del backend de PonteChetado: PHP 8.3 + Apache
#  La API queda en http://localhost:8080/PonteChetado/api (ver docker-compose.yml)
# =====================================================================
FROM php:8.3-apache

# Extensión mysqli (para conectarse a MySQL) y mod_rewrite (lo usa el .htaccess)
RUN docker-php-ext-install mysqli \
    && a2enmod rewrite \
    # Permitir que los .htaccess del proyecto funcionen (igual que en XAMPP)
    && sed -ri 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf \
    # Hora de Chile para que "hoy" y los días de la semana calcen
    && echo "date.timezone=America/Santiago" > /usr/local/etc/php/conf.d/zona-horaria.ini

# Copiamos la API en la misma ruta que en XAMPP: /PonteChetado
COPY . /var/www/html/PonteChetado/

# db.php no se sube a GitHub; si no está, se usa la plantilla
# (en Docker los datos de conexión llegan por variables de entorno)
RUN if [ ! -f /var/www/html/PonteChetado/config/db.php ]; then \
        cp /var/www/html/PonteChetado/config/db.example.php /var/www/html/PonteChetado/config/db.php; \
    fi
