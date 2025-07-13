-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion - PostgreSQL Version
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Populate cdm_person table
--
-- Dependencies: run after st_core.sql
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Known issues / Open points:
--
-- loaded custom mapping:
--      gcpt_ethnicity_to_concept -> mimiciv_per_ethnicity
--
-- Why don't we want to use subject_id as person_id and hadm_id as visit_occurrence_id?
--      ask analysts
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- tmp_subject_ethnicity
-- -------------------------------------------------------------------
DROP TABLE IF EXISTS @etl_database.@etl_schema.tmp_subject_ethnicity CASCADE;
CREATE TABLE @etl_database.@etl_schema.tmp_subject_ethnicity AS
SELECT DISTINCT
    src.subject_id                      AS subject_id,
    FIRST_VALUE(src.ethnicity) OVER (
        PARTITION BY src.subject_id
        ORDER BY src.admittime ASC)     AS ethnicity_first
FROM
    @etl_database.@etl_schema.src_admissions src
;

-- -------------------------------------------------------------------
-- lk_pat_ethnicity_concept
-- -------------------------------------------------------------------
DROP TABLE IF EXISTS @etl_database.@etl_schema.lk_pat_ethnicity_concept CASCADE;
CREATE TABLE @etl_database.@etl_schema.lk_pat_ethnicity_concept AS
SELECT DISTINCT
    src.ethnicity_first     AS source_code,
    vc.concept_id           AS source_concept_id,
    vc.vocabulary_id        AS source_vocabulary_id,
    vc1.concept_id          AS target_concept_id,
    vc1.vocabulary_id       AS target_vocabulary_id -- look here to distinguish Race and Ethnicity
FROM
    @etl_database.@etl_schema.tmp_subject_ethnicity src
LEFT JOIN
    -- gcpt_ethnicity_to_concept -> mimiciv_per_ethnicity
    @etl_database.@etl_schema.voc_concept vc
        ON UPPER(vc.concept_code) = UPPER(src.ethnicity_first) -- do the custom mapping
        AND vc.domain_id IN ('Race', 'Ethnicity')
LEFT JOIN
    @etl_database.@etl_schema.voc_concept_relationship cr1
        ON  cr1.concept_id_1 = vc.concept_id
        AND cr1.relationship_id = 'Maps to'
LEFT JOIN
    @etl_database.@etl_schema.voc_concept vc1
        ON  cr1.concept_id_2 = vc1.concept_id
        AND vc1.invalid_reason IS NULL
        AND vc1.standard_concept = 'S'
;

-- -------------------------------------------------------------------
-- cdm_person
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_person CASCADE;
CREATE TABLE @etl_database.@etl_schema.cdm_person
(
    person_id                   BIGINT    NOT NULL ,
    gender_concept_id           BIGINT    NOT NULL ,
    year_of_birth               INTEGER   NOT NULL ,
    month_of_birth              INTEGER            ,
    day_of_birth                INTEGER            ,
    birth_datetime              TIMESTAMP          ,
    race_concept_id             BIGINT    NOT NULL,
    ethnicity_concept_id        BIGINT    NOT NULL,
    location_id                 BIGINT             ,
    provider_id                 BIGINT             ,
    care_site_id                BIGINT             ,
    person_source_value         VARCHAR(255)       ,
    gender_source_value         VARCHAR(50)        ,
    gender_source_concept_id    BIGINT             ,
    race_source_value           VARCHAR(255)       ,
    race_source_concept_id      BIGINT             ,
    ethnicity_source_value      VARCHAR(255)       ,
    ethnicity_source_concept_id BIGINT             ,
    --
    unit_id                     VARCHAR(255),
    load_table_id               VARCHAR(255),
    load_row_id                 BIGINT,
    trace_id                    VARCHAR(255)
);

INSERT INTO @etl_database.@etl_schema.cdm_person
SELECT
    -- Generate unique person_id using PostgreSQL's built-in functions
    ABS(HASHTEXT(gen_random_uuid()::TEXT))::BIGINT AS person_id,
    CASE
        WHEN p.gender = 'F' THEN 8532 -- FEMALE
        WHEN p.gender = 'M' THEN 8507 -- MALE
        ELSE 0
    END                             AS gender_concept_id,
    p.anchor_year                   AS year_of_birth,
    NULL::INTEGER                   AS month_of_birth,
    NULL::INTEGER                   AS day_of_birth,
    NULL::TIMESTAMP                 AS birth_datetime,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id <> 'Ethnicity'
                THEN map_eth.target_concept_id
            ELSE NULL
        END, 0)                     AS race_concept_id,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id = 'Ethnicity'
                THEN map_eth.target_concept_id
            ELSE NULL
        END, 0)                     AS ethnicity_concept_id,
    NULL::BIGINT                    AS location_id,
    NULL::BIGINT                    AS provider_id,
    NULL::BIGINT                    AS care_site_id,
    p.subject_id::VARCHAR(255)      AS person_source_value,
    p.gender                        AS gender_source_value,
    0                               AS gender_source_concept_id,
    CASE
        WHEN map_eth.target_vocabulary_id <> 'Ethnicity'
            THEN eth.ethnicity_first
        ELSE NULL
    END                             AS race_source_value,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id <> 'Ethnicity'
                THEN map_eth.source_concept_id
            ELSE NULL
        END, 0)                     AS race_source_concept_id,
    CASE
        WHEN map_eth.target_vocabulary_id = 'Ethnicity'
            THEN eth.ethnicity_first
        ELSE NULL
    END                             AS ethnicity_source_value,
    COALESCE(
        CASE
            WHEN map_eth.target_vocabulary_id = 'Ethnicity'
                THEN map_eth.source_concept_id
            ELSE NULL
        END, 0)                     AS ethnicity_source_concept_id,
    --
    'person.patients'               AS unit_id,
    p.load_table_id                 AS load_table_id,
    p.load_row_id                   AS load_row_id,
    p.trace_id                      AS trace_id
FROM
    @etl_database.@etl_schema.src_patients p
LEFT JOIN
    @etl_database.@etl_schema.tmp_subject_ethnicity eth
        ON  p.subject_id = eth.subject_id
LEFT JOIN
    @etl_database.@etl_schema.lk_pat_ethnicity_concept map_eth
        ON  eth.ethnicity_first = map_eth.source_code
;

-- Create index on person_id for better performance
CREATE INDEX idx_cdm_person_person_id ON @etl_database.@etl_schema.cdm_person(person_id);

-- -------------------------------------------------------------------
-- cleanup
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.tmp_subject_ethnicity;