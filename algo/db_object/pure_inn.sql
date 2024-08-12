-- patent_case.pure_inn definition

-- Drop table

-- DROP TABLE patent_case.pure_inn;

/*
 * Нормализованная таблица для поиска по ИНН
 */

CREATE TABLE patent_case.pure_inn (
	inn int8 NULL,
	full_name text NULL,
	short_name text NULL
);
CREATE INDEX pure_inn_idx ON patent_case.pure_inn USING btree (inn);
CREATE INDEX trgm_inn_name_idx ON patent_case.pure_inn USING gin (full_name patent_case.gin_trgm_ops);