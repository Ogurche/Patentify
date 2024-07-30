CREATE OR REPLACE FUNCTION inn_matching.valid_patent
( IN i_patent_holder varchar
, IN i_patent_str_dt int DEFAULT NULL
, OUT fraud bool)
LANGUAGE plpgsql
SET SCHEMA 'inn_matching'
AS $func$ 
BEGIN
	SELECT 
		CASE 
			WHEN i_patent_holder ILIKE  '%общество%'
				 or i_patent_holder ILIKE  '%учреждение%'
				 or i_patent_holder ILIKE  '%предприятие%'
				 or i_patent_holder ILIKE  '%институт%'
				 or i_patent_holder ILIKE  '%БЮРО%'
				 or i_patent_holder ILIKE  '%университет%'
				 or i_patent_holder ILIKE  '%фирма%'
				 or i_patent_holder ILIKE  '%корпораци%'
				 or i_patent_holder ILIKE  '%ООО%'
				 or i_patent_holder ILIKE  '%Фонд%'
				 or i_patent_holder ILIKE  '%центр%'
				 or i_patent_holder ILIKE  '%ВОЙСКОВАЯ ЧАСТЬ%'
				 or i_patent_holder ILIKE  '%Федеральное%'
				 or i_patent_holder ILIKE  '%интситут%'
				 or i_patent_holder ILIKE  '%Российской%'
				 or i_patent_holder ILIKE  '%ОАО%'
				 or i_patent_holder ILIKE  '%НИИ%'
				 or i_patent_holder ILIKE  '%Государственное%'
				 or i_patent_holder ILIKE  '%компания%'
				 or i_patent_holder ILIKE  '%отделение%'
				 or i_patent_holder ILIKE  '%партнерство%'
				 or i_patent_holder ILIKE  '%НИИ%'
				 or i_patent_holder ILIKE  '%завод%'
				 or i_patent_holder ILIKE  '%лаборатория%'
				 or i_patent_holder ILIKE  '%больница%'
				 or i_patent_holder ILIKE  '%Товарищество%'
				 or i_patent_holder ILIKE  '%Ассоциация%'
				 or i_patent_holder ILIKE  '%АО%'
				 or i_patent_holder ILIKE  '%академия%'
				 or i_patent_holder ILIKE  '%коллегия%'
				 or i_patent_holder ILIKE  '%Министерство%'
				 or i_patent_holder ILIKE  '%организация%'
				 or i_patent_holder ILIKE  '%Федерация%'
				 or i_patent_holder ILIKE  '%производственный%'
				 or i_patent_holder ILIKE  '%АО%'
				 or i_patent_holder ILIKE  '%научно-%'
				 or i_patent_holder ILIKE  '%училище%'
				 or i_patent_holder ILIKE  '%комбинат%'
				 or i_patent_holder ILIKE  '%объединение%'
				 or i_patent_holder ILIKE  '%комитет%'
				 or i_patent_holder ILIKE  '%акционерный%'
				 or i_patent_holder ILIKE  '%ансамбль%'
				 or i_patent_holder ILIKE  '%Журнал%'
				 or i_patent_holder ILIKE  '%Министерств%'
				 or i_patent_holder ILIKE  '%производственно-%'
				 or i_patent_holder ILIKE  '%управление%'
				 or i_patent_holder ILIKE  '%Республиканский%'
				 or i_patent_holder ILIKE  '%Управления%'
				 or i_patent_holder ILIKE  '%ансабль%'
				 or i_patent_holder ILIKE  '%Кооператив%'
				 or i_patent_holder ILIKE  '%электростанция%'
				 or i_patent_holder ILIKE  '%коммерческий банк%'
				 or i_patent_holder ILIKE  '%фабрика%'
				 or i_patent_holder ILIKE  '%Совхоз%'
				 or i_patent_holder ILIKE  '%клуб%'
				 or i_patent_holder ILIKE  '%движение%'
				 or i_patent_holder ILIKE  '%монастырь%'
				 or i_patent_holder ILIKE  '%отряд%'
				 or i_patent_holder ILIKE  '%депо%'
				 or i_patent_holder ILIKE  '%Товариществоо%'
				 or i_patent_holder ILIKE  '%Общество%'
				 or i_patent_holder ILIKE  '%Департамент%'
				 OR i_patent_holder ILIKE  '%ИП%'
				 OR i_patent_holder ILIKE '%предприниматель%'
			THEN TRUE 
			ELSE FALSE
		END
	INTO fraud;

	EXCEPTION WHEN OTHERS THEN 
	NULL;
END;

$func$