-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- dependency, run after:
--      st_core.sql
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- A draft to apply Wave Forms
--
-- 3 chunks from a trending data CSV file, and from a summarized CSV file
--
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- open points:
--      parse XML to create src_* or raw_* tables
--

-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- staging tables
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- src_waveform_header
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_waveform_header_3 CASCADE;

CREATE TABLE @etl_database.@etl_schema.src_waveform_header_3
(
    reference_id            VARCHAR(255),
    raw_files_path          TEXT,
    case_id                 VARCHAR(255),
    subject_id              BIGINT,
    start_datetime          TIMESTAMP,
    end_datetime            TIMESTAMP,
    --
    load_table_id           VARCHAR(255),
    load_row_id             BIGINT,
    trace_id                TEXT
);

-- parsed codes to be targeted to table cdm_measurement

DROP TABLE IF EXISTS @etl_database.@etl_schema.src_waveform_mx_3 CASCADE;

CREATE TABLE @etl_database.@etl_schema.src_waveform_mx_3
(
    case_id                 VARCHAR(255),  -- FK to the header
    segment_name            VARCHAR(255), -- two digits of case_id, 5 digits of internal sequence number
    mx_datetime             TIMESTAMP, -- time of measurement
    source_code             VARCHAR(255),   -- type of measurement
    value_as_number         DOUBLE PRECISION,
    unit_source_value       VARCHAR(100), -- measurement unit "BPM", "MS", "UV" (microvolt) etc.
                                         -- map these labels and populate unit_concept_id
    --
    Visit_Detail___Source               VARCHAR(255),
    Visit_Detail___Start_from_minutes   BIGINT,
    Visit_Detail___Report_minutes       BIGINT,
    Visit_Detail___Sumarize_minutes     BIGINT,
    Visit_Detail___Method               VARCHAR(255),
    --
    load_table_id           VARCHAR(255),
    load_row_id             BIGINT,
    trace_id                TEXT
);


-- parse xml from Manlik? -> src_waveform
-- src_waveform -> visit_detail (visit_detail_source_value = <reference ID>)

-- finding the visit
-- create visit_detail
-- create measurement -> link visit_detail using visit_detail_source_value = meas_source_value
-- (start with Manlik's proposal)


-- -------------------------------------------------------------------
-- insert sample data
-- -------------------------------------------------------------------


INSERT INTO @etl_database.@etl_schema.src_waveform_header_3
SELECT
    subj.short_reference_id             AS reference_id,
    subj.long_reference_id              AS raw_files_path,
    subj.case_id                        AS case_id, -- string
    REPLACE(subj.case_id, 'p', '')::BIGINT AS subject_id, -- int
    subj.start_datetime::TIMESTAMP      AS start_datetime,
    subj.end_datetime::TIMESTAMP        AS end_datetime,
    --
    'poc_3_header'                      AS load_table_id,
    0                                   AS load_row_id,
    json_build_object(
        'case_id', subj.case_id,
        'reference_id', subj.short_reference_id
    )::TEXT                             AS trace_id
FROM
    @wf_database.@wf_schema.poc_3_header subj
;

-- Chunk 1
-- 25-second interval, mass data

INSERT INTO @etl_database.@etl_schema.src_waveform_mx_3
SELECT
    src.case_id                         AS case_id, -- FK to the header
    src.segment_name                    AS segment_name,
    --
    src.date_time::TIMESTAMP            AS mx_datetime,
    src.src_name                        AS source_code,
    src.value::DOUBLE PRECISION         AS value_as_number,
    src.unit_concept_name               AS unit_source_value,
    'csv'                               AS Visit_Detail___Source,
    NULL                                AS Visit_Detail___Start_from_minutes,
    NULL                                AS Visit_Detail___Report_minutes,
    NULL                                AS Visit_Detail___Sumarize_minutes,
    'NONE'                              AS Visit_Detail___Method,
    --
    'poc_3_chunk_1'                     AS load_table_id,
    abs(hashtext(gen_random_uuid()::TEXT)) AS load_row_id,
    json_build_object(
        'case_id', src.case_id,
        'date_time', src.date_time::TEXT,
        'src_name', src.src_name
    )::TEXT                             AS trace_id
FROM
    @wf_database.@wf_schema.poc_3_chunk_1 src
INNER JOIN
    @etl_database.@etl_schema.src_patients pat
        ON  REPLACE(src.case_id, 'p', '')::BIGINT = pat.subject_id    -- filter out mass data in demo dataset
;


-- Chunk 2
-- 5-minute interval, summarized data for Full set and Demo

INSERT INTO @etl_database.@etl_schema.src_waveform_mx_3
SELECT
    src.case_id                         AS case_id, -- FK to the header
    src.segment_name                    AS segment_name,
    --
    src.date_time::TIMESTAMP            AS mx_datetime,
    src.src_name                        AS source_code,
    src.value::DOUBLE PRECISION         AS value_as_number,
    src.unit_concept_name               AS unit_source_value,
    Visit_Detail___Source               AS Visit_Detail___Source,
    Visit_Detail___Start_from_minutes   AS Visit_Detail___Start_from_minutes,
    Visit_Detail___Report_minutes       AS Visit_Detail___Report_minutes,
    Visit_Detail___Sumarize_minutes     AS Visit_Detail___Sumarize_minutes,
    Visit_Detail___Method               AS Visit_Detail___Method,
    --
    'poc_3_chunk_2'                     AS load_table_id,
    abs(hashtext(gen_random_uuid()::TEXT)) AS load_row_id,
    json_build_object(
        'case_id', src.case_id,
        'date_time', src.date_time::TEXT,
        'src_name', src.src_name
    )::TEXT                             AS trace_id
FROM
    @wf_database.@wf_schema.poc_3_chunk_2 src
;


-- Chunk 3
-- 25-second interval, tiny mass data for Demo

INSERT INTO @etl_database.@etl_schema.src_waveform_mx_3
SELECT
    src.case_id                         AS case_id, -- FK to the header
    src.segment_name                    AS segment_name,
    --
    src.date_time::TIMESTAMP            AS mx_datetime,
    src.src_name                        AS source_code,
    src.value::DOUBLE PRECISION         AS value_as_number,
    src.unit_concept_name               AS unit_source_value,
    Visit_Detail___Source               AS Visit_Detail___Source,
    Visit_Detail___Start_from_minutes   AS Visit_Detail___Start_from_minutes,
    Visit_Detail___Report_minutes       AS Visit_Detail___Report_minutes,
    Visit_Detail___Sumarize_minutes     AS Visit_Detail___Sumarize_minutes,
    Visit_Detail___Method               AS Visit_Detail___Method,
    --
    'poc_3_chunk_3'                     AS load_table_id,
    abs(hashtext(gen_random_uuid()::TEXT)) AS load_row_id,
    json_build_object(
        'case_id', src.case_id,
        'date_time', src.date_time::TEXT,
        'src_name', src.src_name
    )::TEXT                             AS trace_id
FROM
    @wf_database.@wf_schema.poc_3_chunk_3 src
;