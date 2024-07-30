
CREATE TABLE IF NOT EXISTS pure_inn 
TABLESPACE disk_d
AS SELECT 
	inn::int8
	, create_date
	, is_active
	, full_name
	, short_name
	, jud_address
	, fact_address
	FROM (SELECT 
		split_part("инн",'.',1) AS inn 
		, "Дата создания"::date AS create_date
		, "Компания действующая (1) или нет (0)"::NUMERIC::int2  AS is_active
		, lower("Наименование полное") AS full_name
		, lower("Наименование краткое") AS short_name
		, lower("Юр адрес") AS jud_address
		, lower("Факт адрес") AS fact_address
	FROM inn_raw ir )sub
	WHERE inn ~ E'^\\d+$';

-- CREATE EXTENSION pg_trgm;

SELECT * FROM inn_raw;

CREATE INDEX inn_IDX ON inn_matching.pure_inn (inn) TABLESPACE disk_d;
CREATE INDEX trgm_inn_name_idx ON inn_matching.pure_inn USING gin (full_name gin_trgm_ops) TABLESPACE disk_d;
CREATE INDEX trgm_inn_nameshrt_idx ON inn_matching.pure_inn USING gin (short_name gin_trgm_ops) TABLESPACE disk_d;
CREATE INDEX trgm_inn_namejdadr_idx ON inn_matching.pure_inn USING gin (jud_address gin_trgm_ops) TABLESPACE disk_d;
CREATE INDEX trgm_inn_namefadr_idx ON inn_matching.pure_inn USING gin (fact_address gin_trgm_ops) TABLESPACE disk_d;

--
/*
 * Таблица для сохранения запросов
 * При повторном обращении проверяется в первую очередь
 */

DROP TABLE IF EXISTS inn_matching.patent_request ;

CREATE TABLE IF NOT EXISTS inn_matching.patent_request 
(upload_ident int NOT NULL,
id serial4 PRIMARY KEY,
reg_number int NOT NULL,
application_num int NOT NULL,
y int2 NOT NULL DEFAULT EXTRACT(YEAR FROM current_date), 
patent_type int2,
is_actual int2 NOT NULL DEFAULT 1, 
inn varchar)
TABLESPACE disk_d;

COMMENT ON TABLE inn_matching.patent_request IS 'Таблица запросов/ответов патентов'; 

COMMENT ON COLUMN inn_matching.patent_request.upload_ident IS 'Идентификатор загрузки';
COMMENT ON COLUMN inn_matching.patent_request.id IS 'Идентификатор записи';
COMMENT ON COLUMN inn_matching.patent_request.reg_number IS 'Регистрационный номер патента';
COMMENT ON COLUMN inn_matching.patent_request.application_num IS 'Application номер патента';
COMMENT ON COLUMN inn_matching.patent_request.y IS 'Год';
COMMENT ON COLUMN inn_matching.patent_request.inn IS 'ИНН патентователя';
COMMENT ON COLUMN inn_matching.patent_request.is_actual IS 'Признак актуальности патента 1- актуален, 0-не актуален';
COMMENT ON COLUMN inn_matching.patent_request.patent_type IS 'Тип патента. 1-изобретение 2-полез.модель 3-пром.образец';

CREATE INDEX req_inn_idx ON inn_matching.patent_request(inn) TABLESPACE disk_d;
CREATE INDEX req_rap_num_idx ON inn_matching.patent_request(application_num) TABLESPACE disk_d;

ALTER TABLE patent_request 
ADD COLUMN author varchar,
ADD COLUMN address varchar,
ADD COLUMN model_name varchar,
ADD COLUMN classific varchar;

-- Таблица патентов

CREATE TABLE IF NOT EXISTS patent_matching_tbl 
(id serial4 PRIMARY KEY,
reg_num varchar, 
patent_name varchar, 
patent_holder varchar,
address varchar, 
authors varchar, 
inn_handcheck varchar,
p_type varchar)
TABLESPACE disk_d;

UPDATE inn_matching.patent_matching_tbl s
SET inn_handcheck = NULL
WHERE inn_handcheck = 'NULL' OR inn_handcheck = '';

UPDATE inn_matching.patent_matching_tbl s
SET authors = NULL
WHERE authors = 'NULL' OR authors = '';

UPDATE inn_matching.patent_matching_tbl s
SET patent_name = NULL
WHERE patent_name = 'NULL' OR patent_name = '';

UPDATE inn_matching.patent_matching_tbl s
SET address = NULL
WHERE address = 'NULL' OR address = '';
