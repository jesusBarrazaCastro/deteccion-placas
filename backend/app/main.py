from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
import os
import json # Necesario para asegurar la correcta serialización/deserialización del JSON

# --- 1. Definición del Esquema de Entrada (Pydantic) ---

# Este modelo define la estructura que esperamos recibir en el cuerpo del POST.
# Coincide con las claves que tu SP espera: 'AC' y 'placa'.
class SPInput(BaseModel):
    AC: str
    placa: str

# --- 2. Inicialización de la Aplicación ---

app = FastAPI()

# --- 3. Función de Conexión a la BD ---

def get_db_connection():
    """Establece y devuelve una conexión a la base de datos PostgreSQL."""
    try:
        # Usamos variables de entorno (definidas en docker-compose)
        conn = psycopg2.connect(
            dbname=os.getenv("POSTGRES_DB", "sistema_matriculas"),
            user=os.getenv("POSTGRES_USER", "user_placa"),
            password=os.getenv("POSTGRES_PASSWORD", "password_segura"),
            host="db",  # Nombre del servicio de la BD en docker-compose
            port="5432"
        )
        return conn
    except Exception as e:
        print(f"Error al conectar a la BD: {e}")
        raise HTTPException(status_code=500, detail="Error interno: No se pudo conectar a la base de datos.")


# --- 4. Endpoints de la API ---

@app.get("/", summary="Estado de la API")
def read_root():
    """Endpoint simple para verificar que la API está funcionando."""
    return {"status": "Backend is running!", "version": "1.0"}


@app.post("/api/vehiculos/read/", response_model=list[dict], summary="Consulta vehículos usando JSON y SP")
def read_vehiculos_api(input_data: SPInput):
    """
    Recibe un JSON con 'AC' y 'placa', llama al SP 'read_vehiculos'
    y devuelve el array JSON de resultados.
    """
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        sp_name = "read_vehiculos"

        # 1. Convertir el objeto Pydantic de entrada a un string JSON.
        # Esto genera el parámetro JSON que tu SP (_data JSONB) espera.
        json_payload = input_data.model_dump_json()

        # 2. Llamar a la Función (el SP que devuelve SETOF JSONB/JSONB)
        # La función SQL devuelve un array JSON (un solo registro).
        query = f"SELECT * FROM {sp_name}(%s::jsonb)"
        cur.execute(query, (json_payload,))
        
        # 3. Obtener el único resultado que es el array JSON completo
        result_row = cur.fetchone()

        if result_row is None:
            # Esto puede pasar si el SP no devuelve nada (aunque debería devolver '[]')
            return []

        # 4. El resultado[0] es el array JSONB completo, psycopg2 lo convierte a list de Python.
        # Utilizamos json.loads para asegurar que si viene como string JSON, se convierta en objeto Python
        db_response = result_row[0]
        
        # Si el SP retornó SETOF JSONB, el resultado ya es un objeto Python (list/dict)
        # Si el SP retornó el array JSON como string, se necesita deserializar
        if isinstance(db_response, str):
            return json.loads(db_response)
            
        return db_response

    except Exception as e:
        print(f"Error al llamar a la función de BD: {e}")
        raise HTTPException(status_code=500, detail=f"Error al procesar la solicitud: {e}")
    finally:
        if conn:
            conn.close()

# Se elimina el endpoint 'get_vehicle_by_plate_sp' anterior para evitar duplicidades
# Puedes borrarlo si ya no lo usas.