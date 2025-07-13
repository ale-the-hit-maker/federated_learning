-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion - PostgreSQL Version
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Populate lookups for cdm_visit_occurrence and cdm_visit_detail
--
-- Dependencies: run after
--      st_core.sql
--      lk_vis_part_1.sql
--      lk_meas_labevents.sql
--      lk_meas_specimen.sql
--      lk_meas_waveform.sql
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- negative unique id from random() function
--
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- lk_visit_no_hadm_all
--
-- collect rows without hadm_id from all tables affected by this case:
--      lk_meas_labevents_mapped
--      lk_meas_organism_mapped
--      lk_meas_ab_mapped
--      lk_meas_waveform_mapped
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_visit_no_hadm_all;
CREATE TABLE @etl_database.@etl_schema.lk_visit_no_hadm_all AS
-- labevents
SELECT
    src.subject_id                                  AS subject_id,
    src.start_datetime::DATE                        AS date_id,
    src.start_datetime                              AS start_datetime,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_labevents_mapped src
WHERE
    src.hadm_id IS NULL
UNION ALL
-- specimen
SELECT
    src.subject_id                                  AS subject_id,
    src.start_datetime::DATE                        AS date_id,
    src.start_datetime                              AS start_datetime,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_specimen_mapped src
WHERE
    src.hadm_id IS NULL
UNION ALL
-- organism
SELECT
    src.subject_id                                  AS subject_id,
    src.start_datetime::DATE                        AS date_id,
    src.start_datetime                              AS start_datetime,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_organism_mapped src
WHERE
    src.hadm_id IS NULL
UNION ALL
-- antibiotics
SELECT
    src.subject_id                                  AS subject_id,
    src.start_datetime::DATE                        AS date_id,
    src.start_datetime                              AS start_datetime,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_ab_mapped src
WHERE
    src.hadm_id IS NULL
UNION ALL
-- waveforms
SELECT
    src.subject_id                                  AS subject_id,
    src.start_datetime::DATE                        AS date_id,
    src.start_datetime                              AS start_datetime,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_waveform_mapped src
WHERE
    src.hadm_id IS NULL
;

-- -------------------------------------------------------------------
-- lk_visit_no_hadm_dist
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_visit_no_hadm_dist;
CREATE TABLE @etl_database.@etl_schema.lk_visit_no_hadm_dist AS
SELECT
    src.subject_id                                  AS subject_id,
    src.date_id                                     AS date_id,
    MIN(src.start_datetime)                         AS start_datetime,
    MAX(src.start_datetime)                         AS end_datetime,
    'AMBULATORY OBSERVATION'                        AS admission_type,
    NULL::TEXT                                      AS admission_location,
    NULL::TEXT                                      AS discharge_location,
    --
    'no_hadm'                       AS unit_id,
    'lk_visit_no_hadm_all'          AS load_table_id,
    0                               AS load_row_id,
    json_build_object(
        'subject_id', src.subject_id,
        'date_id', src.date_id
    )::TEXT                                         AS trace_id
FROM
    @etl_database.@etl_schema.lk_visit_no_hadm_all src
GROUP BY
    src.subject_id,
    src.date_id
;


-- -------------------------------------------------------------------
-- lk_visit_detail_waveform_dist
--
-- collect rows without hadm_id from all tables affected by this case@
--      lk_meas_waveform_mapped
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_visit_detail_waveform_dist;
CREATE TABLE @etl_database.@etl_schema.lk_visit_detail_waveform_dist AS
SELECT
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    MIN(src.start_datetime)::DATE                   AS date_id,
    MIN(src.start_datetime)                         AS start_datetime,
    MAX(src.start_datetime)                         AS end_datetime,
    'AMBULATORY OBSERVATION'                        AS current_location,
    src.reference_id                                AS reference_id,
    --
    'waveforms'                     AS unit_id,
    'lk_meas_waveform_mapped'       AS load_table_id,
    0                               AS load_row_id,
    json_build_object(
        'subject_id', src.subject_id,
        'hadm_id', src.hadm_id,
        'reference_id', src.reference_id
    )::TEXT                                         AS trace_id
FROM
    @etl_database.@etl_schema.lk_meas_waveform_mapped src
GROUP BY
    src.subject_id,
    src.hadm_id,
    src.reference_id
;

-- -------------------------------------------------------------------
-- lk_visit_clean
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_visit_clean;
CREATE TABLE @etl_database.@etl_schema.lk_visit_clean AS
SELECT
    abs(hashtext(gen_random_uuid()::TEXT))::BIGINT  AS visit_occurrence_id,
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    NULL::DATE                                      AS date_id,
    src.start_datetime                              AS start_datetime,
    src.end_datetime                                AS end_datetime,
    src.admission_type                              AS admission_type,
    src.admission_location                          AS admission_location,
    src.discharge_location                          AS discharge_location,
    CONCAT(
        src.subject_id::TEXT, '|',
        src.hadm_id::TEXT
    )                                               AS source_value,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_admissions_clean src
UNION ALL
SELECT
    abs(hashtext(gen_random_uuid()::TEXT))::BIGINT  AS visit_occurrence_id,
    src.subject_id                                  AS subject_id,
    NULL::BIGINT                                    AS hadm_id,
    src.date_id                                     AS date_id,
    src.start_datetime                              AS start_datetime,
    src.end_datetime                                AS end_datetime,
    src.admission_type                              AS admission_type,
    src.admission_location                          AS admission_location,
    src.discharge_location                          AS discharge_location,
    CONCAT(
        src.subject_id::TEXT, '|',
        src.date_id::TEXT
    )                                               AS source_value,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_visit_no_hadm_dist src
;

-- -------------------------------------------------------------------
-- lk_visit_detail_clean
--
-- Rule 1.
-- transfers with valid hadm_id
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_visit_detail_clean;
CREATE TABLE @etl_database.@etl_schema.lk_visit_detail_clean AS
SELECT
    abs(hashtext(gen_random_uuid()::TEXT))::BIGINT  AS visit_detail_id,
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    src.date_id                                     AS date_id,
    src.start_datetime                              AS start_datetime,
    src.end_datetime                                AS end_datetime,
    CONCAT(
        src.subject_id::TEXT, '|',
        COALESCE(src.hadm_id::TEXT, src.date_id::TEXT), '|',
        src.transfer_id::TEXT
    )                                               AS source_value,
    src.current_location                            AS current_location,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_transfers_clean src
WHERE
    src.hadm_id IS NOT NULL
;

-- -------------------------------------------------------------------
-- lk_visit_detail_clean
--
-- Rule 2.
-- ER admissions
-- -------------------------------------------------------------------
INSERT INTO @etl_database.@etl_schema.lk_visit_detail_clean
SELECT
    abs(hashtext(gen_random_uuid()::TEXT))::BIGINT  AS visit_detail_id,
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    src.start_datetime::DATE                        AS date_id,
    src.start_datetime                              AS start_datetime,
    NULL::TIMESTAMP                                 AS end_datetime,
    CONCAT(
        src.subject_id::TEXT, '|',
        src.hadm_id::TEXT
    )                                               AS source_value,
    src.admission_type                              AS current_location,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_admissions_clean src
WHERE
    src.is_er_admission
;

-- -------------------------------------------------------------------
-- lk_visit_detail_clean
--
-- Rule 3.
-- services
-- -------------------------------------------------------------------
INSERT INTO @etl_database.@etl_schema.lk_visit_detail_clean
SELECT
    abs(hashtext(gen_random_uuid()::TEXT))::BIGINT  AS visit_detail_id,
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    src.start_datetime::DATE                        AS date_id,
    src.start_datetime                              AS start_datetime,
    src.end_datetime                                AS end_datetime,
    CONCAT(
        src.subject_id::TEXT, '|',
        src.hadm_id::TEXT, '|',
        src.start_datetime::TEXT
    )                                               AS source_value,
    src.curr_service                                AS current_location,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_services_clean src
WHERE
    src.prev_service = src.lag_service
;

-- -------------------------------------------------------------------
-- lk_visit_detail_clean
--
-- Rule 4.
-- waveforms
-- -------------------------------------------------------------------
INSERT INTO @etl_database.@etl_schema.lk_visit_detail_clean
SELECT
    abs(hashtext(gen_random_uuid()::TEXT))::BIGINT  AS visit_detail_id,
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    src.date_id                                     AS date_id,
    src.start_datetime                              AS start_datetime,
    src.end_datetime                                AS end_datetime,
    src.reference_id                                AS source_value,
    src.current_location                            AS current_location,
    --
    src.unit_id                     AS unit_id,
    src.load_table_id               AS load_table_id,
    src.load_row_id                 AS load_row_id,
    src.trace_id                    AS trace_id
FROM
    @etl_database.@etl_schema.lk_visit_detail_waveform_dist src
;

-- -------------------------------------------------------------------
-- lk_visit_detail_prev_next
-- skip "mapped"
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_visit_detail_prev_next;
CREATE TABLE @etl_database.@etl_schema.lk_visit_detail_prev_next AS
SELECT
    src.visit_detail_id                             AS visit_detail_id,
    src.subject_id                                  AS subject_id,
    src.hadm_id                                     AS hadm_id,
    src.date_id                                     AS date_id,
    src.start_datetime                              AS start_datetime,
    COALESCE(
        src.end_datetime,
        LEAD(src.start_datetime) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id
            ORDER BY src.start_datetime ASC
        ),
        vis.end_datetime
    )                                               AS end_datetime,
    src.source_value                                AS source_value,
    --
    src.current_location                            AS current_location,
    LAG(src.visit_detail_id) OVER (
        PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
        ORDER BY src.start_datetime ASC
    )                                               AS preceding_visit_detail_id,
    COALESCE(
        LAG(src.current_location) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
            ORDER BY src.start_datetime ASC
        ),
        vis.admission_location
    )                                               AS admission_location,
    COALESCE(
        LEAD(src.current_location) OVER (
            PARTITION BY src.subject_id, src.hadm_id, src.date_id, src.unit_id
            ORDER BY src.start_datetime ASC
        ),
        vis.discharge_location
    )                                               AS discharge_location,
    --
    src.unit_id                       AS unit_id,
    src.load_table_id                 AS load_table_id,
    src.load_row_id                   AS load_row_id,
    src.trace_id                      AS trace_id
FROM
    @etl_database.@etl_schema.lk_visit_detail_clean src
LEFT JOIN
    @etl_database.@etl_schema.lk_visit_clean vis
        ON  src.subject_id = vis.subject_id
        AND (
            src.hadm_id = vis.hadm_id
            OR (src.hadm_id IS NULL AND src.date_id = vis.date_id)
        )
;


-- -------------------------------------------------------------------
-- lk_visit_concept
--
-- gcpt_admission_type_to_concept -> mimiciv_vis_admission_type
-- gcpt_admission_location_to_concept -> mimiciv_vis_admission_location
-- gcpt_discharge_location_to_concept -> mimiciv_vis_discharge_location
-- brand new vocabulary -> mimiciv_vis_service
-- gcpt_care_site -> mimiciv_cs_place_of_service
--
-- keep exact values of admission type etc as custom concepts,
-- then map it to standard Visit concepts
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_visit_concept;
CREATE TABLE @etl_database.@etl_schema.lk_visit_concept AS
SELECT
    vc.concept_code     AS source_code,
    vc.concept_id       AS source_concept_id,
    vc2.concept_id      AS target_concept_id,
    vc.vocabulary_id    AS source_vocabulary_id
FROM
    @etl_database.@etl_schema.voc_concept vc
LEFT JOIN
    @etl_database.@etl_schema.voc_concept_relationship vcr
        ON  vc.concept_id = vcr.concept_id_1
        AND vcr.relationship_id = 'Maps to'
LEFT JOIN
    @etl_database.@etl_schema.voc_concept vc2
        ON vc2.concept_id = vcr.concept_id_2
        AND vc2.standard_concept = 'S'
        AND vc2.invalid_reason IS NULL
WHERE
    vc.vocabulary_id IN (
        'mimiciv_vis_admission_location',
        'mimiciv_vis_discharge_location',
        'mimiciv_vis_service',
        'mimiciv_vis_admission_type',
        'mimiciv_cs_place_of_service'
    )
;