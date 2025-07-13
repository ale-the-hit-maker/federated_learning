-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion - PostgreSQL Version
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- Populate cdm_measurement table
--
-- Dependencies: run after
--      cdm_person.sql,
--      cdm_visit_occurrence,
--      cdm_visit_detail,
--          lk_meas_labevents.sql,
--          lk_meas_chartevents,
--          lk_meas_specimen,
--          lk_meas_waveform.sql
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- src_labevents: look closer to fields priority and specimen_id
-- src_labevents.value:
--      investigate if there are formatted values with thousand separators,
--      and if we need to use more complicated parsing.
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_measurement;

CREATE TABLE @etl_database.@etl_schema.cdm_measurement
(
    measurement_id                BIGINT    NOT NULL,
    person_id                     BIGINT    NOT NULL,
    measurement_concept_id        BIGINT    NOT NULL,
    measurement_date              DATE      NOT NULL,
    measurement_datetime          TIMESTAMP,
    measurement_time              TEXT,
    measurement_type_concept_id   BIGINT    NOT NULL,
    operator_concept_id           BIGINT,
    value_as_number               DOUBLE PRECISION,
    value_as_concept_id           BIGINT,
    unit_concept_id               BIGINT,
    range_low                     DOUBLE PRECISION,
    range_high                    DOUBLE PRECISION,
    provider_id                   BIGINT,
    visit_occurrence_id           BIGINT,
    visit_detail_id               BIGINT,
    measurement_source_value      TEXT,
    measurement_source_concept_id BIGINT,
    unit_source_value             TEXT,
    value_source_value            TEXT,
    unit_id                       TEXT,
    load_table_id                 TEXT,
    load_row_id                   BIGINT,
    trace_id                      TEXT
);

-- -------------------------------------------------------------------
-- Rule 1
-- LABS from labevents
-- demo:  115,272 rows from mapped 107,209 rows. Remove duplicates
-- -------------------------------------------------------------------

INSERT INTO @etl_database.@etl_schema.cdm_measurement
SELECT
    src.measurement_id                      AS measurement_id,
    per.person_id                           AS person_id,
    COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
    src.start_datetime::DATE                AS measurement_date,
    src.start_datetime                      AS measurement_datetime,
    NULL::TEXT                           AS measurement_time,
    32856                                   AS measurement_type_concept_id, -- OMOP4976929 Lab
    src.operator_concept_id                 AS operator_concept_id,
    src.value_as_number::DOUBLE PRECISION  AS value_as_number,
    NULL::BIGINT                            AS value_as_concept_id,
    src.unit_concept_id                     AS unit_concept_id,
    src.range_low                           AS range_low,
    src.range_high                          AS range_high,
    NULL::BIGINT                            AS provider_id,
    vis.visit_occurrence_id                 AS visit_occurrence_id,
    NULL::BIGINT                            AS visit_detail_id,
    src.source_code                         AS measurement_source_value,
    src.source_concept_id                   AS measurement_source_concept_id,
    src.unit_source_value                   AS unit_source_value,
    src.value_source_value                  AS value_source_value,
    CONCAT('measurement.', src.unit_id)     AS unit_id,
    src.load_table_id                       AS load_table_id,
    src.load_row_id                         AS load_row_id,
    src.trace_id                            AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_labevents_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|',
                COALESCE(src.hadm_id::TEXT, src.date_id::TEXT))
WHERE
    src.target_domain_id = 'Measurement'
;


INSERT INTO @etl_database.@etl_schema.cdm_measurement
SELECT
    src.measurement_id                      AS measurement_id,
    per.person_id                           AS person_id,
    COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
    src.start_datetime::DATE                AS measurement_date,
    src.start_datetime                      AS measurement_datetime,
    NULL::TEXT                           AS measurement_time,
    src.type_concept_id                     AS measurement_type_concept_id,
    NULL::BIGINT                            AS operator_concept_id,
    src.value_as_number                     AS value_as_number,
    src.value_as_concept_id                 AS value_as_concept_id,
    src.unit_concept_id                     AS unit_concept_id,
    NULL::DOUBLE PRECISION                  AS range_low,
    NULL::DOUBLE PRECISION                  AS range_high,
    NULL::BIGINT                            AS provider_id,
    vis.visit_occurrence_id                 AS visit_occurrence_id,
    NULL::BIGINT                            AS visit_detail_id,
    src.source_code                         AS measurement_source_value,
    src.source_concept_id                   AS measurement_source_concept_id,
    src.unit_source_value                   AS unit_source_value,
    src.value_source_value                  AS value_source_value,
    CONCAT('measurement.', src.unit_id)     AS unit_id,
    src.load_table_id                       AS load_table_id,
    src.load_row_id                         AS load_row_id,
    src.trace_id                            AS trace_id
FROM
    @etl_database.@etl_schema.lk_chartevents_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|', src.hadm_id::TEXT)
WHERE
    src.target_domain_id = 'Measurement'
;


INSERT INTO @etl_database.@etl_schema.cdm_measurement
SELECT
    src.measurement_id                      AS measurement_id,
    per.person_id                           AS person_id,
    COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
    src.start_datetime::DATE                AS measurement_date,
    src.start_datetime                      AS measurement_datetime,
    NULL::TEXT                           AS measurement_time,
    src.type_concept_id                     AS measurement_type_concept_id,
    NULL::BIGINT                            AS operator_concept_id,
    NULL::DOUBLE PRECISION                  AS value_as_number,
    COALESCE(src.value_as_concept_id, 0)    AS value_as_concept_id,
    NULL::BIGINT                            AS unit_concept_id,
    NULL::DOUBLE PRECISION                  AS range_low,
    NULL::DOUBLE PRECISION                  AS range_high,
    NULL::BIGINT                            AS provider_id,
    vis.visit_occurrence_id                 AS visit_occurrence_id,
    NULL::BIGINT                            AS visit_detail_id,
    src.source_code                         AS measurement_source_value,
    src.source_concept_id                   AS measurement_source_concept_id,
    NULL::TEXT                           AS unit_source_value,
    src.value_source_value                  AS value_source_value,
    CONCAT('measurement.', src.unit_id)     AS unit_id,
    src.load_table_id                       AS load_table_id,
    src.load_row_id                         AS load_row_id,
    src.trace_id                            AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_organism_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|',
                COALESCE(src.hadm_id::TEXT, src.date_id::TEXT))
WHERE
    src.target_domain_id = 'Measurement'
;

INSERT INTO @etl_database.@etl_schema.cdm_measurement
SELECT
    src.measurement_id                      AS measurement_id,
    per.person_id                           AS person_id,
    COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
    src.start_datetime::DATE                AS measurement_date,
    src.start_datetime                      AS measurement_datetime,
    NULL::TEXT                           AS measurement_time,
    src.type_concept_id                     AS measurement_type_concept_id,
    src.operator_concept_id                 AS operator_concept_id,
    src.value_as_number                     AS value_as_number,
    COALESCE(src.value_as_concept_id, 0)    AS value_as_concept_id,
    NULL::BIGINT                            AS unit_concept_id,
    NULL::DOUBLE PRECISION                  AS range_low,
    NULL::DOUBLE PRECISION                  AS range_high,
    NULL::BIGINT                            AS provider_id,
    vis.visit_occurrence_id                 AS visit_occurrence_id,
    NULL::BIGINT                            AS visit_detail_id,
    src.source_code                         AS measurement_source_value,
    src.source_concept_id                   AS measurement_source_concept_id,
    NULL::TEXT                           AS unit_source_value,
    src.value_source_value                  AS value_source_value,
    CONCAT('measurement.', src.unit_id)     AS unit_id,
    src.load_table_id                       AS load_table_id,
    src.load_row_id                         AS load_row_id,
    src.trace_id                            AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_ab_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|',
                COALESCE(src.hadm_id::TEXT, src.date_id::TEXT))
WHERE
    src.target_domain_id = 'Measurement'
;


INSERT INTO @etl_database.@etl_schema.cdm_measurement
SELECT
    ABS(HASHTEXT(gen_random_uuid()::TEXT))  AS measurement_id,
    per.person_id                           AS person_id,
    COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
    src.start_datetime::DATE                AS measurement_date,
    src.start_datetime                      AS measurement_datetime,
    NULL::TEXT                           AS measurement_time,
    32817                                   AS measurement_type_concept_id,
    NULL::BIGINT                            AS operator_concept_id,
    src.value_as_number                     AS value_as_number,
    NULL::BIGINT                            AS value_as_concept_id,
    src.unit_concept_id                     AS unit_concept_id,
    NULL::DOUBLE PRECISION                  AS range_low,
    NULL::DOUBLE PRECISION                  AS range_high,
    NULL::BIGINT                            AS provider_id,
    vd.visit_occurrence_id                  AS visit_occurrence_id,
    vd.visit_detail_id                      AS visit_detail_id,
    CONCAT(src.source_code)                 AS measurement_source_value,
    src.source_concept_id                   AS measurement_source_concept_id,
    src.unit_source_value                   AS unit_source_value,
    src.value_as_number::TEXT            AS value_source_value,
    CONCAT('measurement.', src.unit_id)     AS unit_id,
    src.load_table_id                       AS load_table_id,
    src.load_row_id                         AS load_row_id,
    src.trace_id                            AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_waveform_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_detail vd
        ON src.reference_id = vd.visit_detail_source_value
WHERE
    src.target_domain_id = 'Measurement'
;


INSERT INTO @etl_database.@etl_schema.cdm_measurement
SELECT
    src.measurement_id                      AS measurement_id,
    per.person_id                           AS person_id,
    COALESCE(src.target_concept_id, 0)      AS measurement_concept_id,
    src.start_datetime::DATE                AS measurement_date,
    src.start_datetime                      AS measurement_datetime,
    NULL::TEXT                           AS measurement_time,
    src.type_concept_id                     AS measurement_type_concept_id,
    NULL::BIGINT                            AS operator_concept_id,
    src.value_as_number                     AS value_as_number,
    COALESCE(src.value_as_concept_id, 0)    AS value_as_concept_id,
    NULL::BIGINT                            AS unit_concept_id,
    NULL::DOUBLE PRECISION                  AS range_low,
    NULL::DOUBLE PRECISION                  AS range_high,
    NULL::BIGINT                            AS provider_id,
    vis.visit_occurrence_id                 AS visit_occurrence_id,
    NULL::BIGINT                            AS visit_detail_id,
    src.source_code                         AS measurement_source_value,
    src.source_concept_id                   AS measurement_source_concept_id,
    src.unit_source_value                   AS unit_source_value,
    src.value_source_value                  AS value_source_value,
    CONCAT('measurement.', src.unit_id)     AS unit_id,
    src.load_table_id                       AS load_table_id,
    src.load_row_id                         AS load_row_id,
    src.trace_id                            AS trace_id
FROM
    @etl_database.@etl_schema.lk_outputevents_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|', src.hadm_id::TEXT)
;