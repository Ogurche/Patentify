CREATE OR REPLACE FUNCTION patent_case.find_similarity 
( IN i_patent_holder varchar
, IN i_application_num int
, IN i_reg_num int
, IN i_allow int 
, IN upload_id int
, IN i_patent_str_dt int DEFAULT NULL
, OUT o_inn varchar 
, OUT o_full_name varchar
, OUT o_id int )
LANGUAGE plpgsql
SET SCHEMA 'patent_case'
AS $func$ 
DECLARE 
	
	v_patent_type int2;
	
BEGIN 
	/*
	 * Сначала проверяем повторное использование
	 */
	o_id := NULL; 
	
	PERFORM set_limit(0.75);
	
	SELECT pr.inn, full_name, id
	INTO o_inn , o_full_name, o_id
	FROM patent_case.patent_request pr
	JOIN pure_inn itr 
		ON itr.inn::varchar = ANY(string_to_array(pr.inn , ',')) 
	WHERE 
		application_num = i_application_num
	LIMIT 1;
	
	IF NOT FOUND THEN	
	/*
	 * Проверяем pure_inn на наличие совпадений 
	 * выдаем топ-1 по сходству 
	 * если несколько записей, нужно выдать массив c иннками
	 */
		WITH sub AS (
			SELECT
				i_patent_holder AS patent_holder
				, inn
				, full_name
				, similarity(full_name, i_patent_holder) simi
				, RANK() OVER (PARTITION BY i_patent_holder ORDER BY similarity(full_name, i_patent_holder) DESC) rn
			FROM pure_inn p  
			WHERE 
				p.full_name % i_patent_holder
			LIMIT 10)
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
				CASE
					WHEN length(i_reg_num::varchar) = '7'
					THEN 1 -- изобретение
					ELSE CASE substring(i_application_num::varchar, 5,1)
							WHEN '1' 
							THEN 2 -- полезная модель
							WHEN '5'
							THEN 3 -- промышленный образец
						END 
				END patent_type 
			INTO v_patent_type;
			
			
			INSERT INTO patent_request (reg_number, application_num, y, inn, patent_type, is_actual, upload_ident)
			VALUES (i_reg_num
					,i_application_num
					,CASE WHEN i_patent_str_dt IS NULL 
						THEN EXTRACT (YEAR FROM current_date )
						ELSE LEFT(i_patent_str_dt::varchar, 4)::int2
					END
					, o_inn
					, v_patent_type
					, i_allow
					, upload_id )
			RETURNING id INTO o_id;
		
		END IF;
		
	END IF; 
END
$func$