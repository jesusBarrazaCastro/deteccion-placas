# 🚗 Sistema de Detección y Gestión de Placas Vehiculares



Un sistema modular y escalable para la detección de placas vehiculares mediante Visión por Computadora (CV), diseñado para la gestión de accesos y la supervisión de vehículos en el tecnológico de culiacán.

---

## 👨‍💻 Autores
Proyecto desarrollado por **Jesús Alberto Barraza Castro y Jesús Guadalupe Wong Camacho**  
TecNM Campus Culiacán — Ingeniería en Tecnologías de la Información y Comunicaciones  
2025

---

## 🚀 Tecnologías Principales (Stack Tecnológico)

El proyecto se basa en una arquitectura contenerizada para asegurar la portabilidad y el alto rendimiento.

| Componente | Tecnología | Propósito |
| :--- | :--- | :--- |
| **Frontend** | **Flutter** | Interfaz de usuario multiplataforma (se puede desplegar a la web, iOS y Android). |
| **Backend** | **Python con FastAPI** | Servidor de aplicación que maneja las solicitudes del Frontend, ejecuta el modelo de CV y se comunica con la base de datos. |
| **Base de Datos**| **PostgreSQL** | Almacena información persistente, como registros de placas, eventos de detección y datos de usuarios. |
| **Despliegue** | **Docker & Docker Compose**| Contenerización y despliegue estandarizado y portable del Backend y la Base de Datos. |

---

## 📁 Estructura del Repositorio

El repositorio está organizado de forma modular, reflejando las capas de la arquitectura:
nombre-del-proyecto/ ├── .env.example # Variables de entorno para configuración (Backend/DB) ├── docker-compose.yml # Definición de servicios para Docker (Backend/DB) ├── README.md # 👈 Este archivo ├── backend/ # 📦 Código fuente del Backend (Python/FastAPI) │ ├── app/ # Lógica de FastAPI, API Endpoints │ ├── cv_model/ # Archivos del modelo de Visión por Computadora (CV) │ ├── requirements.txt # Dependencias de Python │ └── Dockerfile # Instrucciones para construir el contenedor del Backend ├── frontend/ # 📱 Código fuente del Frontend (Flutter) │ ├── lib/ # Lógica de la aplicación Flutter (UI, controllers, services) │ ├── pubspec.yaml # Dependencias de Flutter │ └── ... ├── database_scripts/ # 💾 Scripts de base de datos │ ├── schema.sql # Definición de tablas │ └── stored_procedures.sql # Funciones y lógica PL/pgSQL (ej. read_vehiculos) ├── docs/ # 📄 Documentación adicional (Manuales, informes) └── assets/ # 🖼️ Recursos multimedia (Imágenes de arquitectura, screenshots)

---

## 🛠️ Manual de Instalación de Entorno de Desarrollo

Este proceso describe los pasos para configurar el proyecto en una máquina local para desarrollo y pruebas.

### 1. Requisitos de Software Iniciales
Antes de comenzar, asegúrese de tener instalados los siguientes componentes:
* **Docker & Docker Compose**
* **Python 3.x**
* **Flutter SDK**
* **Git**

### 2. Obtención del Código Fuente
1.  **Clonar el Repositorio:** Abra su terminal, navegue hasta el directorio de trabajo deseado y clone el proyecto.
2.  **Verificación:** Verifique que la estructura del proyecto esté completa (ej. subdirectorios para `backend` y `frontend`).

### 3. Configuración y Arranque del Backend (Docker)
1.  **Levantar Contenedores:** Desde el directorio que contiene `docker-compose.yml`, ejecute el siguiente comando:
    ```bash
    docker-compose up -d --build
    ```
2.  **Aplicar Esquema de la DB:** Una vez que el contenedor de PostgreSQL esté activo, ejecute los scripts SQL de la carpeta `database_scripts` (que contienen las tablas y procedimientos almacenados) para inicializar la base de datos.

### 4. Ejecución del Frontend (Flutter)
1.  **Navegar al Frontend:** Ingrese al directorio del frontend.
2.  **Descargar Dependencias:** Utilice el comando `flutter pub get`.
3.  **Configurar Conexión:** Ingrese el *endpoint* en la clase `api_service.dart` para configurar la conexión al backend.
4.  **Ejecutar la Aplicación:** Use el comando `flutter run`, ya sea en un navegador web o un dispositivo Android o iOS.

---

## 📖 Documentación Técnica Detallada

Para la documentación completa, consulte el documento principal en `docs/Documentacion tecnica - deteccion placas.pdf`.

### 1. Arquitectura del Sistema
La aplicación fue diseñada con una arquitectura moderna y modular, separando claramente la capa de presentación de la lógica de negocio y la persistencia de datos. La arquitectura se compone de tres capas principales: **Frontend** (Capa de Presentación, con Flutter), **Backend** (Lógica de Negocio/Procesamiento, con Python/FastAPI) y **Base de Datos** (Capa de Datos, con PostgreSQL). Tanto el Backend como la Base de Datos se ejecutan dentro de contenedores **Docker**.

#### **Diagrama de Arquitectura:**


[Image of the application architecture diagram]


### 2. Esquema de la Base de Datos (PostgreSQL)
El sistema utiliza **PostgreSQL** como motor de base de datos relacional. El diseño se centra en cuatro entidades principales: `persona`, `vehiculo`, `scan_log` (Registro de Escaneos) e `incidencia`.

#### **Lógica de Negocio y Procedimientos Almacenados**
El sistema utiliza funciones y procedimientos almacenados (PL/pgSQL) directamente en la base de datos. El procedimiento `read_vehiculos` permite la **búsqueda inteligente de Vehículo por Placa** (`AC = 'by_id'`) para compensar errores de reconocimiento de placa utilizando múltiples niveles de coincidencia.

| Casos de Uso (`AC`) | Descripción |
| :--- | :--- |
| `by_id` | Búsqueda inteligente de Vehículo por Placa con compensación de errores de OCR. |
| `get_logs` | Recupera la lista de los últimos 100 registros de escaneo (`scan_log`), incluyendo información del vehículo y propietario. |
| `get_vehicle_list` | Devuelve la lista completa de todos los vehículos registrados y sus propietarios. |
| `get_incidencia_list` | Devuelve la lista completa de todas las incidencias registradas, ordenadas por fecha de registro descendente. |

### 3. Especificaciones de la API (FastAPI)
La interfaz de comunicación entre el Frontend (Flutter) y el Backend (Python con FastAPI) se realiza mediante una API RESTful.

| Módulo | Endpoint (Ruta) | Método HTTP | Descripción |
| :--- | :--- | :--- | :--- |
| **Detección** | `/api/vehiculos/detect-plate/` | `POST` | Recibe un archivo de imagen/video para el procesamiento por el modelo de CV. |
| **Vehículos** | `/api/vehiculos/read` | `POST` | Llama al procedimiento almacenado `read_vehiculos` con la acción `AC = 'by_id'` para la búsqueda inteligente de una placa. |
| **Incidencias** | `/api/incidencia/write/` | `POST` | Registra una nueva incidencia en la base de datos. |

---

## 💡 Manual de Usuario y Demostración

### Manual de Usuario
Este manual está dirigido al personal que utilizará la aplicación.

* [Enlace al Manual de Usuario PDF/Web para el usuario final]

### 🎬 Video Demostración
Vea cómo funciona el sistema de detección y gestión en acción:
* [Enlace a YouTube o Plataforma de Video]

---

## 🤝 Guía de Contribución

1.  **Reporte de Errores (Bugs):** Utilice la pestaña **Issues** para reportar cualquier error.
2.  **Sugerencias de Funcionalidades:** Use la pestaña **Issues** para proponer nuevas *features*.
3.  **Envío de Código:**
    * Haga un **Fork** de este repositorio.
    * Cree una nueva rama para su *feature* (`git checkout -b feature/nombre-de-tu-mejora`).
    * Cree un **Pull Request (PR)** detallando claramente el propósito y el alcance de sus cambios.

---

## 📄 Licencia

Este proyecto se distribuye bajo la **Licencia [Nombre de Licencia]**. Consulte el archivo `LICENSE.md` en la raíz del repositorio para más detalles.

---

## ✉️ Contacto

* **Alumnos:** Jesús Alberto Barraza Castro, Jesús Guadalupe Wong Camacho
* **Profesor:** Zuriel Dathan Mora Felix
