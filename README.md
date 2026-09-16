PonteChetado

Descripción
PonteChetado es una aplicación móvil enfocada en la gestión y gamificación del entrenamiento físico. 

Qué hace: Permite a los usuarios registrar sus entrenamientos diarios, llevando un control de series, repeticiones y pesos. Cuenta con un sistema de validación que, al comprobar el pago de la membresía del gimnasio, desbloquea una versión Premium. Esta versión ofrece rutinas personalizadas, un *Scoreboard* (Top 10) en tiempo real, un chatbox que te guia con tus ejercicios y un avatar dinámico que evoluciona según el volumen de entrenamiento.
A quién va dirigido: Está diseñado para usuarios de gimnasios que desean entrenar con las mejores rutinas sin necesidad de tener conocimientos previos sobre *fitness*, así como para los propios recintos deportivos.
Qué problema resuelve: Soluciona la falta de retención al otorgar una imagen más premium al gimnasio y mejora la fidelización de los clientes. Adicionalmente, alivia la carga de trabajo de los entrenadores gracias al asistente de Chatbox y al botón de notificaciones para solicitar ayuda presencial.

Tecnologías Utilizadas
FrameWork Flutter,con extension de Dart, para asi poder usar Python
Base de Datos: MySQL 

Instrucciones para levantar el proyecto localmente:
1. Clonar el repositorio en tu máquina local.
2. Configurar la base de datos e importar el script SQL inicial.
3. Configurar el archivo .env con las variables de entorno (credenciales de BD).
4. Backend (Python): Navegar a la carpeta del servidor, instalar las dependencias y ejecutar la API.
5. Frontend (Flutter): Navegar a la carpeta de la app, descargar las dependencias y correr la aplicación en un emulador o dispositivo físico con flutter run.

Integrantes:
Mario Torres - Desarrollador Full-Stack / Jefe de Proyecto. Responsable de la arquitectura de la solución, desarrollo de software frontend/backend y gestión del proyecto.

Metodologia del protecto:
SCRUM: Se trabaja mediante un enfoque ágil iterativo e incremental. El proyecto se basa en la definición de un PMV y la estructuración de Épicas estimadas con Poker Planning. El desarrollo está organizado en Sprints semanales para garantizar entregas funcionales y revisiones constantes.

Arquitectura:
El sistema opera bajo una arquitectura Cliente-Servidor (Full-Stack). 
Capa Cliente (Frontend): Desarrollada en Flutter, se encarga de la interfaz gráfica (UX/UI), captura de datos de entrenamiento y renderizado del avatar gamificado.
Capa Servidor (Backend): Desarrollada en Python, actúa como una API REST que centraliza la lógica de negocio, realiza los cálculos de experiencia, gestiona el ranking del scoreboard.
Capa de Datos: Base de datos relacional para la persistencia segura del historial de los usuarios y la validación de sus estados Premium.
