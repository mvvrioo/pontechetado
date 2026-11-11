# PonteChetado con Docker

Docker empaqueta el backend (PHP 8.3 + Apache) y la base de datos (MySQL 8) en
contenedores, para que el proyecto se levante igual en cualquier computador con
un solo comando, sin instalar XAMPP ni configurar nada a mano.

## Arquitectura

```
 App Flutter  --HTTP/JSON-->  [contenedor api]  ---->  [contenedor db]
 (celular/web)                PHP 8.3 + Apache          MySQL 8.0
                              puerto 8080               puerto 3308
```

| Archivo | Para qué sirve |
|---|---|
| `docker-compose.yml` | Define los 2 servicios (`api` y `db`), sus puertos y cómo se conectan |
| `backend/Dockerfile` | Receta de la imagen del backend: PHP + Apache + mysqli + mod_rewrite |
| `.env` | Contraseña del MySQL de Docker (no se sube a GitHub) |
| `base_de_datos/instalacion_completa.sql` | Tablas y catálogo que MySQL carga solo la primera vez |
| `backend/config/db.php` | Lee los datos de conexión desde variables de entorno (o usa los de XAMPP) |

## Cómo levantarlo

1. Instalar **Docker Desktop** (https://www.docker.com/products/docker-desktop/) y abrirlo.
2. Crear el archivo de contraseña: en `C:\proyectos\ponte_chetado` ejecutar `copy .env.example .env`
   (puedes cambiar la contraseña dentro de `.env`).
3. En la terminal, dentro de `C:\proyectos\ponte_chetado`:

   ```
   docker compose up -d --build
   ```

4. Probar en el navegador: http://localhost:8080/PonteChetado/api/auth/login.php
   (debe responder un JSON).
5. Registrarte en la app y hacerte superadmin: `docker exec -it pontechetado-db mysql -uroot -p pontechetado`
   y luego `UPDATE usuarios SET rol = 'superadmin' WHERE email = 'tu@correo.cl';`
6. En la app, en `app/lib/config.dart`, poner `usarDocker = true` y correr `flutter run -d chrome`.

## Comandos útiles

| Comando | Qué hace |
|---|---|
| `docker compose ps` | Ver si los contenedores están corriendo |
| `docker compose logs -f api` | Ver los mensajes del backend |
| `docker compose down` | Apagar los contenedores (los datos se mantienen) |
| `docker compose down -v` | Apagar y **borrar la base** (vuelve a cargar el `.sql` la próxima vez) |
| `docker compose up -d --build` | Volver a construir después de cambiar el código PHP |

XAMPP puede seguir instalado: Docker usa los puertos 8080 y 3308, así que no chocan.

La base de Docker parte vacía (sin usuarios): es independiente de la de XAMPP.

Para correr las pruebas de la API contra Docker (necesita PHP instalado, por ejemplo el de XAMPP):

```
set DB_PORT=3308
set DB_PASSWORD=la_de_tu_.env
C:\xampp\php\php.exe backend\pruebas\probar_api.php http://localhost:8080/PonteChetado/api
```
