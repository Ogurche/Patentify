CREATE OR REPLACE FUNCTION patent_case.find_similarity
( IN i_patent_holder varchar
, IN i_application_num int DEFAULT NULL 
, IN i_reg_num int DEFAULT NULL 
, IN i_allow int DEFAULT 1 
, IN upload_id int DEFAULT 999
, IN i_patent_str_dt int DEFAULT NULL
, IN i_author varchar DEFAULT NULL 
, IN i_invention varchar DEFAULT NULL 
, IN i_patent_type int DEFAULT NULL
, OUT o_inn varchar 
, OUT o_full_name varchar
, OUT o_id int )
LANGUAGE plpgsql
SET SCHEMA 'patent_case'
AS $func$ 
DECLARE 
	
	v_patent_type int2;
	x varchar; 
	
BEGIN 
	/*
	 * Сначала проверяем повторное использование
	 */
	o_id := NULL; 
	
	PERFORM set_limit(0.9);
	
	SELECT 1
	INTO o_inn 
	FROM patent_case.patent_request pr
	WHERE 
		i_reg_num = reg_number
	LIMIT 1;
	
	IF NOT FOUND THEN	
	/*
	 * Проверяем pure_inn на наличие совпадений 
	 * выдаем топ-1 по сходству 
	 * если несколько записей, нужно выдать массив c иннками
	 */
	FOR x IN SELECT string_to_array(i_patent_holder, ',') LOOP  
		WITH sub AS (
			SELECT
				x AS patent_holder
				, inn
				, full_name
				, similarity(full_name, x) simi
				, RANK() OVER (PARTITION BY x ORDER BY similarity(full_name, x) DESC) rn
			FROM pure_inn p  
			WHERE 
				p.full_name % x
			LIMIT 5)
		SELECT
			CASE
				WHEN mx_simi != 1  
				THEN inn_agg[1]::varchar
				ELSE substring (inn_agg::varchar FROM 2 FOR (length(inn_agg::varchar) - 2))
			END res 
			, full_name 
		INTO o_inn, o_full_name 	
		FROM (
			SELECT 
				max(simi) mx_simi 	
				, max(full_name) full_name 
				, array_agg(inn) inn_agg
			FROM sub
			WHERE 
				sub.rn = 1
			GROUP BY patent_holder
		)sub2;
	
		IF FOUND THEN 
			/*
			 * Добавляем в таблицу запросов при результативном поиске  
			 */
			SELECT 
				COALESCE(CASE
					WHEN length(i_reg_num::varchar) = '7'
					THEN 1 -- изобретение
					ELSE CASE substring(i_application_num::varchar, 5,1)
							WHEN '1' 
							THEN 2 -- полезная модель
							WHEN '5'
							THEN 3 -- промышленный образец
						END 
				END, i_patent_type) patent_type 
			INTO v_patent_type;
			
			
			INSERT INTO patent_request (reg_number, application_num, y, inn, patent_type, is_actual, upload_ident,author, model_name )
			VALUES (i_reg_num
					,i_application_num
					,CASE WHEN i_patent_str_dt IS NULL 
						THEN EXTRACT (YEAR FROM current_date )
						ELSE LEFT(i_patent_str_dt::varchar, 4)::int2
					END
					, o_inn
					, v_patent_type
					, i_allow
					, upload_id
					, i_author
					, i_invention)
			RETURNING id INTO o_id;
		
		END IF;
		END LOOP; 
	END IF; 
END
$func$
