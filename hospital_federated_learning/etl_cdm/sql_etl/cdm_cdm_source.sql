-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion - PostgreSQL Version
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- Popola la tabella cdm_source
--
-- Dipendenze: nessuna
--      Eseguire alla fine del workflow ETL
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- TRUNCATE TABLE is not supported, organize create or replace -> Fatto, usando DROP/CREATE
--
-- To define source release date as (?) -> Per ora hardcoded come nell'originale
--      SELECT MAX(creation_time)
--      FROM (loop through source datasets).INFORMATION_SCHEMA.TABLES
-- Add second row for Waveform POC?
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_source CASCADE;

CREATE TABLE @etl_database.@etl_schema.cdm_source
(
    cdm_source_name                 VARCHAR(255)    NOT NULL,
    cdm_source_abbreviation         VARCHAR(255),
    cdm_holder                      VARCHAR(255),
    source_description              TEXT,
    source_documentation_reference  VARCHAR(255),
    cdm_etl_reference               VARCHAR(255),
    source_release_date             DATE,
    cdm_release_date                DATE,
    cdm_version                     VARCHAR(50),
    vocabulary_version              VARCHAR(255),
    --
    unit_id                         VARCHAR(255),
    load_table_id                   VARCHAR(255),
    load_row_id                     BIGINT,
    trace_id                        TEXT
);

INSERT INTO @etl_database.@etl_schema.cdm_source
SELECT
    'MIMIC IV'                                                                  AS cdm_source_name,
    'mimiciv'                                                                   AS cdm_source_abbreviation,
    'PhysioNet'                                                                 AS cdm_holder,
    CONCAT('MIMIC-IV is a publicly available database of patients ',
        'admitted to the Beth Israel Deaconess Medical Center in Boston, MA, USA.') AS source_description,
    'https://mimic-iv.mit.edu/docs/'                                            AS source_documentation_reference,
    'https://github.com/OHDSI/MIMIC/'                                           AS cdm_etl_reference,
    '2020-09-01'::DATE                                                          AS source_release_date, -- Funzione BigQuery PARSE_DATE convertita in cast di data standard
    CURRENT_DATE                                                                AS cdm_release_date,    -- Funzione BigQuery CURRENT_DATE() convertita in standard SQL
    '5.3.1'                                                                     AS cdm_version,
    v.vocabulary_version                                                        AS vocabulary_version,
    --
    'cdm.source'                                                                AS unit_id,
    'none'                                                                      AS load_table_id,
    1                                                                           AS load_row_id,
    json_build_object('trace_id', 'mimiciv')::TEXT                              AS trace_id -- Funzione BigQuery TO_JSON_STRING(STRUCT(...)) convertita in PostgreSQL
FROM
    @etl_database.@etl_schema.voc_vocabulary v -- Assumendo che le tabelle voc_* siano nello stesso schema etl
WHERE
    v.vocabulary_id = 'None'
;