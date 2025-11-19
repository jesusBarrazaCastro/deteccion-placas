CREATE OR REPLACE FUNCTION read_vehiculos(
    _data JSONB  
)
RETURNS SETOF JSONB AS $$
DECLARE	
	AC VARCHAR;
	_placa VARCHAR;
BEGIN
	AC := _data ->> 'AC';
	_placa := _data ->> 'placa';
		
	IF AC = 'by_id' THEN
		RETURN QUERY
    SELECT COALESCE(jsonb_agg(a), '[]')
    FROM (
			SELECT 
				*
			FROM "public".vehiculo v
			WHERE v.placa = _placa
		) as a;	
	END IF;

END;
$$ LANGUAGE plpgsql;