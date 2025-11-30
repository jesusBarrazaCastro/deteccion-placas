CREATE OR REPLACE FUNCTION "public"."write_incidencia"(_data JSONB)
 RETURNS SETOF "pg_catalog"."jsonb" AS $BODY$
DECLARE
    -- Variables para almacenar datos y IDs. vehiculo_id ahora se recibe por parámetro.
		AC VARCHAR := _data ->> 'AC';
    _vehiculo_id BIGINT := (_data ->> 'vehiculo_id')::BIGINT;
		_placa VARCHAR := (_data ->> 'placa');
    _descripcion VARCHAR := _data ->> 'descripcion';
    _estado VARCHAR := _data ->> 'estado'; 
    _latitud NUMERIC := (_data ->> 'latitud')::NUMERIC;     
    _longitud NUMERIC := (_data ->> 'longitud')::NUMERIC;   
    _imagenes_urls JSONB := _data -> 'imagenes_urls';  
    _incidencia_id BIGINT;
    _img_url TEXT;

BEGIN
	
	IF AC = 'save_incidencia' THEN
		-- 1. VALIDAR EL ID DEL VEHÍCULO RECIBIDO
    IF _vehiculo_id IS NULL OR _vehiculo_id = 0 THEN
        RETURN QUERY
        SELECT jsonb_build_object('status', 'ERROR', 'message', 'ID de Vehículo no válido o ausente.');
        RETURN;
    END IF;

    -- 2. INSERTAR LA INCIDENCIA 
    INSERT INTO public.incidencia(
        vehiculo_id,
				placa,
        registro_fecha,
				latitud,  
        longitud,
        descripcion,
				estado,
				estado_validacion
    )
    VALUES (
        _vehiculo_id,
				_placa,
        CURRENT_TIMESTAMP,
				_latitud,
				_longitud,
        _descripcion,
        'Registrada',
				false
    )
    RETURNING id INTO _incidencia_id; -- Obtener el ID de la nueva incidencia
		
		--BLOQUEAR PERSONA SI ES LA TERCERA INCIDENCIA
		IF ((SELECT COUNT(*) FROM public.incidencia WHERE vehiculo_id = _vehiculo_id AND estado_validacion = false) >= 3) THEN
			UPDATE public.persona SET
				estado = 'inactivo'
			WHERE id = (SELECT persona_id FROM public.vehiculo WHERE id = _vehiculo_id);
		END IF;

    -- 4. DEVOLVER EL RESULTADO DE ÉXITO
    RETURN QUERY
    SELECT COALESCE(jsonb_agg(a), '[]'::jsonb)
    FROM (
        SELECT
            'OK' AS status,
            'Incidencia registrada exitosamente.' AS message,
            _incidencia_id AS incidencia_id
    ) AS a;
	END IF;

END;
$BODY$
 LANGUAGE plpgsql VOLATILE
 COST 100
 ROWS 1000;