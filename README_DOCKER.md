# PonteChetado con Docker

Docker empaqueta la app web (Flutter + Nginx), el backend (PHP 8.3 + Apache) y
la base de datos (MySQL 8) en contenedores, para que el proyecto se levante igual en cualquier computador con
un solo comando, sin instalar XAMPP ni configurar nada a mano.

## Arquitectura

```
 [contenedor web]  --HTTP/JSON-->  [contenedor api]  ---->  [contenedor db]
 Flutter Web + Nginx               PHP 8.3 + Apache          MySQL 8.0
 puerto 8081                       puerto 8080               puerto 3308
```

| Archivo | Para qué sirve |
|---|---|
| `docker-compose.yml` | Define los 3 servicios (`web`, `api` y `db`), sus puertos y cómo se conectan |
| `app/Dockerfile` | Compila la app Flutter para web y la sirve con Nginx |
| `backend/Dockerfile` | Receta de la imagen del backend: PHP + Apache + mysqli + mod_rewrite |
| `.env` | Contraseña del MySQL de Docker (no se sube a GitHub) |
| `base_de_datos/instalacion_completa.sql` | Tablas y catálogo que MySQL carga solo la primera vez |
| `base_de_datos/datos_demo.sql` | Gimnasio y cuentas de demostración (también solo la primera vez) |
| `backend/config/db.php` | Lee los datos de conexión desde variables de entorno (o usa los de XAMPP) |

## Instalación con un clic

1. Instalar **Docker Desktop** (https://www.docker.com/products/docker-desktop/) y abrirlo.
2. Hacer doble clic en **`INSTALAR.bat`** (en la carpeta del proyecto).

El archivo crea la contraseña de la base de datos, construye la app, la API y la base
de datos (con el catálogo y las cuentas demo) y abre la app en el navegador.
Para apagarlo: **`APAGAR.bat`**.

## Cómo levantarlo a mano


1. Instalar **Docker Desktop** (https://www.docker.com/products/docker-desktop/) y abrirlo.
2. Crear el archivo de contraseña: en `C:\proyectos\ponte_chetado` ejecutar `copy .env.example .env`
   (puedes cambiar la contraseña dentro de `.env`).
3. En la terminal, dentro de `C:\proyectos\ponte_chetado`:

   ```
   docker compose up -d --build
   ```

4. Abrir la app: **http://localhost:8081** (la primera vez tarda unos minutos en compilar).
   La API queda en http://localhost:8080/PonteChetado/api

## Cuentas de demostración

La base de Docker parte con un gimnasio ("Gimnasio Demo") y estas cuentas.
Todas usan la contraseña **Chetado2026**:

| Rol | Correo |
|---|---|
| Superadmin | superadmin.demo@pontechetado.test |
| Admin del gimnasio | admin.demo@pontechetado.test |
| Entrenador | entrenador.demo@pontechetado.test |
| Socio Premium | usuario.demo@pontechetado.test |
| Socio gratis (sin gimnasio) | gratis.demo@pontechetado.test |

Para usar la app de escritorio o el celular contra Docker, en `app/lib/config.dart`
poner `usarDocker = true` y correr `flutter run`.

## Comandos útiles

| Comando | Qué hace |
|---|---|
| `docker compose ps` | Ver si los contenedores están corriendo |
| `docker compose logs -f api` | Ver los mensajes del backend |
| `docker compose down` | Apagar los contenedores (los datos se mantienen) |
| `docker compose down -v` | Apagar y **borrar la base** (vuelve a cargar el `.sql` la próxima vez) |
| `docker compose up -d --build` | Volver a construir después de cambiar el código PHP |

XAMPP puede seguir instalado: Docker usa los puertos 8080 y 3308, así que no chocan.

La base de Docker es independiente de la de XAMPP.

Cada vez que se sube un cambio a GitHub, la acción "Instalación con Docker"
levanta los 3 contenedores desde cero y corre todas las pruebas de la API.

Para correr las pruebas de la API contra Docker (necesita PHP instalado, por ejemplo el de XAMPP):

```
set DB_PORT=3308
set DB_PASSWORD=la_de_tu_.env
C:\xampp\php\php.exe backend\pruebas\probar_api.php http://localhost:8080/PonteChetado/api
```
