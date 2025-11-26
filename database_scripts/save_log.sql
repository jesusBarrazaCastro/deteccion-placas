CREATE OR REPLACE FUNCTION "public"."write_log"(_data JSONB)
  RETURNS SETOF "pg_catalog"."jsonb" AS $BODY$
DECLARE	
	AC VARCHAR;
	_vehiculo_id BIGINT;
BEGIN
	AC := _data ->> 'AC';
	_vehiculo_id := (_data ->> 'vehiculo_id')::BIGINT;
			
	IF AC = 'save_log' THEN
	--GUARDAR LOG
		INSERT INTO public.scan_log(
			vehiculo_id,
			registro_fecha
		)
		VALUES (
			_vehiculo_id,
			CURRENT_TIMESTAMP
		);
		-------------
		RETURN QUERY
    SELECT COALESCE(jsonb_agg(a), '[]'::jsonb)
    FROM (
			SELECT 'OKasdwewgasd'
		) as a;	
	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;