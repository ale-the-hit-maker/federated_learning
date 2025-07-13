-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- Populate cdm_observation table
--
-- Dependencies: run after
--      lk_observation
--      lk_procedure
--      lk_meas_chartevents
--      lk_cond_diagnoses
--      cdm_person.sql
--      cdm_visit_occurrence
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- cdm_observation
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_observation;
CREATE TABLE @etl_database.@etl_schema.cdm_observation
(
    observation_id                BIGINT    NOT NULL ,
    person_id                     BIGINT    NOT NULL ,
    observation_concept_id        BIGINT    NOT NULL ,
    observation_date              DATE      NOT NULL ,
    observation_datetime          TIMESTAMP          ,
    observation_type_concept_id   BIGINT    NOT NULL ,
    value_as_number               DOUBLE PRECISION   ,
    value_as_string               TEXT               ,
    value_as_concept_id           BIGINT             ,
    qualifier_concept_id          BIGINT             ,
    unit_concept_id               BIGINT             ,
    provider_id                   BIGINT             ,
    visit_occurrence_id           BIGINT             ,
    visit_detail_id               BIGINT             ,
    observation_source_value      TEXT               ,
    observation_source_concept_id BIGINT             ,
    unit_source_value             TEXT               ,
    qualifier_source_value        TEXT               ,
    --
    unit_id                       TEXT,
    load_table_id                 TEXT,
    load_row_id                   BIGINT,
    trace_id                      TEXT
);

-- -------------------------------------------------------------------
-- Rules 1-4
-- lk_observation_mapped (demographics and DRG codes)
-- -------------------------------------------------------------------

INSERT INTO @etl_database.@etl_schema.cdm_observation
SELECT
    EXTRACT(EPOCH FROM NOW())::BIGINT * 1000000 + ROW_NUMBER() OVER ()  AS observation_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS observation_concept_id,
    src.start_datetime::DATE                    AS observation_date,
    src.start_datetime                          AS observation_datetime,
    src.type_concept_id                         AS observation_type_concept_id,
    NULL::FLOAT8                                AS value_as_number,
    src.value_as_string                         AS value_as_string,
    CASE WHEN src.value_as_string IS NOT NULL THEN
        COALESCE(src.value_as_concept_id, 0)
        ELSE NULL
    END                                         AS value_as_concept_id,
    NULL::BIGINT                                AS qualifier_concept_id,
    NULL::BIGINT                                AS unit_concept_id,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS observation_source_value,
    src.source_concept_id                       AS observation_source_concept_id,
    NULL::TEXT                                  AS unit_source_value,
    NULL::TEXT                                  AS qualifier_source_value,
    --
    CONCAT('observation.', src.unit_id)         AS unit_id,
    src.load_table_id                           AS load_table_id,
    src.load_row_id                             AS load_row_id,
    src.trace_id                                AS trace_id
FROM
    @etl_database.@etl_schema.lk_observation_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON  vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|', src.hadm_id::TEXT)
WHERE
    src.target_domain_id = 'Observation'
;

-- -------------------------------------------------------------------
-- Rule 5
-- chartevents
-- -------------------------------------------------------------------

INSERT INTO @etl_database.@etl_schema.cdm_observation
SELECT
    src.measurement_id                          AS observation_id, -- id is generated already
    per.person_id                               AS person_id,
    src.target_concept_id                       AS observation_concept_id,
    src.start_datetime::DATE                    AS observation_date,
    src.start_datetime                          AS observation_datetime,
    src.type_concept_id                         AS observation_type_concept_id,
    src.value_as_number                         AS value_as_number,
    src.value_source_value                      AS value_as_string,
    CASE WHEN src.value_source_value IS NOT NULL THEN
        COALESCE(src.value_as_concept_id, 0)
        ELSE NULL
    END                                         AS value_as_concept_id,
    NULL::BIGINT                                AS qualifier_concept_id,
    src.unit_concept_id                         AS unit_concept_id,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS observation_source_value,
    src.source_concept_id                       AS observation_source_concept_id,
    src.unit_source_value                       AS unit_source_value,
    NULL::TEXT                                  AS qualifier_source_value,
    --
    CONCAT('observation.', src.unit_id)         AS unit_id,
    src.load_table_id                           AS load_table_id,
    src.load_row_id                             AS load_row_id,
    src.trace_id                                AS trace_id
FROM
    @etl_database.@etl_schema.lk_chartevents_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON  vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|', src.hadm_id::TEXT)
WHERE
    src.target_domain_id = 'Observation'
;

-- -------------------------------------------------------------------
-- Rule 6
-- lk_procedure_mapped
-- -------------------------------------------------------------------

INSERT INTO @etl_database.@etl_schema.cdm_observation
SELECT
    EXTRACT(EPOCH FROM NOW())::BIGINT * 1000000 + ROW_NUMBER() OVER ()  AS observation_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS observation_concept_id,
    src.start_datetime::DATE                    AS observation_date,
    src.start_datetime                          AS observation_datetime,
    src.type_concept_id                         AS observation_type_concept_id,
    NULL::FLOAT8                                AS value_as_number,
    NULL::TEXT                                  AS value_as_string,
    NULL::BIGINT                                AS value_as_concept_id,
    NULL::BIGINT                                AS qualifier_concept_id,
    NULL::BIGINT                                AS unit_concept_id,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS observation_source_value,
    src.source_concept_id                       AS observation_source_concept_id,
    NULL::TEXT                                  AS unit_source_value,
    NULL::TEXT                                  AS qualifier_source_value,
    --
    CONCAT('observation.', src.unit_id)         AS unit_id,
    src.load_table_id                           AS load_table_id,
    src.load_row_id                             AS load_row_id,
    src.trace_id                                AS trace_id
FROM
    @etl_database.@etl_schema.lk_procedure_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON  vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|', src.hadm_id::TEXT)
WHERE
    src.target_domain_id = 'Observation'
;

-- -------------------------------------------------------------------
-- Rule 7
-- diagnoses
-- -------------------------------------------------------------------

INSERT INTO @etl_database.@etl_schema.cdm_observation
SELECT
    EXTRACT(EPOCH FROM NOW())::BIGINT * 1000000 + ROW_NUMBER() OVER ()  AS observation_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS observation_concept_id, -- to rename fields in *_mapped
    src.start_datetime::DATE                    AS observation_date,
    src.start_datetime                          AS observation_datetime,
    src.type_concept_id                         AS observation_type_concept_id,
    NULL::FLOAT8                                AS value_as_number,
    NULL::TEXT                                  AS value_as_string,
    NULL::BIGINT                                AS value_as_concept_id,
    NULL::BIGINT                                AS qualifier_concept_id,
    NULL::BIGINT                                AS unit_concept_id,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS observation_source_value,
    src.source_concept_id                       AS observation_source_concept_id,
    NULL::TEXT                                  AS unit_source_value,
    NULL::TEXT                                  AS qualifier_source_value,
    --
    CONCAT('observation.', src.unit_id)         AS unit_id,
    src.load_table_id                           AS load_table_id,
    src.load_row_id                             AS load_row_id,
    src.trace_id                                AS trace_id
FROM
    @etl_database.@etl_schema.lk_diagnoses_icd_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON  vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|', src.hadm_id::TEXT)
WHERE
    src.target_domain_id = 'Observation'
;

-- -------------------------------------------------------------------
-- Rule 8
-- lk_specimen_mapped
-- -------------------------------------------------------------------

INSERT INTO @etl_database.@etl_schema.cdm_observation
SELECT
    EXTRACT(EPOCH FROM NOW())::BIGINT * 1000000 + ROW_NUMBER() OVER ()  AS observation_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS observation_concept_id,
    src.start_datetime::DATE                    AS observation_date,
    src.start_datetime                          AS observation_datetime,
    src.type_concept_id                         AS observation_type_concept_id,
    NULL::FLOAT8                                AS value_as_number,
    NULL::TEXT                                  AS value_as_string,
    NULL::BIGINT                                AS value_as_concept_id,
    NULL::BIGINT                                AS qualifier_concept_id,
    NULL::BIGINT                                AS unit_concept_id,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS observation_source_value,
    src.source_concept_id                       AS observation_source_concept_id,
    NULL::TEXT                                  AS unit_source_value,
    NULL::TEXT                                  AS qualifier_source_value,
    --
    CONCAT('observation.', src.unit_id)         AS unit_id,
    src.load_table_id                           AS load_table_id,
    src.load_row_id                             AS load_row_id,
    src.trace_id                                AS trace_id
FROM
    @etl_database.@etl_schema.lk_specimen_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON  vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|',
                COALESCE(src.hadm_id::TEXT, src.date_id::TEXT))
WHERE
    src.target_domain_id = 'Observation'
;