/*
 * Таблица для сохранения запросов
 * При повторном обращении проверяется в первую очередь
 */

DROP TABLE IF EXISTS patent_case.patent_request ;

CREATE TABLE IF NOT EXISTS patent_case.patent_request 
(upload_ident int NOT NULL,
id serial4 PRIMARY KEY,
reg_number int NOT NULL,
application_num int NOT NULL,
y int2 NOT NULL DEFAULT EXTRACT(YEAR FROM current_date), 
patent_type int2,
is_actual int2 NOT NULL DEFAULT 1, 
inn varchar);

COMMENT ON TABLE patent_case.patent_request IS 'Таблица запросов/ответов патентов'; 

COMMENT ON COLUMN patent_case.patent_request.upload_ident IS 'Идентификатор загрузки';
COMMENT ON COLUMN patent_case.patent_request.id IS 'Идентификатор записи';
COMMENT ON COLUMN patent_case.patent_request.reg_number IS 'Регистрационный номер патента';
COMMENT ON COLUMN patent_case.patent_request.application_num IS 'Application номер патента';
COMMENT ON COLUMN patent_case.patent_request.y IS 'Год';
COMMENT ON COLUMN patent_case.patent_request.inn IS 'ИНН патентователя';
COMMENT ON COLUMN patent_case.patent_request.is_actual IS 'Признак актуальности патента 1- актуален, 0-не актуален';
COMMENT ON COLUMN patent_case.patent_request.patent_type IS 'Тип патента. 1-изобретение 2-полез.модель 3-пром.образец';

CREATE INDEX req_inn_idx ON patent_case.patent_request(inn);
CREATE INDEX req_rap_num_idx ON patent_case.patent_request(application_num);

ALTER TABLE patent_request 
ADD COLUMN author varchar,
ADD COLUMN address varchar,
ADD COLUMN model_name varchar,
ADD COLUMN classific varchar;