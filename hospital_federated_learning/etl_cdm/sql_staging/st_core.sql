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
-- transfers.stay_id - does not exist in Demo, but is described in the online Documentation
-- -------------------------------------------------------------------


-- -------------------------------------------------------------------
-- src_patients
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_patients;
CREATE TABLE @etl_database.@etl_schema.src_patients AS
SELECT
    subject_id                          AS subject_id,
    anchor_year                         AS anchor_year,
    anchor_age                          AS anchor_age,
    anchor_year_group                   AS anchor_year_group,
    gender                              AS gender,
    --
    'patients'                          AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id
    )::TEXT                             AS trace_id
FROM
    @source_database.@core_schema.patients
;

-- -------------------------------------------------------------------
-- src_admissions
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_admissions;
CREATE TABLE @etl_database.@etl_schema.src_admissions AS
SELECT
    hadm_id                             AS hadm_id, -- PK
    subject_id                          AS subject_id,
    admittime                           AS admittime,
    dischtime                           AS dischtime,
    deathtime                           AS deathtime,
    admission_type                      AS admission_type,
    admission_location                  AS admission_location,
    discharge_location                  AS discharge_location,
    race                                AS ethnicity, -- MIMIC IV 2.0 change, field race replaced field ethnicity
    edregtime                           AS edregtime,
    insurance                           AS insurance,
    marital_status                      AS marital_status,
    language                            AS language,
    -- edouttime
    -- hospital_expire_flag
    --
    'admissions'                        AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id
    )::TEXT                             AS trace_id
FROM
    @source_database.@core_schema.admissions
;

-- -------------------------------------------------------------------
-- src_transfers
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_transfers;
CREATE TABLE @etl_database.@etl_schema.src_transfers AS
SELECT
    transfer_id                         AS transfer_id,
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
    careunit                            AS careunit,
    intime                              AS intime,
    outtime                             AS outtime,
    eventtype                           AS eventtype,
    --
    'transfers'                         AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'transfer_id', transfer_id
    )::TEXT                             AS trace_id
FROM
    @source_database.@core_schema.transfers
;