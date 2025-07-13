-- Unload to ATLAS
-- extra tables (d_items to concept)

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.d_items_to_concept CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.d_items_to_concept AS
SELECT
    *
FROM @etl_database.@etl_schema.d_items_to_concept
;

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.d_labitems_to_concept CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.d_labitems_to_concept AS
SELECT
    *
FROM @etl_database.@etl_schema.d_labitems_to_concept
;

DROP TABLE IF EXISTS @atlas_database.@atlas_schema.d_micro_to_concept CASCADE;
CREATE TABLE @atlas_database.@atlas_schema.d_micro_to_concept AS
SELECT
    *
FROM @etl_database.@etl_schema.d_micro_to_concept
;

