/*OMOP CDM v5.3.1 14June2018 - PostgreSQL Version*/

-- Drop tables if they exist (PostgreSQL equivalent of CREATE OR REPLACE)
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_cohort_definition CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_attribute_definition CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_cdm_source CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_metadata CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_person CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_observation_period CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_specimen CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_death CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_visit_occurrence CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_visit_detail CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_procedure_occurrence CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_drug_exposure CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_device_exposure CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_condition_occurrence CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_measurement CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_note CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_note_nlp CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_observation CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_fact_relationship CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_location CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_care_site CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_provider CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_payer_plan_period CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_cost CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_cohort CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_cohort_attribute CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_drug_era CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_dose_era CASCADE;
DROP TABLE IF EXISTS @etl_database.@etl_schema.cdm_condition_era CASCADE;

CREATE TABLE @etl_database.@etl_schema.cdm_cohort_definition (
  cohort_definition_id            BIGINT      NOT NULL,
  cohort_definition_name          VARCHAR(255) NOT NULL,
  cohort_definition_description   TEXT,
  definition_type_concept_id      BIGINT      NOT NULL,
  cohort_definition_syntax        TEXT,
  subject_concept_id              BIGINT      NOT NULL,
  cohort_initiation_date          DATE
);

CREATE TABLE @etl_database.@etl_schema.cdm_attribute_definition (
  attribute_definition_id     BIGINT      NOT NULL,
  attribute_name              VARCHAR(255) NOT NULL,
  attribute_description       TEXT,
  attribute_type_concept_id   BIGINT      NOT NULL,
  attribute_syntax            TEXT
);

CREATE TABLE @etl_database.@etl_schema.cdm_cdm_source
(
  cdm_source_name                 VARCHAR(255) NOT NULL,
  cdm_source_abbreviation         VARCHAR(25),
  cdm_holder                      VARCHAR(255),
  source_description              TEXT,
  source_documentation_reference  VARCHAR(255),
  cdm_etl_reference               VARCHAR(255),
  source_release_date             DATE,
  cdm_release_date                DATE,
  cdm_version                     VARCHAR(10),
  vocabulary_version              VARCHAR(20)
);

CREATE TABLE @etl_database.@etl_schema.cdm_metadata
(
  metadata_concept_id       BIGINT      NOT NULL,
  metadata_type_concept_id  BIGINT      NOT NULL,
  name                      VARCHAR(250) NOT NULL,
  value_as_string           TEXT,
  value_as_concept_id       BIGINT,
  metadata_date             DATE,
  metadata_datetime         TIMESTAMP
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_person
(
  person_id                   BIGINT      NOT NULL,
  gender_concept_id           BIGINT      NOT NULL,
  year_of_birth               INTEGER     NOT NULL,
  month_of_birth              INTEGER,
  day_of_birth                INTEGER,
  birth_datetime              TIMESTAMP,
  race_concept_id             BIGINT      NOT NULL,
  ethnicity_concept_id        BIGINT      NOT NULL,
  location_id                 BIGINT,
  provider_id                 BIGINT,
  care_site_id                BIGINT,
  person_source_value         VARCHAR(50),
  gender_source_value         VARCHAR(50),
  gender_source_concept_id    BIGINT,
  race_source_value           VARCHAR(50),
  race_source_concept_id      BIGINT,
  ethnicity_source_value      VARCHAR(50),
  ethnicity_source_concept_id BIGINT
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_observation_period
(
  observation_period_id             BIGINT  NOT NULL,
  person_id                         BIGINT  NOT NULL,
  observation_period_start_date     DATE    NOT NULL,
  observation_period_end_date       DATE    NOT NULL,
  period_type_concept_id            BIGINT  NOT NULL
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_specimen
(
  specimen_id                 BIGINT      NOT NULL,
  person_id                   BIGINT      NOT NULL,
  specimen_concept_id         BIGINT      NOT NULL,
  specimen_type_concept_id    BIGINT      NOT NULL,
  specimen_date               DATE        NOT NULL,
  specimen_datetime           TIMESTAMP,
  quantity                    NUMERIC,
  unit_concept_id             BIGINT,
  anatomic_site_concept_id    BIGINT,
  disease_status_concept_id   BIGINT,
  specimen_source_id          VARCHAR(50),
  specimen_source_value       VARCHAR(50),
  unit_source_value           VARCHAR(50),
  anatomic_site_source_value  VARCHAR(50),
  disease_status_source_value VARCHAR(50)
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_death
(
  person_id               BIGINT      NOT NULL,
  death_date              DATE        NOT NULL,
  death_datetime          TIMESTAMP,
  death_type_concept_id   BIGINT      NOT NULL,
  cause_concept_id        BIGINT,
  cause_source_value      VARCHAR(50),
  cause_source_concept_id BIGINT
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_visit_occurrence
(
  visit_occurrence_id           BIGINT      NOT NULL,
  person_id                     BIGINT      NOT NULL,
  visit_concept_id              BIGINT      NOT NULL,
  visit_start_date              DATE        NOT NULL,
  visit_start_datetime          TIMESTAMP,
  visit_end_date                DATE        NOT NULL,
  visit_end_datetime            TIMESTAMP,
  visit_type_concept_id         BIGINT      NOT NULL,
  provider_id                   BIGINT,
  care_site_id                  BIGINT,
  visit_source_value            VARCHAR(50),
  visit_source_concept_id       BIGINT,
  admitting_source_concept_id   BIGINT,
  admitting_source_value        VARCHAR(50),
  discharge_to_concept_id       BIGINT,
  discharge_to_source_value     VARCHAR(50),
  preceding_visit_occurrence_id BIGINT
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_visit_detail
(
  visit_detail_id                    BIGINT      NOT NULL,
  person_id                          BIGINT      NOT NULL,
  visit_detail_concept_id            BIGINT      NOT NULL,
  visit_detail_start_date            DATE        NOT NULL,
  visit_detail_start_datetime        TIMESTAMP,
  visit_detail_end_date              DATE        NOT NULL,
  visit_detail_end_datetime          TIMESTAMP,
  visit_detail_type_concept_id       BIGINT      NOT NULL,
  provider_id                        BIGINT,
  care_site_id                       BIGINT,
  admitting_source_concept_id        BIGINT,
  discharge_to_concept_id            BIGINT,
  preceding_visit_detail_id          BIGINT,
  visit_detail_source_value          VARCHAR(50),
  visit_detail_source_concept_id     BIGINT,
  admitting_source_value             VARCHAR(50),
  discharge_to_source_value          VARCHAR(50),
  visit_detail_parent_id             BIGINT,
  visit_occurrence_id                BIGINT      NOT NULL
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_procedure_occurrence
(
  procedure_occurrence_id     BIGINT      NOT NULL,
  person_id                   BIGINT      NOT NULL,
  procedure_concept_id        BIGINT      NOT NULL,
  procedure_date              DATE        NOT NULL,
  procedure_datetime          TIMESTAMP,
  procedure_type_concept_id   BIGINT      NOT NULL,
  modifier_concept_id         BIGINT,
  quantity                    INTEGER,
  provider_id                 BIGINT,
  visit_occurrence_id         BIGINT,
  visit_detail_id             BIGINT,
  procedure_source_value      VARCHAR(50),
  procedure_source_concept_id BIGINT,
  modifier_source_value       VARCHAR(50)
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_drug_exposure
(
  drug_exposure_id              BIGINT      NOT NULL,
  person_id                     BIGINT      NOT NULL,
  drug_concept_id               BIGINT      NOT NULL,
  drug_exposure_start_date      DATE        NOT NULL,
  drug_exposure_start_datetime  TIMESTAMP,
  drug_exposure_end_date        DATE        NOT NULL,
  drug_exposure_end_datetime    TIMESTAMP,
  verbatim_end_date             DATE,
  drug_type_concept_id          BIGINT      NOT NULL,
  stop_reason                   VARCHAR(20),
  refills                       INTEGER,
  quantity                      NUMERIC,
  days_supply                   INTEGER,
  sig                           TEXT,
  route_concept_id              BIGINT,
  lot_number                    VARCHAR(50),
  provider_id                   BIGINT,
  visit_occurrence_id           BIGINT,
  visit_detail_id               BIGINT,
  drug_source_value             VARCHAR(50),
  drug_source_concept_id        BIGINT,
  route_source_value            VARCHAR(50),
  dose_unit_source_value        VARCHAR(50)
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_device_exposure
(
  device_exposure_id              BIGINT      NOT NULL,
  person_id                       BIGINT      NOT NULL,
  device_concept_id               BIGINT      NOT NULL,
  device_exposure_start_date      DATE        NOT NULL,
  device_exposure_start_datetime  TIMESTAMP,
  device_exposure_end_date        DATE,
  device_exposure_end_datetime    TIMESTAMP,
  device_type_concept_id          BIGINT      NOT NULL,
  unique_device_id                VARCHAR(50),
  quantity                        INTEGER,
  provider_id                     BIGINT,
  visit_occurrence_id             BIGINT,
  visit_detail_id                 BIGINT,
  device_source_value             VARCHAR(50),
  device_source_concept_id        BIGINT
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_condition_occurrence
(
  condition_occurrence_id       BIGINT      NOT NULL,
  person_id                     BIGINT      NOT NULL,
  condition_concept_id          BIGINT      NOT NULL,
  condition_start_date          DATE        NOT NULL,
  condition_start_datetime      TIMESTAMP,
  condition_end_date            DATE,
  condition_end_datetime        TIMESTAMP,
  condition_type_concept_id     BIGINT      NOT NULL,
  stop_reason                   VARCHAR(20),
  provider_id                   BIGINT,
  visit_occurrence_id           BIGINT,
  visit_detail_id               BIGINT,
  condition_source_value        VARCHAR(50),
  condition_source_concept_id   BIGINT,
  condition_status_source_value VARCHAR(50),
  condition_status_concept_id   BIGINT
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_measurement
(
  measurement_id                BIGINT      NOT NULL,
  person_id                     BIGINT      NOT NULL,
  measurement_concept_id        BIGINT      NOT NULL,
  measurement_date              DATE        NOT NULL,
  measurement_datetime          TIMESTAMP,
  measurement_time              VARCHAR(10),
  measurement_type_concept_id   BIGINT      NOT NULL,
  operator_concept_id           BIGINT,
  value_as_number               NUMERIC,
  value_as_concept_id           BIGINT,
  unit_concept_id               BIGINT,
  range_low                     NUMERIC,
  range_high                    NUMERIC,
  provider_id                   BIGINT,
  visit_occurrence_id           BIGINT,
  visit_detail_id               BIGINT,
  measurement_source_value      VARCHAR(50),
  measurement_source_concept_id BIGINT,
  unit_source_value             VARCHAR(50),
  value_source_value            VARCHAR(50)
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_note
(
  note_id               BIGINT      NOT NULL,
  person_id             BIGINT      NOT NULL,
  note_date             DATE        NOT NULL,
  note_datetime         TIMESTAMP,
  note_type_concept_id  BIGINT      NOT NULL,
  note_class_concept_id BIGINT      NOT NULL,
  note_title            VARCHAR(250),
  note_text             TEXT,
  encoding_concept_id   BIGINT      NOT NULL,
  language_concept_id   BIGINT      NOT NULL,
  provider_id           BIGINT,
  visit_occurrence_id   BIGINT,
  visit_detail_id       BIGINT,
  note_source_value     VARCHAR(50)
);

CREATE TABLE @etl_database.@etl_schema.cdm_note_nlp
(
  note_nlp_id                 BIGINT,
  note_id                     BIGINT,
  section_concept_id          BIGINT,
  snippet                     VARCHAR(250),
  offset_val                    VARCHAR(50), -- hand modified later in "offset"
  lexical_variant             VARCHAR(250) NOT NULL,
  note_nlp_concept_id         BIGINT,
  note_nlp_source_concept_id  BIGINT,
  nlp_system                  VARCHAR(250),
  nlp_date                    DATE         NOT NULL,
  nlp_datetime                TIMESTAMP,
  term_exists                 VARCHAR(1),
  term_temporal               VARCHAR(50),
  term_modifiers              VARCHAR(2000)
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_observation
(
  observation_id                BIGINT      NOT NULL,
  person_id                     BIGINT      NOT NULL,
  observation_concept_id        BIGINT      NOT NULL,
  observation_date              DATE        NOT NULL,
  observation_datetime          TIMESTAMP,
  observation_type_concept_id   BIGINT      NOT NULL,
  value_as_number               NUMERIC,
  value_as_string               VARCHAR(60),
  value_as_concept_id           BIGINT,
  qualifier_concept_id          BIGINT,
  unit_concept_id               BIGINT,
  provider_id                   BIGINT,
  visit_occurrence_id           BIGINT,
  visit_detail_id               BIGINT,
  observation_source_value      VARCHAR(50),
  observation_source_concept_id BIGINT,
  unit_source_value             VARCHAR(50),
  qualifier_source_value        VARCHAR(50)
);

CREATE TABLE @etl_database.@etl_schema.cdm_fact_relationship
(
  domain_concept_id_1     BIGINT  NOT NULL,
  fact_id_1               BIGINT  NOT NULL,
  domain_concept_id_2     BIGINT  NOT NULL,
  fact_id_2               BIGINT  NOT NULL,
  relationship_concept_id BIGINT  NOT NULL
);

CREATE TABLE @etl_database.@etl_schema.cdm_location
(
  location_id           BIGINT      NOT NULL,
  address_1             VARCHAR(50),
  address_2             VARCHAR(50),
  city                  VARCHAR(50),
  state                 VARCHAR(2),
  zip                   VARCHAR(9),
  county                VARCHAR(20),
  location_source_value VARCHAR(50)
);

CREATE TABLE @etl_database.@etl_schema.cdm_care_site
(
  care_site_id                  BIGINT      NOT NULL,
  care_site_name                VARCHAR(255),
  place_of_service_concept_id   BIGINT,
  location_id                   BIGINT,
  care_site_source_value        VARCHAR(50),
  place_of_service_source_value VARCHAR(50)
);

CREATE TABLE @etl_database.@etl_schema.cdm_provider
(
  provider_id                 BIGINT      NOT NULL,
  provider_name               VARCHAR(255),
  npi                         VARCHAR(20),
  dea                         VARCHAR(20),
  specialty_concept_id        BIGINT,
  care_site_id                BIGINT,
  year_of_birth               INTEGER,
  gender_concept_id           BIGINT,
  provider_source_value       VARCHAR(50),
  specialty_source_value      VARCHAR(50),
  specialty_source_concept_id BIGINT,
  gender_source_value         VARCHAR(50),
  gender_source_concept_id    BIGINT
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_payer_plan_period
(
  payer_plan_period_id          BIGINT      NOT NULL,
  person_id                     BIGINT      NOT NULL,
  payer_plan_period_start_date  DATE        NOT NULL,
  payer_plan_period_end_date    DATE        NOT NULL,
  payer_concept_id              BIGINT,
  payer_source_value            VARCHAR(50),
  payer_source_concept_id       BIGINT,
  plan_concept_id               BIGINT,
  plan_source_value             VARCHAR(50),
  plan_source_concept_id        BIGINT,
  sponsor_concept_id            BIGINT,
  sponsor_source_value          VARCHAR(50),
  sponsor_source_concept_id     BIGINT,
  family_source_value           VARCHAR(50),
  stop_reason_concept_id        BIGINT,
  stop_reason_source_value      VARCHAR(50),
  stop_reason_source_concept_id BIGINT
);

CREATE TABLE @etl_database.@etl_schema.cdm_cost
(
  cost_id                   BIGINT      NOT NULL,
  cost_event_id             BIGINT      NOT NULL,
  cost_domain_id            VARCHAR(20) NOT NULL,
  cost_type_concept_id      BIGINT      NOT NULL,
  currency_concept_id       BIGINT,
  total_charge              NUMERIC,
  total_cost                NUMERIC,
  total_paid                NUMERIC,
  paid_by_payer             NUMERIC,
  paid_by_patient           NUMERIC,
  paid_patient_copay        NUMERIC,
  paid_patient_coinsurance  NUMERIC,
  paid_patient_deductible   NUMERIC,
  paid_by_primary           NUMERIC,
  paid_ingredient_cost      NUMERIC,
  paid_dispensing_fee       NUMERIC,
  payer_plan_period_id      BIGINT,
  amount_allowed            NUMERIC,
  revenue_code_concept_id   BIGINT,
  revenue_code_source_value VARCHAR(50),
  drg_concept_id            BIGINT,
  drg_source_value          VARCHAR(50)
);

-- Distributed on subject_id
CREATE TABLE @etl_database.@etl_schema.cdm_cohort
(
  cohort_definition_id  BIGINT  NOT NULL,
  subject_id            BIGINT  NOT NULL,
  cohort_start_date     DATE    NOT NULL,
  cohort_end_date       DATE    NOT NULL
);

-- Distributed on subject_id
CREATE TABLE @etl_database.@etl_schema.cdm_cohort_attribute
(
  cohort_definition_id    BIGINT  NOT NULL,
  subject_id              BIGINT  NOT NULL,
  cohort_start_date       DATE    NOT NULL,
  cohort_end_date         DATE    NOT NULL,
  attribute_definition_id BIGINT  NOT NULL,
  value_as_number         NUMERIC,
  value_as_concept_id     BIGINT
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_drug_era
(
  drug_era_id         BIGINT  NOT NULL,
  person_id           BIGINT  NOT NULL,
  drug_concept_id     BIGINT  NOT NULL,
  drug_era_start_date DATE    NOT NULL,
  drug_era_end_date   DATE    NOT NULL,
  drug_exposure_count INTEGER,
  gap_days            INTEGER
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_dose_era
(
  dose_era_id           BIGINT  NOT NULL,
  person_id             BIGINT  NOT NULL,
  drug_concept_id       BIGINT  NOT NULL,
  unit_concept_id       BIGINT  NOT NULL,
  dose_value            NUMERIC NOT NULL,
  dose_era_start_date   DATE    NOT NULL,
  dose_era_end_date     DATE    NOT NULL
);

-- Distributed on person_id
CREATE TABLE @etl_database.@etl_schema.cdm_condition_era
(
  condition_era_id            BIGINT  NOT NULL,
  person_id                   BIGINT  NOT NULL,
  condition_concept_id        BIGINT  NOT NULL,
  condition_era_start_date    DATE    NOT NULL,
  condition_era_end_date      DATE    NOT NULL,
  condition_occurrence_count  INTEGER
);