# 1. ETAPA BASE
# Usamos una imagen slim de Python, que es más pequeña.
FROM python:3.11-slim-bullseye
# 2. DEPENDENCIAS DEL SISTEMA
# Instalamos librerías necesarias para OpenCV (libgl1-mesa-glx)
# y para el driver de PostgreSQL (libpq-dev).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libgl1-mesa-glx \
    libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# 3. DIRECTORIO DE TRABAJO
# Establece el directorio de trabajo donde estará la aplicación dentro del contenedor.
WORKDIR /app

# 4. INSTALACIÓN DE DEPENDENCIAS DE PYTHON
# Copia el archivo de requisitos
COPY requirements.txt .

# Instala todas las dependencias listadas en requirements.txt
# La opción --no-cache-dir ayuda a mantener pequeña la imagen final.
RUN pip install --no-cache-dir -r requirements.txt

# 5. CÓDIGO DE LA APLICACIÓN
# Copia el directorio de la aplicación al contenedor.
# Usamos /app/app porque ahí es donde la aplicación FastAPI realmente reside (app/main.py).
COPY ./app /app/app
# Si tienes datos del modelo (weights, checkpoints, etc.), copia también:
COPY ./model_data /app/model_data

# 6. EXPOSICIÓN Y ARRANQUE
# Puerto que usará el servidor uvicorn (FastAPI).
EXPOSE 8000

# Comando de inicio del servidor uvicorn.
# app.main:app -> Busca la instancia 'app' en el archivo 'main.py' dentro del módulo 'app'.
# --host 0.0.0.0 -> Permite que el servidor sea accesible desde fuera del contenedor.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]