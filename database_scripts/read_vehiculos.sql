CREATE OR REPLACE FUNCTION "public"."read_vehiculos"("_data" jsonb)
  RETURNS SETOF "pg_catalog"."jsonb" AS $BODY$
DECLARE	
	AC VARCHAR;
	_placa VARCHAR;
	_placa_clean VARCHAR;
BEGIN
	AC := _data ->> 'AC';
	_placa := UPPER(TRIM(_data ->> 'placa'));
	_placa_clean := REGEXP_REPLACE(_placa, '[^A-Z0-9]', '', 'g');
	
	RAISE NOTICE 'Buscando placa: %, Limpia: %', _placa, _placa_clean;
		
	IF AC = 'by_id' THEN
		-------------
		RETURN QUERY
    SELECT COALESCE(jsonb_agg(a), '[]'::jsonb)
    FROM (
			SELECT 
				v.id,
				v.persona_id,
				v.placa,
				v.marca,
				v.modelo,
				v.ano,
				v.color,
				p.tipo as persona_tipo,
				p.clave as persona_clave,
				p.nombre_completo,
				p.sexo,
				p.fecha_nacimiento,
				p.correo,
				p.num_telefono,
				p.estado as persona_estado
			FROM "public".vehiculo v
			LEFT JOIN "public".persona p ON p.id = v.persona_id
			WHERE 
				-- 1. Búsqueda exacta (case insensitive)
				UPPER(v.placa) = _placa
				OR 
				-- 2. Búsqueda exacta sin caracteres especiales
				REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g') = _placa_clean
				OR
				-- 3. Búsqueda por similitud de texto (Levenshtein)
				LEVENSHTEIN(REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g'), _placa_clean) <= 2
				OR
				-- 4. Búsqueda por patrón (caracteres similares)
				(
					LENGTH(REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g')) = LENGTH(_placa_clean)
					AND SIMILARITY(REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g'), _placa_clean) > 0.6
				)
			ORDER BY
				-- Priorizar resultados más exactos
				CASE 
					WHEN UPPER(v.placa) = _placa THEN 1
					WHEN REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g') = _placa_clean THEN 2
					WHEN LEVENSHTEIN(REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g'), _placa_clean) = 1 THEN 3
					WHEN LEVENSHTEIN(REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g'), _placa_clean) = 2 THEN 4
					ELSE 5
				END,
				-- Ordenar por similitud descendente
				SIMILARITY(REGEXP_REPLACE(UPPER(v.placa), '[^A-Z0-9]', '', 'g'), _placa_clean) DESC
		) as a;	
		
	ELSEIF AC = 'get_logs' THEN
		RETURN QUERY
    SELECT COALESCE(jsonb_agg(a), '[]'::jsonb)
    FROM (
			SELECT 
				v.id,
				v.persona_id,
				v.placa,
				v.marca,
				v.modelo,
				v.ano,
				v.color,
				p.tipo as persona_tipo,
				p.clave as persona_clave,
				p.nombre_completo,
				p.sexo,
				p.fecha_nacimiento,
				p.correo,
				p.num_telefono,
				p.estado as persona_estado,
				sl.registro_fecha as fecha_scan
			FROM "public".vehiculo v
			LEFT JOIN "public".persona p ON p.id = v.persona_id
			INNER JOIN "public".scan_log sl ON sl.vehiculo_id = v.id
			ORDER BY sl.registro_fecha DESC
			LIMIT 100
		) as a;	
		
	ELSEIF AC = 'get_vehicle_list' THEN
		RETURN QUERY
    SELECT COALESCE(jsonb_agg(a), '[]'::jsonb)
    FROM (
			SELECT 
				v.id,
				v.persona_id,
				v.placa,
				v.marca,
				v.modelo,
				v.ano,
				v.color,
				p.tipo as persona_tipo,
				p.clave as persona_clave,
				p.nombre_completo,
				p.sexo,
				p.fecha_nacimiento,
				p.correo,
				p.num_telefono,
				p.estado as persona_estado
			FROM "public".vehiculo v
			INNER JOIN "public".persona p ON p.id = v.persona_id
		) as a;	
		
	ELSEIF AC = 'get_incidencia_list' THEN
		RETURN QUERY
    SELECT COALESCE(jsonb_agg(a), '[]'::jsonb)
    FROM (
			SELECT 
				*
			FROM "public".incidencia
			ORDER BY registro_fecha DESC
		) as a;	
	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000