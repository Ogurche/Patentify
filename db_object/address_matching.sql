CREATE OR REPLACE FUNCTION inn_matching.address_matching 
(i_inn_agg int8[],
i_max_sim NUMERIC, 
i_full_name varchar,
i_address varchar DEFAULT NULL)
RETURNS int8 
LANGUAGE plpgsql
SET SCHEMA 'inn_matching'
AS $func$ 
DECLARE 
	res int8 DEFAULT NULL;
BEGIN 

	/*
	 * max_simi пока не исспользуется, но можно исправить и обрабатывать
	 * если similarity > N то ....
	 * если similarity < N то ....
	 */
	
	PERFORM set_limit(0.8);
	
	IF i_inn_agg IS NULL THEN 
	
		WITH sub AS (
			SELECT
				i_full_name AS patent_holder
				, inn
				, similarity(p.short_name, i_full_name) simi
				, RANK() OVER (PARTITION BY i_full_name 
								ORDER BY similarity(p.short_name, i_full_name) DESC) rn
			FROM pure_inn p  
			WHERE 
				p.short_name % i_full_name)
		SELECT 
			max(simi) mx_simi 	
			, array_agg(inn ORDER BY simi DESC) inn_agg
		INTO i_max_sim, i_inn_agg
		FROM sub
		WHERE 
			sub.rn = 1
		GROUP BY patent_holder;
	END IF;	
	
	IF array_length(i_inn_agg, 1)> 1 THEN 
		RAISE info 'много инн';
		SELECT 	
			pis.inn
		INTO res
		FROM pure_inn pis
		WHERE pis.inn = ANY(i_inn_agg)
			AND (pis.jud_address = i_address
				OR pis.fact_address = i_address
				OR pis.jud_address % i_address
				OR pis.fact_address% i_address)
		ORDER BY (similarity(pis.jud_address, i_address) , similarity(pis.fact_address, i_address)) DESC 
		LIMIT 1; 
		
		IF NOT FOUND THEN 
			RAISE info 'не нашел адресс';
			res := i_inn_agg[1]::int8;
		END IF;
		
	ELSIF  array_length(i_inn_agg, 1)= 1 THEN 
		res := i_inn_agg[1]::int8;
		RAISE info 'ед. совпаление';
	END IF;
	RETURN res;

	EXCEPTION WHEN OTHERS THEN 
	NULL;
END;
$func$

SELECT address_matching (NULL,NULL, 'ооо "регион-мебель"', 'башкортостан респ., г. уфа, ул. маркса, д. 55 к. 2 кв. 19');
