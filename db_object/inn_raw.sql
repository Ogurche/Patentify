-- patent_case.inn_tbl_raw definition

-- Drop table

-- DROP TABLE patent_case.inn_tbl_raw;
/*
 * Таблица с сырыми данными по ИНН 
 */


CREATE TABLE patent_case.inn_tbl_raw (
	"ID компании" int8 NULL,
	"Наименование полное" text NULL,
	"Наименование краткое" text NULL,
	"ИНН" text NULL,
	"Юр адрес" text NULL,
	"Факт адрес" text NULL,
	"ОГРН" text NULL,
	"Головная компания (1) или филиал (0)" int8 NULL,
	"КПП" text NULL,
	"ОКОПФ (код)" text NULL,
	"ОКОПФ (расшифровка)" text NULL,
	"ОКВЭД2" text NULL,
	"ОКВЭД2 расшифровка" text NULL,
	"Дата создания" text NULL,
	"статус по ЕГРЮЛ " text NULL,
	"ОКФС код" text NULL,
	"ОКФС (форма собственности)" text NULL,
	"Компания действующая (1) или нет (0)" float8 NULL,
	"id Компании-наследника (реорганиза" text NULL,
	"телефоны СПАРК" text NULL,
	"почта СПАРК" text NULL,
	"Сайты" text NULL,
	"ФИО директора" text NULL,
	"Название должности" text NULL,
	"доп. ОКВЭД2" text NULL
);
CREATE INDEX raw_inn_idx ON patent_case.inn_tbl_raw USING btree ("ИНН");