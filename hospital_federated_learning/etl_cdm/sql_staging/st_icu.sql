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
-- src_procedureevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_procedureevents;
CREATE TABLE @etl_database.@etl_schema.src_procedureevents AS
SELECT
    hadm_id                             AS hadm_id,
    subject_id                          AS subject_id,
    stay_id                             AS stay_id,
    itemid                              AS itemid,
    starttime                           AS starttime,
    value                               AS value,
    CAST(0 AS INTEGER)                  AS cancelreason, -- MIMIC IV 2.0 change, the field is removed
    --
    'procedureevents'                   AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'starttime', starttime
    )::TEXT                             AS trace_id
FROM
    @source_database.@icu_schema.procedureevents
;

-- -------------------------------------------------------------------
-- src_d_items
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_d_items;
CREATE TABLE @etl_database.@etl_schema.src_d_items AS
SELECT
    itemid                              AS itemid,
    label                               AS label,
    linksto                             AS linksto,
    -- abbreviation
    -- category
    -- unitname
    -- param_type
    -- lownormalvalue
    -- highnormalvalue
    --
    'd_items'                           AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'itemid', itemid,
        'linksto', linksto
    )::TEXT                             AS trace_id
FROM
    @source_database.@icu_schema.d_items
;

-- -------------------------------------------------------------------
-- src_datetimeevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_datetimeevents;
CREATE TABLE @etl_database.@etl_schema.src_datetimeevents AS
SELECT
    subject_id  AS subject_id,
    hadm_id     AS hadm_id,
    stay_id     AS stay_id,
    itemid      AS itemid,
    charttime   AS charttime,
    value       AS value,
    --
    'datetimeevents'                    AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'stay_id', stay_id,
        'charttime', charttime
    )::TEXT                             AS trace_id
FROM
    @source_database.@icu_schema.datetimeevents
;

-- -------------------------------------------------------------------
-- src_chartevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_chartevents;
CREATE TABLE @etl_database.@etl_schema.src_chartevents AS
SELECT
    subject_id  AS subject_id,
    hadm_id     AS hadm_id,
    stay_id     AS stay_id,
    itemid      AS itemid,
    charttime   AS charttime,
    value       AS value,
    valuenum    AS valuenum,
    valueuom    AS valueuom,
    --
    'chartevents'                       AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'stay_id', stay_id,
        'charttime', charttime
    )::TEXT                             AS trace_id
FROM
    @source_database.@icu_schema.chartevents
;

-- -------------------------------------------------------------------
-- src_outputevents
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_outputevents;
CREATE TABLE @etl_database.@etl_schema.src_outputevents AS
SELECT
    subject_id  AS subject_id,
    hadm_id     AS hadm_id,
    stay_id     AS stay_id,
    charttime   AS charttime,
    storetime   AS storetime,
    itemid      AS itemid,
    value       AS value,
    valueuom    AS valueuom,
    --
    'outputevents'                       AS load_table_id,
    ABS(HASHTEXT(GEN_RANDOM_UUID()::TEXT)) AS load_row_id,
    JSON_BUILD_OBJECT(
        'subject_id', subject_id,
        'hadm_id', hadm_id,
        'stay_id', stay_id,
        'charttime', charttime
    )::TEXT                             AS trace_id
FROM
    @source_database.@icu_schema.outputevents
;