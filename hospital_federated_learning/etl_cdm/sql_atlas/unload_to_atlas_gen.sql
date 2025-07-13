-- bq_cdm_to_atlas generated script --

-- Unload to ATLAS-- Copy Vocabulary tables

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.concept CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.concept AS
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
FROM @etl_database.@etl_schema.voc_concept;

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.vocabulary CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.vocabulary AS
SELECT
    vocabulary_id,
    vocabulary_name,
    vocabulary_reference,
    vocabulary_version,
    vocabulary_concept_id
FROM @etl_database.@etl_schema.voc_vocabulary;

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.domain CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.domain AS
SELECT
    domain_id,
    domain_name,
    domain_concept_id
FROM @etl_database.@etl_schema.voc_domain;

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.concept_class CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.concept_class AS
SELECT
    concept_class_id,
    concept_class_name,
    concept_class_concept_id
FROM @etl_database.@etl_schema.voc_concept_class;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.concept_relationship CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.concept_relationship AS
SELECT
    concept_id_1,
    concept_id_2,
    relationship_id,
    valid_start_DATE,
    valid_end_DATE,
    invalid_reason
FROM @etl_database.@etl_schema.voc_concept_relationship;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.relationship CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.relationship AS
SELECT
    relationship_id,
    relationship_name,
    is_hierarchical,
    defines_ancestry,
    reverse_relationship_id,
    relationship_concept_id
FROM @etl_database.@etl_schema.voc_relationship;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.concept_synonym CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.concept_synonym AS
SELECT
    concept_id,
    concept_synonym_name,
    language_concept_id
FROM @etl_database.@etl_schema.voc_concept_synonym;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.concept_ancestor CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.concept_ancestor AS
SELECT
    ancestor_concept_id,
    descendant_concept_id,
    min_levels_of_separation,
    max_levels_of_separation
FROM @etl_database.@etl_schema.voc_concept_ancestor;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.source_to_concept_map CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.source_to_concept_map AS
SELECT
    source_code,
    source_concept_id,
    source_vocabulary_id,
    source_code_description,
    target_concept_id,
    target_vocabulary_id,
    valid_start_DATE,
    valid_end_DATE,
    invalid_reason
FROM @etl_database.@etl_schema.voc_source_to_concept_map;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.drug_strength CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.drug_strength AS
SELECT
    drug_concept_id,
    ingredient_concept_id,
    amount_value,
    amount_unit_concept_id,
    numerator_value,
    numerator_unit_concept_id,
    denominator_value,
    denominator_unit_concept_id,
    box_size,
    valid_start_DATE,
    valid_end_DATE,
    invalid_reason
FROM @etl_database.@etl_schema.voc_drug_strength;


-- Copy CDM tables

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.cohort_definition CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.cohort_definition AS
SELECT
    cohort_definition_id,
    cohort_definition_name,
    cohort_definition_description,
    definition_type_concept_id,
    cohort_definition_syntax,
    subject_concept_id,
    cohort_initiation_date
FROM @etl_database.@etl_schema.cdm_cohort_definition;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.attribute_definition CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.attribute_definition AS
SELECT
    attribute_definition_id,
    attribute_name,
    attribute_description,
    attribute_type_concept_id,
    attribute_syntax
FROM @etl_database.@etl_schema.cdm_attribute_definition;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.cdm_source CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.cdm_source AS
SELECT
    cdm_source_name,
    cdm_source_abbreviation,
    cdm_holder,
    source_description,
    source_documentation_reference,
    cdm_etl_reference,
    source_release_date,
    cdm_release_date,
    cdm_version,
    vocabulary_version
FROM @etl_database.@etl_schema.cdm_cdm_source;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.metadata CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.metadata AS
SELECT
    metadata_concept_id,
    metadata_type_concept_id,
    name,
    value_as_string,
    value_as_concept_id,
    metadata_date,
    metadata_datetime
FROM @etl_database.@etl_schema.cdm_metadata;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.person CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.person AS
SELECT
    person_id,
    gender_concept_id,
    year_of_birth,
    month_of_birth,
    day_of_birth,
    birth_datetime,
    race_concept_id,
    ethnicity_concept_id,
    location_id,
    provider_id,
    care_site_id,
    person_source_value,
    gender_source_value,
    gender_source_concept_id,
    race_source_value,
    race_source_concept_id,
    ethnicity_source_value,
    ethnicity_source_concept_id
FROM @etl_database.@etl_schema.cdm_person;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.observation_period CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.observation_period AS
SELECT
    observation_period_id,
    person_id,
    observation_period_start_date,
    observation_period_end_date,
    period_type_concept_id
FROM @etl_database.@etl_schema.cdm_observation_period;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.specimen CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.specimen AS
SELECT
    specimen_id,
    person_id,
    specimen_concept_id,
    specimen_type_concept_id,
    specimen_date,
    specimen_datetime,
    quantity,
    unit_concept_id,
    anatomic_site_concept_id,
    disease_status_concept_id,
    specimen_source_id,
    specimen_source_value,
    unit_source_value,
    anatomic_site_source_value,
    disease_status_source_value
FROM @etl_database.@etl_schema.cdm_specimen;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.death CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.death AS
SELECT
    person_id,
    death_date,
    death_datetime,
    death_type_concept_id,
    cause_concept_id,
    cause_source_value,
    cause_source_concept_id
FROM @etl_database.@etl_schema.cdm_death;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.visit_occurrence CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.visit_occurrence AS
SELECT
    visit_occurrence_id,
    person_id,
    visit_concept_id,
    visit_start_date,
    visit_start_datetime,
    visit_end_date,
    visit_end_datetime,
    visit_type_concept_id,
    provider_id,
    care_site_id,
    visit_source_value,
    visit_source_concept_id,
    admitting_source_concept_id,
    admitting_source_value,
    discharge_to_concept_id,
    discharge_to_source_value,
    preceding_visit_occurrence_id
FROM @etl_database.@etl_schema.cdm_visit_occurrence;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.visit_detail CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.visit_detail AS
SELECT
    visit_detail_id,
    person_id,
    visit_detail_concept_id,
    visit_detail_start_date,
    visit_detail_start_datetime,
    visit_detail_end_date,
    visit_detail_end_datetime,
    visit_detail_type_concept_id,
    provider_id,
    care_site_id,
    admitting_source_concept_id,
    discharge_to_concept_id,
    preceding_visit_detail_id,
    visit_detail_source_value,
    visit_detail_source_concept_id,
    admitting_source_value,
    discharge_to_source_value,
    visit_detail_parent_id,
    visit_occurrence_id
FROM @etl_database.@etl_schema.cdm_visit_detail;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.procedure_occurrence CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.procedure_occurrence AS
SELECT
    procedure_occurrence_id,
    person_id,
    procedure_concept_id,
    procedure_date,
    procedure_datetime,
    procedure_type_concept_id,
    modifier_concept_id,
    quantity,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    procedure_source_value,
    procedure_source_concept_id,
    modifier_source_value
FROM @etl_database.@etl_schema.cdm_procedure_occurrence;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.drug_exposure CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.drug_exposure AS
SELECT
    drug_exposure_id,
    person_id,
    drug_concept_id,
    drug_exposure_start_date,
    drug_exposure_start_datetime,
    drug_exposure_end_date,
    drug_exposure_end_datetime,
    verbatim_end_date,
    drug_type_concept_id,
    stop_reason,
    refills,
    quantity,
    days_supply,
    sig,
    route_concept_id,
    lot_number,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    drug_source_value,
    drug_source_concept_id,
    route_source_value,
    dose_unit_source_value
FROM @etl_database.@etl_schema.cdm_drug_exposure;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.device_exposure CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.device_exposure AS
SELECT
    device_exposure_id,
    person_id,
    device_concept_id,
    device_exposure_start_date,
    device_exposure_start_datetime,
    device_exposure_end_date,
    device_exposure_end_datetime,
    device_type_concept_id,
    unique_device_id,
    quantity,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    device_source_value,
    device_source_concept_id
FROM @etl_database.@etl_schema.cdm_device_exposure;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.condition_occurrence CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.condition_occurrence AS
SELECT
    condition_occurrence_id,
    person_id,
    condition_concept_id,
    condition_start_date,
    condition_start_datetime,
    condition_end_date,
    condition_end_datetime,
    condition_type_concept_id,
    stop_reason,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    condition_source_value,
    condition_source_concept_id,
    condition_status_source_value,
    condition_status_concept_id
FROM @etl_database.@etl_schema.cdm_condition_occurrence;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.measurement CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.measurement AS
SELECT
    measurement_id,
    person_id,
    measurement_concept_id,
    measurement_date,
    measurement_datetime,
    measurement_time,
    measurement_type_concept_id,
    operator_concept_id,
    value_as_number,
    value_as_concept_id,
    unit_concept_id,
    range_low,
    range_high,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    measurement_source_value,
    measurement_source_concept_id,
    unit_source_value,
    value_source_value
FROM @etl_database.@etl_schema.cdm_measurement;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.note CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.note AS
SELECT
    note_id,
    person_id,
    note_date,
    note_datetime,
    note_type_concept_id,
    note_class_concept_id,
    note_title,
    note_text,
    encoding_concept_id,
    language_concept_id,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    note_source_value
FROM @etl_database.@etl_schema.cdm_note;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.note_nlp CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.note_nlp AS
SELECT
    note_nlp_id,
    note_id,
    section_concept_id,
    snippet,
    offset_val,
    lexical_variant,
    note_nlp_concept_id,
    note_nlp_source_concept_id,
    nlp_system,
    nlp_date,
    nlp_datetime,
    term_exists,
    term_temporal,
    term_modifiers
FROM @etl_database.@etl_schema.cdm_note_nlp;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.observation CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.observation AS
SELECT
    observation_id,
    person_id,
    observation_concept_id,
    observation_date,
    observation_datetime,
    observation_type_concept_id,
    value_as_number,
    value_as_string,
    value_as_concept_id,
    qualifier_concept_id,
    unit_concept_id,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    observation_source_value,
    observation_source_concept_id,
    unit_source_value,
    qualifier_source_value
FROM @etl_database.@etl_schema.cdm_observation;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.fact_relationship CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.fact_relationship AS
SELECT
    domain_concept_id_1,
    fact_id_1,
    domain_concept_id_2,
    fact_id_2,
    relationship_concept_id
FROM @etl_database.@etl_schema.cdm_fact_relationship;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.location CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.location AS
SELECT
    location_id,
    address_1,
    address_2,
    city,
    state,
    zip,
    county,
    location_source_value
FROM @etl_database.@etl_schema.cdm_location;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.care_site CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.care_site AS
SELECT
    care_site_id,
    care_site_name,
    place_of_service_concept_id,
    location_id,
    care_site_source_value,
    place_of_service_source_value
FROM @etl_database.@etl_schema.cdm_care_site;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.provider CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.provider AS
SELECT
    provider_id,
    provider_name,
    npi,
    dea,
    specialty_concept_id,
    care_site_id,
    year_of_birth,
    gender_concept_id,
    provider_source_value,
    specialty_source_value,
    specialty_source_concept_id,
    gender_source_value,
    gender_source_concept_id
FROM @etl_database.@etl_schema.cdm_provider;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.payer_plan_period CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.payer_plan_period AS
SELECT
    payer_plan_period_id,
    person_id,
    payer_plan_period_start_date,
    payer_plan_period_end_date,
    payer_concept_id,
    payer_source_value,
    payer_source_concept_id,
    plan_concept_id,
    plan_source_value,
    plan_source_concept_id,
    sponsor_concept_id,
    sponsor_source_value,
    sponsor_source_concept_id,
    family_source_value,
    stop_reason_concept_id,
    stop_reason_source_value,
    stop_reason_source_concept_id
FROM @etl_database.@etl_schema.cdm_payer_plan_period;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.cost CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.cost AS
SELECT
    cost_id,
    cost_event_id,
    cost_domain_id,
    cost_type_concept_id,
    currency_concept_id,
    total_charge,
    total_cost,
    total_paid,
    paid_by_payer,
    paid_by_patient,
    paid_patient_copay,
    paid_patient_coinsurance,
    paid_patient_deductible,
    paid_by_primary,
    paid_ingredient_cost,
    paid_dispensing_fee,
    payer_plan_period_id,
    amount_allowed,
    revenue_code_concept_id,
    revenue_code_source_value,
    drg_concept_id,
    drg_source_value
FROM @etl_database.@etl_schema.cdm_cost;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.cohort CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.cohort AS
SELECT
    cohort_definition_id,
    subject_id,
    cohort_start_date,
    cohort_end_date
FROM @etl_database.@etl_schema.cdm_cohort;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.cohort_attribute CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.cohort_attribute AS
SELECT
    cohort_definition_id,
    subject_id,
    cohort_start_date,
    cohort_end_date,
    attribute_definition_id,
    value_as_number,
    value_as_concept_id
FROM @etl_database.@etl_schema.cdm_cohort_attribute;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.drug_era CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.drug_era AS
SELECT
    drug_era_id,
    person_id,
    drug_concept_id,
    drug_era_start_date,
    drug_era_end_date,
    drug_exposure_count,
    gap_days
FROM @etl_database.@etl_schema.cdm_drug_era;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.dose_era CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.dose_era AS
SELECT
    dose_era_id,
    person_id,
    drug_concept_id,
    unit_concept_id,
    dose_value,
    dose_era_start_date,
    dose_era_end_date
FROM @etl_database.@etl_schema.cdm_dose_era;


DROP TABLE IF EXISTS @atlas_database.@atlas_schema.condition_era CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.condition_era AS
SELECT
    condition_era_id,
    person_id,
    condition_concept_id,
    condition_era_start_date,
    condition_era_end_date,
    condition_occurrence_count
FROM @etl_database.@etl_schema.cdm_condition_era;

