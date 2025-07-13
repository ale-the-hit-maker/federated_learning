-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Populate staging tables for cdm dimension tables
--
-- Dependencies: run first after DDL
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- -------------------------------------------------------------------


-- -------------------------------------------------------------------
-- for Condition_occurrence
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- src_diagnoses_icd
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_diagnoses_icd;
CREATE TABLE @etl_database.@etl_schema.src_diagnoses_icd AS
SELECT
    subject_id      AS subject_id,
    hadm_id         AS hadm_id,
    seq_num         AS seq_num,
    icd_code        AS icd_code,
    icd_version     AS icd_version,
    --
    'diagnoses_icd'                     AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'hadm_id', hadm_id,
        'seq_num', seq_num
    )::TEXT                             AS trace_id
FROM
    @source_database.@hosp_schema.diagnoses_icd
;

-- -------------------------------------------------------------------
-- for Measurement
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- src_services
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_services;
CREATE TABLE @etl_database.@etl_schema.src_services AS
SELECT
    subject_id                          AS subject_id,
    hadm_id                             AS hadm_id,
    transfertime                        AS transfertime,
    prev_service                        AS prev_service,
    curr_service                        AS curr_service,
    --
    'services'                          AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'transfertime', transfertime
    )::TEXT                             AS trace_id
FROM
    @source_database.@hosp_schema.services
;

-- -------------------------------------------------------------------
-- src_labevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_labevents;
CREATE TABLE @etl_database.@etl_schema.src_labevents AS
SELECT
    labevent_id                         AS labevent_id,
    subject_id                          AS subject_id,
    charttime                           AS charttime,
    hadm_id                             AS hadm_id,
    itemid                              AS itemid,
    valueuom                            AS valueuom,
    value                               AS value,
    flag                                AS flag,
    ref_range_lower                     AS ref_range_lower,
    ref_range_upper                     AS ref_range_upper,
    --
    'labevents'                         AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'labevent_id', labevent_id
    )::TEXT                             AS trace_id
FROM
    @source_database.@hosp_schema.labevents
;

-- -------------------------------------------------------------------
-- src_d_labitems
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_d_labitems;
CREATE TABLE @etl_database.@etl_schema.src_d_labitems AS
SELECT
    itemid                              AS itemid,
    label                               AS label,
    fluid                               AS fluid,
    category                            AS category,
    CAST(NULL AS TEXT)                  AS loinc_code, -- MIMIC IV 2.0 change, the field is removed
    --
    'd_labitems'                        AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'itemid', itemid
    )::TEXT                             AS trace_id
FROM
    @source_database.@hosp_schema.d_labitems
;


-- -------------------------------------------------------------------
-- for Procedure
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- src_procedures_icd
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_procedures_icd;
CREATE TABLE @etl_database.@etl_schema.src_procedures_icd AS
SELECT
    subject_id                          AS subject_id,
    hadm_id                             AS hadm_id,
    icd_code        AS icd_code,
    icd_version     AS icd_version,
    --
    'procedures_icd'                    AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'icd_code', icd_code,
        'icd_version', icd_version
    )::TEXT                             AS trace_id -- this set of fields is not unique. To set quantity?
FROM
    @source_database.@hosp_schema.procedures_icd
;

-- -------------------------------------------------------------------
-- src_hcpcsevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_hcpcsevents;
CREATE TABLE @etl_database.@etl_schema.src_hcpcsevents AS
SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
    hcpcs_cd                            AS hcpcs_cd,
    seq_num                             AS seq_num,
    short_description                   AS short_description,
    --
    'hcpcsevents'                       AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'hcpcs_cd', hcpcs_cd,
        'seq_num', seq_num
    )::TEXT                             AS trace_id -- this set of fields is not unique. To set quantity?
FROM
    @source_database.@hosp_schema.hcpcsevents
;


-- -------------------------------------------------------------------
-- src_drgcodes
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_drgcodes;
CREATE TABLE @etl_database.@etl_schema.src_drgcodes AS
SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
    drg_code                            AS drg_code,
    description                         AS description,
    --
    'drgcodes'                       AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'drg_code', COALESCE(drg_code, '')
    )::TEXT                             AS trace_id -- this set of fields is not unique.
FROM
    @source_database.@hosp_schema.drgcodes
;

-- -------------------------------------------------------------------
-- src_prescriptions
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_prescriptions;
CREATE TABLE @etl_database.@etl_schema.src_prescriptions AS
SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
    pharmacy_id                         AS pharmacy_id,
    starttime                           AS starttime,
    stoptime                            AS stoptime,
    drug_type                           AS drug_type,
    drug                                AS drug,
    gsn                                 AS gsn,
    ndc                                 AS ndc,
    prod_strength                       AS prod_strength,
    form_rx                             AS form_rx,
    dose_val_rx                         AS dose_val_rx,
    dose_unit_rx                        AS dose_unit_rx,
    form_val_disp                       AS form_val_disp,
    form_unit_disp                      AS form_unit_disp,
    doses_per_24_hrs                    AS doses_per_24_hrs,
    route                               AS route,
    --
    'prescriptions'                     AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'pharmacy_id', pharmacy_id,
        'starttime', starttime
    )::TEXT                             AS trace_id
FROM
    @source_database.@hosp_schema.prescriptions
;


-- -------------------------------------------------------------------
-- src_microbiologyevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_microbiologyevents;
CREATE TABLE @etl_database.@etl_schema.src_microbiologyevents AS
SELECT
    microevent_id               AS microevent_id,
    subject_id                  AS subject_id,
    hadm_id                     AS hadm_id,
    chartdate                   AS chartdate,
    charttime                   AS charttime, -- usage: COALESCE(charttime, chartdate)
    spec_itemid                 AS spec_itemid, -- d_micro, type of specimen taken. If no grouth, then all other fields is null
    spec_type_desc              AS spec_type_desc, -- for reference
    test_itemid                 AS test_itemid, -- d_micro, what test is taken, goes to measurement
    test_name                   AS test_name, -- for reference
    org_itemid                  AS org_itemid, -- d_micro, what bacteria have grown
    org_name                    AS org_name, -- for reference
    ab_itemid                   AS ab_itemid, -- d_micro, antibiotic tested on the bacteria
    ab_name                     AS ab_name, -- for reference
    dilution_comparison         AS dilution_comparison, -- operator sign
    dilution_value              AS dilution_value, -- numeric value
    interpretation              AS interpretation, -- bacteria's degree of resistance to the antibiotic
    --
    'microbiologyevents'                AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'microevent_id', microevent_id
    )::TEXT                             AS trace_id
FROM
    @source_database.@hosp_schema.microbiologyevents
;

-- -------------------------------------------------------------------
-- src_d_micro
-- raw d_micro is no longer available both in mimic_hosp and mimiciv_hosp
-- -------------------------------------------------------------------

-- DROP TABLE IF EXISTS @etl_database.@etl_schema.src_d_micro;
-- CREATE TABLE @etl_database.@etl_schema.src_d_micro AS
-- SELECT
--     itemid                      AS itemid, -- numeric ID
--     label                       AS label, -- source_code for custom mapping
--     category                    AS category,
--     --
--     'd_micro'                   AS load_table_id,
--     ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
--     JSON_BUILD_OBJECT(
--         'itemid', itemid
--     )::TEXT                             AS trace_id
-- FROM
--     @source_database.@hosp_schema.d_micro
-- ;

-- -------------------------------------------------------------------
-- src_d_micro
-- MIMIC IV 2.0: generate src_d_micro from microbiologyevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_d_micro;
CREATE TABLE @etl_database.@etl_schema.src_d_micro AS
WITH d_micro AS (

    SELECT DISTINCT
        ab_itemid                   AS itemid, -- numeric ID
        ab_name                     AS label, -- source_code for custom mapping
        'ANTIBIOTIC'                AS category,
        --
        JSON_BUILD_OBJECT(
            'field_name', 'ab_itemid',
            'itemid', ab_itemid
        )::TEXT                             AS trace_id
    FROM
        @source_database.@hosp_schema.microbiologyevents
    WHERE
        ab_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT
        test_itemid                 AS itemid, -- numeric ID
        test_name                   AS label, -- source_code for custom mapping
        'MICROTEST'                 AS category,
        --
        JSON_BUILD_OBJECT(
            'field_name', 'test_itemid',
            'itemid', test_itemid
        )::TEXT                             AS trace_id
    FROM
        @source_database.@hosp_schema.microbiologyevents
    WHERE
        test_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT
        org_itemid                  AS itemid, -- numeric ID
        org_name                    AS label, -- source_code for custom mapping
        'ORGANISM'                  AS category,
        --
        JSON_BUILD_OBJECT(
            'field_name', 'org_itemid',
            'itemid', org_itemid
        )::TEXT                             AS trace_id
    FROM
        @source_database.@hosp_schema.microbiologyevents
    WHERE
        org_itemid IS NOT NULL
    UNION ALL
    SELECT DISTINCT
        spec_itemid                 AS itemid, -- numeric ID
        spec_type_desc              AS label, -- source_code for custom mapping
        'SPECIMEN'                  AS category,
        --
        JSON_BUILD_OBJECT(
            'field_name', 'spec_itemid',
            'itemid', spec_itemid
        )::TEXT                             AS trace_id
    FROM
        @source_database.@hosp_schema.microbiologyevents
    WHERE
        spec_itemid IS NOT NULL
)
SELECT
    itemid                      AS itemid, -- numeric ID
    label                       AS label, -- source_code for custom mapping
    category                    AS category,
    --
    'microbiologyevents'                AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    trace_id                            AS trace_id
FROM
    d_micro
;

-- -------------------------------------------------------------------
-- src_pharmacy
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_pharmacy;
CREATE TABLE @etl_database.@etl_schema.src_pharmacy AS
SELECT
    pharmacy_id                         AS pharmacy_id,
    medication                          AS medication,
    -- hadm_id                             AS hadm_id,
    -- subject_id                          AS subject_id,
    -- starttime                           AS starttime,
    -- stoptime                            AS stoptime,
    -- route                               AS route,
    --
    'pharmacy'                          AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'pharmacy_id', pharmacy_id
    )::TEXT                             AS trace_id
FROM
    @source_database.@hosp_schema.pharmacy
;