CREATE OR REPLACE FUNCTION analytics_by_all_patent ()
RETURNS TABLE (patent_types varchar,num_of_patent_by_type int,num_of_actual int,num_of_not_actual int, classific varchar)
SET SCHEMA 'patent_case'
LANGUAGE SQL
AS $act$
	SELECT 
		CASE patent_type 
			WHEN 1
			THEN 'Изобретение'
			WHEN 2
			THEN 'Полезная модель'
			WHEN 3
			THEN 'Промышленные образцы'
			ELSE 'Не удалось определить'
		END patent_types
		, COUNT (*) AS num_of_patent_by_type
		, sum(is_actual) AS num_of_actual
		, COunt(*) - sum(is_actual) AS num_of_not_actual
		, classific
	FROM patent_request pr 
	GROUP BY patent_type, classific; 
$act$;	