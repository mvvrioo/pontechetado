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
| `base_de_datos/docker-init/` | Respaldo `.sql` que MySQL carga la primera vez |
| `backend/config/db.php` | Lee los datos de conexión desde variables de entorno (o usa los de XAMPP) |

## Cómo levantarlo

1. Instalar **Docker Desktop** (https://www.docker.com/products/docker-desktop/) y abrirlo.
2. Exportar la base desde MySQL Workbench: **Server > Data Export** > marcar `pontechetado` >
   **Dump Structure and Data** > **Export to Self-Contained File** >
   `C:\proyectos\ponte_chetado\base_de_datos\docker-init\01_pontechetado.sql` > **Start Export**.
3. En la terminal, dentro de `C:\proyectos\ponte_chetado`:

   ```
   docker compose up -d --build
   ```

4. Probar en el navegador: http://localhost:8080/PonteChetado/api/auth/login.php
   (debe responder un JSON).
5. En la app, en `app/lib/config.dart`, poner `usarDocker = true` y correr `flutter run -d chrome`.

## Comandos útiles

| Comando | Qué hace |
|---|---|
| `docker compose ps` | Ver si los contenedores están corriendo |
| `docker compose logs -f api` | Ver los mensajes del backend |
| `docker compose down` | Apagar los contenedores (los datos se mantienen) |
| `docker compose down -v` | Apagar y **borrar la base** (vuelve a cargar el `.sql` la próxima vez) |
| `docker compose up -d --build` | Volver a construir después de cambiar el código PHP |

XAMPP puede seguir instalado: Docker usa los puertos 8080 y 3308, así que no chocan.
