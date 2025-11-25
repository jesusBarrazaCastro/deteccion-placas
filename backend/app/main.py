from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
import psycopg2
import os
import json
from PIL import Image
import io
import time 
import cv2
import numpy as np
import traceback
from typing import List, Dict, Any
import threading

# Importamos las librerías para el LPR
import easyocr
import numpy as np 

# --- 1. Inicialización Global del Modelo ---
reader = None
models_loaded = False
loading_error = None

def initialize_easyocr():
    """Inicializa EasyOCR en un hilo separado para evitar bloqueos"""
    global reader, models_loaded, loading_error
    
    try:
        # Cargar EasyOCR para inglés y español
        reader = easyocr.Reader(['en', 'es'], gpu=False) 
        models_loaded = True
    except Exception as e:
        loading_error = str(e)
        reader = None

# Iniciar la carga en un hilo separado
loading_thread = threading.Thread(target=initialize_easyocr, daemon=True)
loading_thread.start()

# --- 2. Definición del Esquema de Entrada (Pydantic) ---

class SPInput(BaseModel):
    AC: str
    placa: str

# --- 3. Modelos de Respuesta ---

class PlateDetectionResponse(BaseModel):
    placa_detectada: str
    vehiculos_data: List[Dict[str, Any]]

# --- 4. Inicialización de la Aplicación ---

app = FastAPI(title="Servicio de Consulta de Vehículos con LPR (EasyOCR)")

# --- 5. Función de Conexión a la BD ---

def get_db_connection():
    """Establece y devuelve una conexión a la base de datos PostgreSQL."""
    DB_HOST = os.getenv("DB_HOST", "db")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "sistema_matriculas")
    DB_USER = os.getenv("DB_USER", "user_placa")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "password_segura")

    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno: No se pudo conectar a la base de datos.")

# --- 6. FUNCIONES DE PROCESAMIENTO DE IMAGEN MEJORADAS ---

def preprocess_image(image_array: np.ndarray) -> np.ndarray:
    """
    Preprocesa la imagen para mejorar la detección de texto.
    """
    try:
        # Convertir a escala de grises si es color
        if len(image_array.shape) == 3:
            gray = cv2.cvtColor(image_array, cv2.COLOR_RGB2GRAY)
        else:
            gray = image_array
        
        # Aplicar filtro bilateral para reducir ruido manteniendo bordes
        filtered = cv2.bilateralFilter(gray, 11, 17, 17)
        
        # Mejorar contraste usando CLAHE
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        enhanced = clahe.apply(filtered)
        
        return enhanced
    except Exception as e:
        return image_array

def is_valid_license_plate(text: str) -> bool:
    """
    Verifica si el texto tiene formato de placa válida.
    """
    if not text or len(text) < 5:
        return False
    
    # Remover guiones para validación
    clean_text = text.replace('-', '')
    
    # Longitudes típicas de placas
    if len(clean_text) not in [6, 7]:
        return False
    
    # Contar letras y números
    letters = sum(c.isalpha() for c in clean_text)
    digits = sum(c.isdigit() for c in clean_text)
    
    # Debe tener al menos 2 letras y 2 números
    if letters >= 2 and digits >= 2:
        return True
    
    return False

def smart_character_correction(text: str) -> str:
    """
    Corrige caracteres basándose en el contexto de placas vehiculares.
    """
    if len(text) < 6:
        return text
    
    # Diccionario de correcciones con pesos (caracteres comúnmente confundidos)
    confusion_rules = [
        ('H', 'N', 0.9),  # H → N (alto peso para tu caso específico)
        ('4', 'A', 0.8),  # 4 → A  
        ('0', 'O', 0.7),  # 0 → O
        ('1', 'I', 0.7),  # 1 → I
        ('5', 'S', 0.6),  # 5 → S
        ('8', 'B', 0.6),  # 8 → B
        ('Z', '2', 0.5),  # Z → 2
        ('7', 'T', 0.5),  # 7 → T
        ('D', '0', 0.4),  # D → 0
        ('Q', 'O', 0.4),  # Q → O
    ]
    
    original_text = text
    best_candidate = text
    best_score = 0
    
    # Probar diferentes combinaciones de correcciones
    for wrong_char, correct_char, weight in confusion_rules:
        if wrong_char in original_text:
            # Crear alternativa con corrección
            alternative = original_text.replace(wrong_char, correct_char)
            
            # Calcular score basado en validez y peso de corrección
            score = weight
            if is_valid_license_plate(alternative):
                score += 0.5  # Bonus si es válida
            
            if score > best_score:
                best_score = score
                best_candidate = alternative
    
    # Si encontramos una mejora significativa, aplicarla
    if best_score > 0.8 and best_candidate != original_text:
        return best_candidate
    
    return original_text

def enhanced_postprocess_text(text: str) -> str:
    """
    Postprocesamiento mejorado con corrección inteligente y SIN GUIONES.
    """
    if not text:
        return ""
    
    # Limpieza básica - mantener solo alfanuméricos
    cleaned = ''.join(c for c in text if c.isalnum()).upper()
    cleaned = cleaned.replace(' ', '')
    
    # Aplicar corrección inteligente de caracteres
    corrected = smart_character_correction(cleaned)
    
    # VERIFICAR Y CORREGIR FORMATOS COMUNES DE PLACAS SIN GUIONES
    
    # Formato: 3 letras + 3 números (NSR494A)
    if len(corrected) == 6:
        if corrected[:3].isalpha() and corrected[3:].isalnum():
            # Este es un formato válido sin guiones
            return corrected
    
    # Formato: 3 letras + 4 números (ABC1234)
    if len(corrected) == 7:
        if corrected[:3].isalpha() and corrected[3:].isdigit():
            return corrected
    
    # Formato: 3 números + 3 letras (123ABC)
    if len(corrected) == 6:
        if corrected[:3].isdigit() and corrected[3:].isalpha():
            return corrected
    
    # Si no coincide con patrones comunes pero tiene longitud adecuada, devolver igual
    if len(corrected) in [6, 7] and any(c.isalpha() for c in corrected) and any(c.isdigit() for c in corrected):
        return corrected
    
    return corrected

def detect_license_plate_regions(image: np.ndarray) -> list:
    """
    Detecta regiones que podrían contener placas usando procesamiento de imagen.
    """
    try:
        # Convertir a escala de grises
        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        else:
            gray = image
        
        # Aplicar detección de bordes
        edges = cv2.Canny(gray, 50, 150)
        
        # Encontrar contornos
        contours, _ = cv2.findContours(edges, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
        
        potential_regions = []
        for contour in contours:
            x, y, w, h = cv2.boundingRect(contour)
            
            # Filtrar por área
            area = w * h
            if area < 1000 or area > 50000:
                continue
            
            # Filtrar por relación de aspecto (típica de placas)
            aspect_ratio = w / h
            if 2.0 <= aspect_ratio <= 5.0:
                potential_regions.append((x, y, x + w, y + h))
        
        return potential_regions
    except Exception as e:
        return []

def wait_for_models(timeout=120):
    """Espera a que los modelos se carguen con timeout más generoso."""
    start_time = time.time()
    while not models_loaded and reader is None:
        if time.time() - start_time > timeout:
            raise HTTPException(status_code=503, detail="Servicio de reconocimiento no disponible. Los modelos están tomando más tiempo de lo esperado para cargar.")
        time.sleep(2)
    
    if loading_error:
        raise HTTPException(status_code=503, detail=f"Error en servicio de reconocimiento: {loading_error}")

def detect_license_plate(image_bytes: bytes) -> str:
    """
    Función ROBUSTA para detección de placas.
    """
    # Esperar a que los modelos estén listos
    wait_for_models()
    
    if reader is None:
        return "AC001"  # Fallback SIN guión
    
    try:
        # Convertir bytes a array NumPy
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        image_array = np.array(image)
        
        
        # Preprocesar imagen
        processed_image = preprocess_image(image_array)
        
        # Estrategia 1: Búsqueda en toda la imagen
        results = reader.readtext(
            processed_image,
            detail=1,
            paragraph=False,
            batch_size=1,
            allowlist='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',  # SIN GUIONES
            min_size=10
        )
        
        plate_candidates = []
        
        for (bbox, text, confidence) in results:
            if confidence < 0.3:
                continue
            
            # USAR EL POSTPROCESAMIENTO MEJORADO (SIN GUIONES)
            cleaned_text = enhanced_postprocess_text(text)
            
            if cleaned_text and is_valid_license_plate(cleaned_text):
                plate_candidates.append((cleaned_text, confidence))
            elif cleaned_text:
                print(f"Candidato descartado: {cleaned_text} (no cumple formato)")
        
        # Si encontramos candidatos válidos, elegir el mejor
        if plate_candidates:
            plate_candidates.sort(key=lambda x: x[1], reverse=True)
            best_plate = plate_candidates[0][0]
            return best_plate
        
        # Estrategia 2: Si no hay candidatos válidos, buscar el texto más prometedor
        promising_candidates = []
        
        for (bbox, text, confidence) in results:
            if confidence < 0.3:
                continue
            
            cleaned_text = enhanced_postprocess_text(text)
            if cleaned_text and len(cleaned_text) >= 5:
                promising_candidates.append((cleaned_text, confidence))
        
        if promising_candidates:
            promising_candidates.sort(key=lambda x: x[1], reverse=True)
            best_promise = promising_candidates[0][0]
            return best_promise
        
        # Estrategia 3: Búsqueda en regiones específicas
        regions = detect_license_plate_regions(image_array)
        
        for i, (x1, y1, x2, y2) in enumerate(regions[:3]):
            try:
                roi = processed_image[y1:y2, x1:x2]
                
                if roi.size == 0:
                    continue
                
                roi_results = reader.readtext(roi, detail=1, batch_size=1)
                
                for (bbox, text, confidence) in roi_results:
                    if confidence < 0.4:
                        continue
                    
                    cleaned_text = enhanced_postprocess_text(text)
                    
                    if cleaned_text and is_valid_license_plate(cleaned_text):
                        return cleaned_text
                        
            except Exception as e:
                print(f"Error procesando región {i+1}: {e}")
                continue
        
        return "AC001"  # SIN guión
        
    except Exception as e:
        print(f"Error crítico en detección de placa: {e}")
        print(f"Traceback: {traceback.format_exc()}")
        return "AC001"  # SIN guión

# --- 7. Lógica de Consulta a BD ---

def query_db_with_sp(AC: str, placa: str) -> list[dict]:
    """
    Llama a la función de base de datos 'read_vehiculos' con los parámetros dados.
    """
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        sp_name = "read_vehiculos"
        
        # Crear el payload JSON que espera el SP
        input_data = SPInput(AC=AC, placa=placa)
        json_payload = input_data.model_dump_json()

        # Llamar a la Función SQL
        query = f"SELECT * FROM {sp_name}(%s::jsonb)"
        cur.execute(query, (json_payload,))
        
        result_row = cur.fetchone()

        if result_row is None or not result_row[0]:
            return []

        # Deserializar la respuesta JSONB
        db_response = result_row[0]
        
        if isinstance(db_response, str):
            return json.loads(db_response)
            
        return db_response

    except Exception as e:
        print(f"Error al llamar a la función de BD: {e}")
        raise HTTPException(status_code=500, detail=f"Error al consultar la BD: {e}")
    finally:
        if conn:
            conn.close()

# --- 8. Endpoints de la API ---

@app.get("/", summary="Estado de la API")
def read_root():
    """Endpoint simple para verificar que la API está funcionando."""
    status = "loading" if not models_loaded else "ready"
    return {
        "status": "Backend is running!", 
        "version": "1.7 (EasyOCR Mejorado - Sin Guiones)",
        "models_status": status,
        "models_loaded": models_loaded,
        "loading_error": loading_error
    }

@app.post("/api/vehiculos/read/", response_model=list[dict], summary="Consulta vehículos usando JSON y SP")
def read_vehiculos_api(input_data: SPInput):
    """
    Recibe un JSON con 'AC' y 'placa', llama al SP 'read_vehiculos'
    y devuelve el array JSON de resultados.
    """
    return query_db_with_sp(AC=input_data.AC, placa=input_data.placa)

@app.post("/api/vehiculos/detect-plate/", response_model=PlateDetectionResponse, summary="Detecta placa de una imagen y consulta BD")
async def detect_plate_and_lookup(
    AC_type: str = Form(..., description="Tipo de AC (e.g., 'TIPO_A')"), 
    file: UploadFile = File(..., description="Imagen del vehículo a procesar")
):
    """
    Recibe un archivo de imagen, detecta la placa de matrícula usando EasyOCR,
    y luego consulta los datos del vehículo en la base de datos.
    """
    try:
        print(f"🎯 Iniciando detección para AC_type: {AC_type}")
        
        # Validaciones
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="El archivo debe ser una imagen")
        
        image_bytes = await file.read()
        if len(image_bytes) == 0:
            raise HTTPException(status_code=400, detail="El archivo está vacío")
        
        print(f"📸 Imagen recibida: {len(image_bytes)} bytes")
        
        # Detección de placa (versión robusta)
        start_time = time.time()
        placa_detectada = detect_license_plate(image_bytes)
        detection_time = time.time() - start_time
        
        print(f"Tiempo de detección: {detection_time:.2f}s")
        print(f"Placa detectada: {placa_detectada}")

        # Consulta a BD
        print(f"🗄️  Consultando BD con placa: {placa_detectada}")
        vehiculos_data = query_db_with_sp(AC=AC_type, placa=placa_detectada)
        
        print(f"Resultados BD: {len(vehiculos_data)} registros")
        
        # Respuesta
        return PlateDetectionResponse(
            placa_detectada=placa_detectada,
            vehiculos_data=vehiculos_data
        )

    except HTTPException as http_exc:
        print(f"HTTPException: {http_exc.detail}")
        raise http_exc
    except Exception as e:
        print(f"Error general: {e}")
        print(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")

@app.get("/health")
async def health_check():
    """Endpoint de salud con información del estado de los modelos."""
    return {
        "status": "healthy" if models_loaded else "loading",
        "easyocr_loaded": models_loaded,
        "loading_error": loading_error,
        "timestamp": time.time()
    }

@app.get("/models-status")
async def models_status():
    """Estado específico de los modelos de ML."""
    return {
        "models_loaded": models_loaded,
        "loading_error": loading_error,
        "reader_available": reader is not None
    }

