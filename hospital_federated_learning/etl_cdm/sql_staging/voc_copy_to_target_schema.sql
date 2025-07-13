-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Copy vocabulary tables from the master vocab dataset
-- (to apply custom mapping here?)
-- -------------------------------------------------------------------

-- check
-- SELECT 'VOC' as source_type, COUNT(*) as record_count FROM @voc_database.@voc_schema.concept
-- UNION ALL
-- SELECT 'TARGET' as source_type, COUNT(*) as record_count FROM @etl_database.@etl_schema.voc_concept
-- ;

-- affected by custom mapping

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_concept AS
SELECT * FROM @voc_database.@voc_schema.concept
;

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_relationship CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_concept_relationship AS
SELECT * FROM @voc_database.@voc_schema.concept_relationship
;

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_vocabulary CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_vocabulary AS
SELECT * FROM @voc_database.@voc_schema.vocabulary
;

-- not affected by custom mapping

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_domain CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_domain AS
SELECT * FROM @voc_database.@voc_schema.domain
;

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_class CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_concept_class AS
SELECT * FROM @voc_database.@voc_schema.concept_class
;

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_relationship CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_relationship AS
SELECT * FROM @voc_database.@voc_schema.relationship
;

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_synonym CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_concept_synonym AS
SELECT * FROM @voc_database.@voc_schema.concept_synonym
;

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_ancestor CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_concept_ancestor AS
SELECT * FROM @voc_database.@voc_schema.concept_ancestor
;

DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_drug_strength CASCADE;
CREATE TABLE @etl_database.@etl_schema.voc_drug_strength AS
SELECT * FROM @voc_database.@voc_schema.drug_strength
;