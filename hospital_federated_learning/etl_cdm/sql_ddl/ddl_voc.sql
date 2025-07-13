/*OMOP CDM v5.3.1 14June2018 - PostgreSQL Version*/

-- Drop tables if they exist (PostgreSQL equivalent of CREATE OR REPLACE)
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_vocabulary CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_domain CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_class CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_relationship CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_relationship CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_synonym CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_concept_ancestor CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_source_to_concept_map CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.voc_drug_strength CASCADE;

CREATE TABLE @etl_database.@etl_schema.voc_concept (
  concept_id          BIGINT      NOT NULL,
  concept_name        VARCHAR(255) NOT NULL,
  domain_id           VARCHAR(20)  NOT NULL,
  vocabulary_id       VARCHAR(30)  NOT NULL,
  concept_class_id    VARCHAR(30)  NOT NULL,
  standard_concept    VARCHAR(1),
  concept_code        VARCHAR(255)  NOT NULL,
  valid_start_date    DATE         NOT NULL,
  valid_end_date      DATE         NOT NULL,
  invalid_reason      VARCHAR(1)
);

CREATE TABLE @etl_database.@etl_schema.voc_vocabulary (
  vocabulary_id         VARCHAR(30)  NOT NULL,
  vocabulary_name       VARCHAR(255) NOT NULL,
  vocabulary_reference  VARCHAR(255) NOT NULL,
  vocabulary_version    VARCHAR(255),
  vocabulary_concept_id BIGINT       NOT NULL
);

CREATE TABLE @etl_database.@etl_schema.voc_domain (
  domain_id         VARCHAR(20)  NOT NULL,
  domain_name       VARCHAR(255) NOT NULL,
  domain_concept_id BIGINT       NOT NULL
);

CREATE TABLE @etl_database.@etl_schema.voc_concept_class (
  concept_class_id          VARCHAR(30)  NOT NULL,
  concept_class_name        VARCHAR(255) NOT NULL,
  concept_class_concept_id  BIGINT       NOT NULL
);

CREATE TABLE @etl_database.@etl_schema.voc_concept_relationship (
  concept_id_1      BIGINT      NOT NULL,
  concept_id_2      BIGINT      NOT NULL,
  relationship_id   VARCHAR(20) NOT NULL,
  valid_start_date  DATE        NOT NULL,
  valid_end_date    DATE        NOT NULL,
  invalid_reason    VARCHAR(1)
);

CREATE TABLE @etl_database.@etl_schema.voc_relationship (
  relationship_id         VARCHAR(20)  NOT NULL,
  relationship_name       VARCHAR(255) NOT NULL,
  is_hierarchical         VARCHAR(1)   NOT NULL,
  defines_ancestry        VARCHAR(1)   NOT NULL,
  reverse_relationship_id VARCHAR(20)  NOT NULL,
  relationship_concept_id BIGINT       NOT NULL
);

CREATE TABLE @etl_database.@etl_schema.voc_concept_synonym (
  concept_id            BIGINT       NOT NULL,
  concept_synonym_name  VARCHAR(1000) NOT NULL,
  language_concept_id   BIGINT       NOT NULL
);

CREATE TABLE @etl_database.@etl_schema.voc_concept_ancestor (
  ancestor_concept_id       BIGINT  NOT NULL,
  descendant_concept_id     BIGINT  NOT NULL,
  min_levels_of_separation  INTEGER NOT NULL,
  max_levels_of_separation  INTEGER NOT NULL
);

CREATE TABLE @etl_database.@etl_schema.voc_source_to_concept_map (
  source_code             VARCHAR(255)  NOT NULL,
  source_concept_id       BIGINT       NOT NULL,
  source_vocabulary_id    VARCHAR(20)  NOT NULL,
  source_code_description VARCHAR(255),
  target_concept_id       BIGINT       NOT NULL,
  target_vocabulary_id    VARCHAR(20)  NOT NULL,
  valid_start_date        DATE         NOT NULL,
  valid_end_date          DATE         NOT NULL,
  invalid_reason          VARCHAR(1)
);

CREATE TABLE @etl_database.@etl_schema.voc_drug_strength (
  drug_concept_id             BIGINT  NOT NULL,
  ingredient_concept_id       BIGINT  NOT NULL,
  amount_value                NUMERIC,
  amount_unit_concept_id      BIGINT,
  numerator_value             NUMERIC,
  numerator_unit_concept_id   BIGINT,
  denominator_value           NUMERIC,
  denominator_unit_concept_id BIGINT,
  box_size                    INTEGER,
  valid_start_date            DATE    NOT NULL,
  valid_end_date              DATE    NOT NULL,
  invalid_reason              VARCHAR(1)
);