-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- Populate cdm_drug_exposure table
--
-- Dependencies: run after
--      lk_drug_prescriptions.sql
--      cdm_person.sql,
--      cdm_visit_occurrence.sql
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- TRUNCATE TABLE is not supported, organize create or replace
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- cdm_drug_exposure
-- -------------------------------------------------------------------

--HINT DISTRIBUTE_ON_KEY(person_id)
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_drug_exposure;
CREATE TABLE @etl_database.@etl_schema.cdm_drug_exposure
(
    drug_exposure_id              BIGINT      NOT NULL ,
    person_id                     BIGINT      NOT NULL ,
    drug_concept_id               BIGINT      NOT NULL ,
    drug_exposure_start_date      DATE        NOT NULL ,
    drug_exposure_start_datetime  TIMESTAMP            ,
    drug_exposure_end_date        DATE        NOT NULL ,
    drug_exposure_end_datetime    TIMESTAMP            ,
    verbatim_end_date             DATE                 ,
    drug_type_concept_id          BIGINT      NOT NULL ,
    stop_reason                   TEXT                 ,
    refills                       BIGINT               ,
    quantity                      NUMERIC              ,
    days_supply                   BIGINT               ,
    sig                           TEXT                 ,
    route_concept_id              BIGINT               ,
    lot_number                    TEXT                 ,
    provider_id                   BIGINT               ,
    visit_occurrence_id           BIGINT               ,
    visit_detail_id               BIGINT               ,
    drug_source_value             TEXT                 ,
    drug_source_concept_id        BIGINT               ,
    route_source_value            TEXT                 ,
    dose_unit_source_value        TEXT                 ,
    --
    unit_id                       TEXT,
    load_table_id                 TEXT,
    load_row_id                   BIGINT,
    trace_id                      TEXT
);

INSERT INTO @etl_database.@etl_schema.cdm_drug_exposure
SELECT
    ABS(HASHTEXT(gen_random_uuid()::TEXT))      AS drug_exposure_id,
    per.person_id                               AS person_id,
    src.target_concept_id                       AS drug_concept_id,
    src.start_datetime::DATE                    AS drug_exposure_start_date,
    src.start_datetime                          AS drug_exposure_start_datetime,
    src.end_datetime::DATE                      AS drug_exposure_end_date,
    src.end_datetime                            AS drug_exposure_end_datetime,
    NULL::DATE                                  AS verbatim_end_date,
    src.type_concept_id                         AS drug_type_concept_id,
    NULL::TEXT                                  AS stop_reason,
    NULL::BIGINT                                AS refills,
    src.quantity                                AS quantity,
    NULL::BIGINT                                AS days_supply,
    NULL::TEXT                                  AS sig,
    src.route_concept_id                        AS route_concept_id,
    NULL::TEXT                                  AS lot_number,
    NULL::BIGINT                                AS provider_id,
    vis.visit_occurrence_id                     AS visit_occurrence_id,
    NULL::BIGINT                                AS visit_detail_id,
    src.source_code                             AS drug_source_value,
    src.source_concept_id                       AS drug_source_concept_id,
    src.route_source_code                       AS route_source_value,
    src.dose_unit_source_code                   AS dose_unit_source_value,
    --
    CONCAT('drug.', src.unit_id)                AS unit_id,
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
    src.target_domain_id = 'Drug'
;

-- Note: Uses hashtext(gen_random_uuid()) to generate random integer IDs