-- Unload to ATLAS-- 2 billion concepts from Vocabulary tables

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.custom_concept CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.custom_concept AS
SELECT
    concept_id,
    concept_name,
    domain_id,
    vocabulary_id,
    concept_class_id,
    standard_concept,
    concept_code,
    valid_start_DATE,
    valid_end_DATE,
    invalid_reason
FROM @etl_database.@etl_schema.voc_concept
WHERE
    concept_id >= 2000000000
;

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.custom_concept_relationship CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.custom_concept_relationship AS
SELECT
    concept_id_1,
    concept_id_2,
    relationship_id,
    valid_start_DATE,
    valid_end_DATE,
    invalid_reason
FROM @etl_database.@etl_schema.voc_concept_relationship
WHERE
    concept_id_1 >= 2000000000
    OR concept_id_2 >= 2000000000
;

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.custom_vocabulary CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.custom_vocabulary AS
SELECT
    vocabulary_id,
    vocabulary_name,
    vocabulary_reference,
    vocabulary_version,
    vocabulary_concept_id
FROM @etl_database.@etl_schema.voc_vocabulary
WHERE
    vocabulary_concept_id >= 2000000000
;

