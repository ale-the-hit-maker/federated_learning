-- -------------------------------------------------------------------
-- @2020, Odysseus Data Services, Inc. All rights reserved
-- MIMIC IV CDM Conversion - PostgreSQL Version
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- Unload cross-reference table for itemid mapping
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- d_items.itemid to concept_id
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.d_items_to_concept;

CREATE TABLE @etl_database.@etl_schema.d_items_to_concept AS
WITH
counts AS
(
    -- d_items for chartevents
    SELECT
        -- itemid
        src.itemid                  AS itemid,
        src.source_label            AS source_label,
        src.source_vocabulary_id    AS source_vocabulary_id,
        src.source_concept_id       AS source_concept_id,
        src.target_concept_id       AS target_concept_id,
        COUNT(*)                    AS row_count
    FROM
        @etl_database.@etl_schema.lk_chartevents_mapped src
    GROUP BY
        src.itemid,
        src.source_label,
        src.source_vocabulary_id,
        src.source_concept_id,
        src.target_concept_id

    UNION ALL

    -- d_items for procedureevents and datetimeevents
    SELECT
        -- itemid
        src.itemid                  AS itemid,
        src.source_label            AS source_label,
        src.source_vocabulary_id    AS source_vocabulary_id,
        src.source_concept_id       AS source_concept_id,
        src.target_concept_id       AS target_concept_id,
        COUNT(*)                    AS row_count
    FROM
        @etl_database.@etl_schema.lk_procedure_mapped src
    WHERE
        src.unit_id LIKE '%.procedureevents'
        OR src.unit_id LIKE '%.datetimeevents'
    GROUP BY
        src.itemid,
        src.source_label,
        src.source_vocabulary_id,
        src.source_concept_id,
        src.target_concept_id
)
SELECT
    -- itemid
    src.itemid                      AS itemid,
    src.source_label                AS source_label,
    src.source_vocabulary_id        AS source_vocabulary_id,
    -- source concept
    vc.domain_id                    AS source_domain_id,
    src.source_concept_id           AS source_concept_id,
    vc.concept_name                 AS source_concept_name,
    -- target concept
    vc2.vocabulary_id               AS target_vocabulary_id,
    vc2.domain_id                   AS target_domain_id,
    src.target_concept_id           AS target_concept_id,
    vc2.concept_name                AS target_concept_name,
    vc2.standard_concept            AS target_standard_concept, -- for double-check
    src.row_count                   AS row_count
FROM
    counts src
LEFT JOIN
    @etl_database.@etl_schema.voc_concept vc
        ON  src.source_concept_id = vc.concept_id
LEFT JOIN
    @etl_database.@etl_schema.voc_concept vc2
        ON src.target_concept_id = vc2.concept_id
ORDER BY
    itemid, target_vocabulary_id, target_concept_id
;

-- -------------------------------------------------------------------
-- d_labitems.itemid to concept_id
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.d_labitems_to_concept;

CREATE TABLE @etl_database.@etl_schema.d_labitems_to_concept AS
WITH
counts AS
(
    SELECT
        itemid AS itemid, COUNT(*) AS row_count
    FROM
        @etl_database.@etl_schema.lk_meas_labevents_mapped
    GROUP BY itemid
)
SELECT
    -- itemid
    src.itemid                      AS itemid,
    src.loinc_code                  AS loinc_code,
    src.source_label                AS source_label,
    src.source_vocabulary_id        AS source_vocabulary_id,
    -- source concept
    src.source_domain_id            AS source_domain_id,
    src.source_concept_id           AS source_concept_id,
    src.source_concept_name         AS source_concept_name,
    -- target concept
    src.target_vocabulary_id        AS target_vocabulary_id,
    src.target_domain_id            AS target_domain_id,
    src.target_concept_id           AS target_concept_id,
    src.target_concept_name         AS target_concept_name,
    src.target_standard_concept     AS target_standard_concept, -- for double-check
    counts.row_count                AS row_count
FROM
    @etl_database.@etl_schema.lk_meas_d_labitems_concept src
LEFT JOIN
    counts
        USING (itemid)
ORDER BY
    itemid, target_vocabulary_id, target_concept_id
;


-- -------------------------------------------------------------------
-- d_micro.itemid to concept_id
-- -------------------------------------------------------------------

DROP TABLE IF EXISTS @etl_database.@etl_schema.d_micro_to_concept;

CREATE TABLE @etl_database.@etl_schema.d_micro_to_concept AS
WITH
counts AS
(
    SELECT
        spec_itemid AS itemid, COUNT(*) AS row_count
    FROM
        @etl_database.@etl_schema.lk_specimen_mapped
    GROUP BY itemid
    UNION ALL -- more unions
    SELECT
        test_itemid AS itemid, COUNT(*) AS row_count
    FROM
        @etl_database.@etl_schema.lk_meas_organism_mapped
    GROUP BY itemid
    UNION ALL -- more unions
    SELECT
        org_itemid AS itemid, COUNT(*) AS row_count
    FROM
        @etl_database.@etl_schema.lk_meas_organism_mapped
    GROUP BY itemid
    UNION ALL
    SELECT
        ab_itemid AS itemid, COUNT(*) AS row_count
    FROM
        @etl_database.@etl_schema.lk_meas_ab_mapped
    GROUP BY itemid
)
SELECT
    -- itemid
    src.itemid                      AS itemid,
    src.source_label                AS source_label,
    src.source_vocabulary_id        AS source_vocabulary_id,
    -- source concept
    src.source_domain_id            AS source_domain_id,
    src.source_concept_id           AS source_concept_id,
    src.source_concept_name         AS source_concept_name,
    -- target concept
    src.target_vocabulary_id        AS target_vocabulary_id,
    src.target_domain_id            AS target_domain_id,
    src.target_concept_id           AS target_concept_id,
    src.target_concept_name         AS target_concept_name,
    src.target_standard_concept     AS target_standard_concept, -- for double-check
    counts.row_count                AS row_count
FROM
    @etl_database.@etl_schema.lk_d_micro_concept src
LEFT JOIN
    counts
        USING (itemid)
LEFT JOIN
    @etl_database.@etl_schema.voc_concept vc
        ON  src.source_concept_id = vc.concept_id
LEFT JOIN
    @etl_database.@etl_schema.voc_concept vc2
        ON src.target_concept_id = vc2.concept_id
ORDER BY
    itemid, target_vocabulary_id, target_concept_id
;