-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Populate cdm_visit_detail table
--
-- Dependencies: run after
--      st_core.sql,
--      st_hosp.sql,
--      st_waveform.sql,
--      lk_vis_adm_transfers.sql,
--      cdm_person.sql,
--      cdm_visit_occurrence.sql
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- TRUNCATE TABLE is not supported, organize create or replace
-- negative unique id from FARM_FINGERPRINT(GENERATE_UUID())
--
-- src.callout - is there any derived table in MIMIC IV?
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- cdm_visit_detail
-- -------------------------------------------------------------------

-- Drop table if exists and create new one
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_visit_detail CASCADE;

CREATE TABLE @etl_database.@etl_schema.cdm_visit_detail
(
    visit_detail_id                    BIGINT    NOT NULL ,
    person_id                          BIGINT    NOT NULL ,
    visit_detail_concept_id            BIGINT    NOT NULL ,
    visit_detail_start_date            DATE      NOT NULL ,
    visit_detail_start_datetime        TIMESTAMP          ,
    visit_detail_end_date              DATE      NOT NULL ,
    visit_detail_end_datetime          TIMESTAMP          ,
    visit_detail_type_concept_id       BIGINT    NOT NULL , -- detail! -- this typo still exists in v.5.3.1(???)
    provider_id                        BIGINT             ,
    care_site_id                       BIGINT             ,
    admitting_source_concept_id        BIGINT             ,
    discharge_to_concept_id            BIGINT             ,
    preceding_visit_detail_id          BIGINT             ,
    visit_detail_source_value          VARCHAR(255)       ,
    visit_detail_source_concept_id     BIGINT             , -- detail! -- this typo still exists in v.5.3.1(???)
    admitting_source_value             VARCHAR(255)       ,
    discharge_to_source_value          VARCHAR(255)       ,
    visit_detail_parent_id             BIGINT             ,
    visit_occurrence_id                BIGINT    NOT NULL ,
    --
    unit_id                       VARCHAR(255),
    load_table_id                 VARCHAR(255),
    load_row_id                   BIGINT,
    trace_id                      VARCHAR(255)
);

-- -------------------------------------------------------------------
-- Rule 1. transfers
-- Rule 2. services
-- -------------------------------------------------------------------

INSERT INTO @etl_database.@etl_schema.cdm_visit_detail
SELECT
    src.visit_detail_id                     AS visit_detail_id,
    per.person_id                           AS person_id,
    COALESCE(vdc.target_concept_id, 0)      AS visit_detail_concept_id,
                                            -- see source value in care_site.care_site_source_value
    src.start_datetime::DATE                AS visit_start_date,
    src.start_datetime                      AS visit_start_datetime,
    src.end_datetime::DATE                  AS visit_end_date,
    src.end_datetime                        AS visit_end_datetime,
    32817                                   AS visit_detail_type_concept_id,   -- EHR   Type Concept    Standard
    NULL::BIGINT                            AS provider_id,
    cs.care_site_id                         AS care_site_id,

    CASE
        WHEN src.admission_location IS NOT NULL
        THEN COALESCE(la.target_concept_id, 0)
        ELSE NULL
    END                                     AS admitting_source_concept_id,

    CASE
        WHEN src.discharge_location IS NOT NULL
        THEN COALESCE(ld.target_concept_id, 0)
        ELSE NULL
    END                                     AS discharge_to_concept_id,

    src.preceding_visit_detail_id           AS preceding_visit_detail_id,
    src.source_value                        AS visit_detail_source_value,
    COALESCE(vdc.source_concept_id, 0)      AS visit_detail_source_concept_id,
    src.admission_location                  AS admitting_source_value,
    src.discharge_location                  AS discharge_to_source_value,
    NULL::BIGINT                            AS visit_detail_parent_id,
    vis.visit_occurrence_id                 AS visit_occurrence_id,
    --
    CONCAT('visit_detail.', src.unit_id)    AS unit_id,
    src.load_table_id                       AS load_table_id,
    src.load_row_id                         AS load_row_id,
    src.trace_id                            AS trace_id
FROM
    @etl_database.@etl_schema.lk_visit_detail_prev_next src
INNER JOIN
    @etl_database.@etl_schema.cdm_person per
        ON src.subject_id::TEXT = per.person_source_value
INNER JOIN
    @etl_database.@etl_schema.cdm_visit_occurrence vis
        ON  vis.visit_source_value =
            CONCAT(src.subject_id::TEXT, '|',
                COALESCE(src.hadm_id::TEXT, src.date_id::TEXT))
LEFT JOIN
    @etl_database.@etl_schema.cdm_care_site cs
        ON cs.care_site_source_value = src.current_location
LEFT JOIN
    @etl_database.@etl_schema.lk_visit_concept vdc
        ON vdc.source_code = src.current_location
LEFT JOIN
    @etl_database.@etl_schema.lk_visit_concept la
        ON la.source_code = src.admission_location
LEFT JOIN
    @etl_database.@etl_schema.lk_visit_concept ld
        ON ld.source_code = src.discharge_location
;