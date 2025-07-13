-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- Populate cdm_device_exposure table
--
-- Dependencies: run after
--      lk_drug_prescriptions.sql
--      lk_meas_chartevents.sql
--      cdm_person.sql
--      cdm_visit_occurrence.sql
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- TRUNCATE TABLE is not supported, organize create or replace
--
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- cdm_device_exposure
-- Rule 1 lk_drug_mapped
-- -------------------------------------------------------------------

--HINT DISTRIBUTE_ON_KEY(person_id)
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_device_exposure;
CREATE TABLE @etl_database.@etl_schema.cdm_device_exposure
(
    device_exposure_id              BIGINT      NOT NULL ,
    person_id                       BIGINT      NOT NULL ,
    device_concept_id               BIGINT      NOT NULL ,
    device_exposure_start_date      DATE        NOT NULL ,
    device_exposure_start_datetime  TIMESTAMP            ,
    device_exposure_end_date        DATE                 ,
    device_exposure_end_datetime    TIMESTAMP            ,
    device_type_concept_id          BIGINT      NOT NULL ,
    unique_device_id                TEXT                 ,
    quantity                        BIGINT               ,
    provider_id                     BIGINT               ,
    visit_occurrence_id             BIGINT               ,
    visit_detail_id                 BIGINT               ,
    device_source_value             TEXT                 ,
    device_source_concept_id        BIGINT               ,
    --
    unit_id                         TEXT,
    load_table_id                   TEXT,
    load_row_id                     BIGINT,
    trace_id                        TEXT
);


INSERT INTO @etl_database.@etl_schema.cdm_device_exposure
SELECT
    ABS(HASHTEXT(gen_random_uuid()::TEXT))      AS device_exposure_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS device_concept_id,
    src.start_datetime::DATE                    AS device_exposure_start_date,
    src.start_datetime                          AS device_exposure_start_datetime,
    src.end_datetime::DATE                      AS device_exposure_end_date,
    src.end_datetime                            AS device_exposure_end_datetime,
    src.type_concept_id                         AS device_type_concept_id,
    NULL::TEXT                                  AS unique_device_id,
    CASE
        WHEN ROUND(src.quantity) = src.quantity THEN src.quantity::BIGINT
        ELSE NULL
    END                                         AS quantity,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS device_source_value,
    src.source_concept_id                       AS device_source_concept_id,
    --
    CONCAT('device.', src.unit_id)              AS unit_id,
    src.load_table_id                           AS load_table_id,
    src.load_row_id                             AS load_row_id,
    src.trace_id                                AS trace_id
FROM
    @etl_database.@etl_schema.lk_drug_mapped src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON  vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|', src.hadm_id::TEXT)
WHERE
    src.target_domain_id = 'Device'
;


INSERT INTO @etl_database.@etl_schema.cdm_device_exposure
SELECT
    ABS(HASHTEXT(gen_random_uuid()::TEXT))      AS device_exposure_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS device_concept_id,
    src.start_datetime::DATE                    AS device_exposure_start_date,
    src.start_datetime                          AS device_exposure_start_datetime,
    src.start_datetime::DATE                    AS device_exposure_end_date,
    src.start_datetime                          AS device_exposure_end_datetime,
    src.type_concept_id                         AS device_type_concept_id,
    NULL::TEXT                                  AS unique_device_id,
    CASE
        WHEN ROUND(src.value_as_number) = src.value_as_number THEN src.value_as_number::BIGINT
        ELSE NULL
    END                                         AS quantity,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS device_source_value,
    src.source_concept_id                       AS device_source_concept_id,
    --
    CONCAT('device.', src.unit_id)              AS unit_id,
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
    src.target_domain_id = 'Device'
;

-- Note: Uses hashtext(gen_random_uuid()) to generate random integer IDs