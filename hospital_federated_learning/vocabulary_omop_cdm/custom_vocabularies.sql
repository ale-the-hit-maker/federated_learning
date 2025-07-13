-- -------------------------------------------------------------------
-- @2019, Odysseus Data Services, Inc. All rights reserved
-- MODIFIED FOR POSTGRESQL by Alessandro & Gemini
-- Last updated: 2025-05-18
-- -------------------------------------------------------------------

-- -------------------------------------------------------------------
-- Load custom mappings from tmp_custom_mapping to concept, concept_relationship, and vocabulary.
--
-- Source table:
-- omop_cdm.tmp_custom_mapping
-- -------------------------------------------------------------------

\echo 'Inizio processamento vocabolari custom da omop_cdm.tmp_custom_mapping per PostgreSQL...'

-- -- temp create backup (DECOMMENTA SE VUOI ESEGUIRE I BACKUP OGNI VOLTA)
-- \echo 'Creazione backup tabelle vocabolario...'
-- CREATE TABLE omop_cdm.concept_bak_custom_load AS SELECT * FROM omop_cdm.concept;
-- CREATE TABLE omop_cdm.concept_relationship_bak_custom_load AS SELECT * FROM omop_cdm.concept_relationship;
-- CREATE TABLE omop_cdm.vocabulary_bak_custom_load AS SELECT * FROM omop_cdm.vocabulary;
-- \echo 'Backup completato.'

-- -------------------------------------------------------------------
-- Verifica o creazione dei vincoli di chiave primaria e unicità
-- -------------------------------------------------------------------

\echo 'Verifica e creazione dei vincoli necessari sulle tabelle...'

-- Verifica e creazione del vincolo di chiave primaria su concept
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'xpk_concept' AND conrelid = 'omop_cdm.concept'::regclass
    ) THEN
        ALTER TABLE omop_cdm.concept ADD CONSTRAINT xpk_concept PRIMARY KEY (concept_id);
        RAISE NOTICE 'Aggiunto vincolo di chiave primaria a omop_cdm.concept';
    END IF;
END $$;

-- Verifica e creazione del vincolo di chiave primaria composta su concept_relationship
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'xpk_concept_relationship' AND conrelid = 'omop_cdm.concept_relationship'::regclass
    ) THEN
        ALTER TABLE omop_cdm.concept_relationship ADD CONSTRAINT xpk_concept_relationship PRIMARY KEY (concept_id_1, concept_id_2, relationship_id);
        RAISE NOTICE 'Aggiunto vincolo di chiave primaria a omop_cdm.concept_relationship';
    END IF;
END $$;

-- Verifica e creazione del vincolo di chiave primaria su vocabulary
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'xpk_vocabulary' AND conrelid = 'omop_cdm.vocabulary'::regclass
    ) THEN
        ALTER TABLE omop_cdm.vocabulary ADD CONSTRAINT xpk_vocabulary PRIMARY KEY (vocabulary_id);
        RAISE NOTICE 'Aggiunto vincolo di chiave primaria a omop_cdm.vocabulary';
    END IF;
END $$;

-- -------------------------------------------------------------------
-- Creazione tabelle temporanee intermedie basate su tmp_custom_mapping
-- -------------------------------------------------------------------

-- tmp_custom_concept
\echo 'Creazione omop_cdm.tmp_custom_concept...'
DROP TABLE IF EXISTS omop_cdm.tmp_custom_concept;
CREATE TABLE omop_cdm.tmp_custom_concept AS
SELECT
    voc.source_concept_id           AS concept_id,
    voc.concept_name                AS concept_name,
    voc.source_domain_id            AS domain_id,
    voc.source_vocabulary_id        AS vocabulary_id,
    voc.source_concept_class_id     AS concept_class_id,
    CASE
        WHEN voc.target_concept_id = 0 THEN 'S' -- Se target_id è 0, il source_concept è lo standard
        ELSE voc.standard_concept
    END                             AS standard_concept,
    voc.concept_code                AS concept_code,
    TO_DATE(voc.valid_start_date, 'YYYY-MM-DD')     AS valid_start_date,
    TO_DATE(voc.valid_end_date, 'YYYY-MM-DD')       AS valid_end_date,
    voc.invalid_reason              AS invalid_reason,
    CAST('tmp_custom_mapping' AS VARCHAR(255))      AS load_table_id, -- Tipo VARCHAR per PostgreSQL
    CAST(NULL AS BIGINT)            AS load_row_id
FROM
    omop_cdm.tmp_custom_mapping voc
GROUP BY -- Per ottenere definizioni uniche di concetti dalla tabella di staging
    voc.source_concept_id,
    voc.concept_name,
    voc.source_domain_id,
    voc.source_vocabulary_id,
    voc.source_concept_class_id,
    CASE
        WHEN voc.target_concept_id = 0 THEN 'S'
        ELSE voc.standard_concept
    END,
    voc.concept_code,
    voc.valid_start_date, 
    voc.valid_end_date,
    voc.invalid_reason;

-- tmp_custom_concept_relationship
\echo 'Creazione omop_cdm.tmp_custom_concept_relationship...'
DROP TABLE IF EXISTS omop_cdm.tmp_custom_concept_relationship;
CREATE TABLE omop_cdm.tmp_custom_concept_relationship AS
SELECT
    tcr.source_concept_id           AS concept_id_1,
    CASE
        WHEN tcr.target_concept_id = 0 THEN tcr.source_concept_id -- Auto-mappatura se target_id è 0
        ELSE tcr.target_concept_id
    END                             AS concept_id_2,
    tcr.relationship_id             AS relationship_id,
    TO_DATE(tcr.relationship_valid_start_date, 'YYYY-MM-DD') AS valid_start_date,
    TO_DATE(tcr.relationship_end_date, 'YYYY-MM-DD')         AS valid_end_date,
    tcr.invalid_reason_cr           AS invalid_reason,
    CAST('tmp_custom_mapping' AS VARCHAR(255))      AS load_table_id,
    CAST(NULL AS BIGINT)            AS load_row_id
FROM
    omop_cdm.tmp_custom_mapping tcr
WHERE
    tcr.target_concept_id IS NOT NULL -- Processa solo se c'è un target per la relazione

UNION ALL

SELECT
    CASE
        WHEN tcr.target_concept_id = 0 THEN tcr.source_concept_id
        ELSE tcr.target_concept_id
    END                             AS concept_id_1,
    tcr.source_concept_id           AS concept_id_2,
    tcr.reverse_relationship_id    AS relationship_id, -- Mantenendo l'typo originale
    TO_DATE(tcr.relationship_valid_start_date, 'YYYY-MM-DD') AS valid_start_date,
    TO_DATE(tcr.relationship_end_date, 'YYYY-MM-DD')         AS valid_end_date,
    tcr.invalid_reason_cr           AS invalid_reason,
    CAST('tmp_custom_mapping' AS VARCHAR(255))      AS load_table_id,
    CAST(NULL AS BIGINT)            AS load_row_id
FROM
    omop_cdm.tmp_custom_mapping tcr
WHERE
    tcr.target_concept_id IS NOT NULL
    AND tcr.reverse_relationship_id IS NOT NULL AND tcr.reverse_relationship_id <> ''; -- Considera solo se esiste una relazione inversa

-- tmp_custom_vocabulary
\echo 'Creazione omop_cdm.tmp_custom_vocabulary...'
DROP TABLE IF EXISTS omop_cdm.tmp_custom_vocabulary_dist;
CREATE TABLE omop_cdm.tmp_custom_vocabulary_dist AS
SELECT
    voc.source_vocabulary_id        AS source_vocabulary_id,
    CAST('tmp_custom_mapping' AS VARCHAR(255)) AS load_table_id, -- Aggiunto per coerenza con tmp_custom_vocabulary
    CAST(NULL AS BIGINT) AS load_row_id -- Aggiunto per coerenza con tmp_custom_vocabulary
FROM
    omop_cdm.tmp_custom_mapping voc
WHERE voc.source_vocabulary_id IS NOT NULL AND voc.source_vocabulary_id <> '' -- Evita vocabolari vuoti
GROUP BY
    voc.source_vocabulary_id;

DROP TABLE IF EXISTS omop_cdm.tmp_custom_vocabulary;
CREATE TABLE omop_cdm.tmp_custom_vocabulary AS
SELECT
    dist.source_vocabulary_id        AS vocabulary_id,
    dist.source_vocabulary_id        AS vocabulary_name, -- Nome uguale all'ID per i custom, si può affinare
    'Locally generated for MIMIC ETL' AS vocabulary_reference, -- Riferimento più specifico
    CAST(NULL AS VARCHAR(255))      AS vocabulary_version,   -- Tipo VARCHAR per PostgreSQL
    -- Assicurati che questo range di ID per vocabulary_concept_id non si sovrapponga
    -- ai concept_id usati dai vocabolari standard (di solito < 70 o < 200 per i vocabolari stessi)
    -- e ai tuoi source_concept_id se sono pre-assegnati.
    -- Un range sicuro per vocabulary_concept_id potrebbe essere diverso da quello dei concept_id > 2 miliardi.
    -- Qui usiamo un offset da un valore base per i vocabolari custom.
    -- Se hai pochi vocabolari custom, puoi anche assegnarli manualmente o usare una sequenza.
    (2000000000 + ROW_NUMBER() OVER (ORDER BY dist.source_vocabulary_id)) AS vocabulary_concept_id,
    dist.load_table_id               AS load_table_id,
    dist.load_row_id                 AS load_row_id
FROM
    omop_cdm.tmp_custom_vocabulary_dist dist;

DROP TABLE IF EXISTS omop_cdm.tmp_custom_vocabulary_dist;

-- -------------------------------------------------------------------
-- Riscrittura delle tabelle OMOP finali: concept, concept_relationship, vocabulary
-- Questo approccio rimuove i vecchi concetti/relazioni/vocabolari custom (ID > 2 miliardi)
-- e inserisce quelli nuovi da tmp_custom_*.
-- -------------------------------------------------------------------

-- CONCEPT
\echo 'Aggiornamento tabella omop_cdm.concept...'
DROP TABLE IF EXISTS omop_cdm.tmp_voc_concept_standard;
CREATE TEMP TABLE tmp_voc_concept_standard AS -- Usiamo una tabella temporanea di sessione
SELECT *
FROM omop_cdm.concept
WHERE concept_id < 2000000000; -- Mantiene solo i concetti standard

-- Aggiungiamo l'indice alla tabella temporanea per ottimizzare l'operazione di INSERT seguente
CREATE UNIQUE INDEX idx_tmp_voc_concept_id ON tmp_voc_concept_standard(concept_id);

INSERT INTO tmp_voc_concept_standard (
    concept_id, concept_name, domain_id, vocabulary_id, concept_class_id,
    standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason
)
SELECT
    c.concept_id, c.concept_name, c.domain_id, c.vocabulary_id, c.concept_class_id,
    c.standard_concept, c.concept_code, c.valid_start_date, c.valid_end_date, c.invalid_reason
FROM omop_cdm.tmp_custom_concept c -- Inserisce i nuovi concetti custom
WHERE NOT EXISTS (
    SELECT 1 FROM tmp_voc_concept_standard ts
    WHERE ts.concept_id = c.concept_id
);

DROP TABLE IF EXISTS omop_cdm.concept;
CREATE TABLE omop_cdm.concept AS SELECT * FROM tmp_voc_concept_standard;
ALTER TABLE omop_cdm.concept ADD CONSTRAINT xpk_concept PRIMARY KEY (concept_id);
DROP TABLE tmp_voc_concept_standard; -- Pulizia tabella temporanea di sessione

-- CONCEPT_RELATIONSHIP
\echo 'Aggiornamento tabella omop_cdm.concept_relationship...'
DROP TABLE IF EXISTS omop_cdm.tmp_voc_concept_relationship_standard;
CREATE TEMP TABLE tmp_voc_concept_relationship_standard AS
SELECT cr.*
FROM omop_cdm.concept_relationship cr
JOIN omop_cdm.concept c1 ON cr.concept_id_1 = c1.concept_id AND c1.concept_id < 2000000000 -- Relazioni tra concetti standard
JOIN omop_cdm.concept c2 ON cr.concept_id_2 = c2.concept_id AND c2.concept_id < 2000000000;

-- Aggiungiamo un indice alla tabella temporanea per ottimizzare l'operazione di INSERT seguente
CREATE UNIQUE INDEX idx_tmp_rel_concept_ids ON tmp_voc_concept_relationship_standard(concept_id_1, concept_id_2, relationship_id);

INSERT INTO tmp_voc_concept_relationship_standard (
    concept_id_1, concept_id_2, relationship_id,
    valid_start_date, valid_end_date, invalid_reason
)
SELECT
    cr.concept_id_1, cr.concept_id_2, cr.relationship_id,
    cr.valid_start_date, cr.valid_end_date, cr.invalid_reason
FROM omop_cdm.tmp_custom_concept_relationship cr -- Inserisce le nuove relazioni custom
WHERE NOT EXISTS (
    SELECT 1 FROM tmp_voc_concept_relationship_standard trs
    WHERE trs.concept_id_1 = cr.concept_id_1
    AND trs.concept_id_2 = cr.concept_id_2
    AND trs.relationship_id = cr.relationship_id
);

DROP TABLE IF EXISTS omop_cdm.concept_relationship;
CREATE TABLE omop_cdm.concept_relationship AS SELECT * FROM tmp_voc_concept_relationship_standard;
ALTER TABLE omop_cdm.concept_relationship ADD CONSTRAINT xpk_concept_relationship PRIMARY KEY (concept_id_1, concept_id_2, relationship_id);
DROP TABLE tmp_voc_concept_relationship_standard;

-- VOCABULARY
\echo 'Aggiornamento tabella omop_cdm.vocabulary...'
DROP TABLE IF EXISTS omop_cdm.tmp_voc_vocabulary_standard;
CREATE TEMP TABLE tmp_voc_vocabulary_standard AS
SELECT *
FROM omop_cdm.vocabulary
WHERE vocabulary_concept_id < 2000000000; -- Mantiene solo i vocabolari standard

-- Aggiungiamo un indice alla tabella temporanea per ottimizzare le operazioni seguenti
CREATE UNIQUE INDEX idx_tmp_voc_vocabulary_id ON tmp_voc_vocabulary_standard(vocabulary_id);

-- Gestione vocabolari custom: usiamo un INSERT separato per ogni vocabolario custom
INSERT INTO tmp_voc_vocabulary_standard (
    vocabulary_id, vocabulary_name, vocabulary_reference,
    vocabulary_version, vocabulary_concept_id
)
SELECT
    v.vocabulary_id, v.vocabulary_name, v.vocabulary_reference,
    v.vocabulary_version, v.vocabulary_concept_id
FROM omop_cdm.tmp_custom_vocabulary v -- Inserisce i nuovi vocabolari custom
WHERE NOT EXISTS (
    SELECT 1 FROM tmp_voc_vocabulary_standard tvs
    WHERE tvs.vocabulary_id = v.vocabulary_id
);

-- Aggiorniamo i vocabolari esistenti che potrebbero avere lo stesso vocabulary_id
UPDATE tmp_voc_vocabulary_standard tvs
SET 
    vocabulary_name = v.vocabulary_name,
    vocabulary_reference = v.vocabulary_reference,
    vocabulary_version = v.vocabulary_version,
    vocabulary_concept_id = v.vocabulary_concept_id
FROM omop_cdm.tmp_custom_vocabulary v
WHERE tvs.vocabulary_id = v.vocabulary_id
AND tvs.vocabulary_concept_id >= 2000000000; -- Aggiorniamo solo i vocabolari custom esistenti

DROP TABLE IF EXISTS omop_cdm.vocabulary;
CREATE TABLE omop_cdm.vocabulary AS SELECT * FROM tmp_voc_vocabulary_standard;
ALTER TABLE omop_cdm.vocabulary ADD CONSTRAINT xpk_vocabulary PRIMARY KEY (vocabulary_id);
DROP TABLE tmp_voc_vocabulary_standard;

-- Inserimento dei concetti per i nuovi vocabolari custom in concept
-- Questo assicura che ogni vocabolario custom abbia una rappresentazione come concetto.
\echo 'Inserimento concetti per vocabolari custom nella tabella omop_cdm.concept...'
INSERT INTO omop_cdm.concept (
    concept_id, concept_name, domain_id, vocabulary_id, concept_class_id,
    standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason
)
SELECT
    vcv.vocabulary_concept_id   AS concept_id,
    vcv.vocabulary_name         AS concept_name,
    'Metadata'                  AS domain_id,       -- Come da script originale
    'Vocabulary'                AS vocabulary_id,   -- Il vocabulary_id per questi concetti è 'Vocabulary'
    'Vocabulary'                AS concept_class_id,-- Come da script originale
    'S'                         AS standard_concept,-- Come da script originale
    vcv.vocabulary_id           AS concept_code,    -- Usa vocabulary_id come concept_code per il concetto del vocabolario
    CAST('1970-01-01' AS DATE)  AS valid_start_date,
    CAST('2099-12-31' AS DATE)  AS valid_end_date,
    NULL                        AS invalid_reason
FROM
    omop_cdm.tmp_custom_vocabulary vcv -- Legge dalla tabella temporanea dei vocabolari custom
-- Controlla se il concept_id (che è vocabulary_concept_id) esiste già in concept
WHERE NOT EXISTS (
    SELECT 1 FROM omop_cdm.concept c
    WHERE c.concept_id = vcv.vocabulary_concept_id
);

-- -------------------------------------------------------------------
-- Creazione tabella tmp_custom_concept_skipped per diagnostica
-- -------------------------------------------------------------------
\echo 'Creazione tabella omop_cdm.tmp_custom_concept_skipped...'
DROP TABLE IF EXISTS omop_cdm.tmp_custom_concept_skipped;
CREATE TABLE omop_cdm.tmp_custom_concept_skipped AS
SELECT
    tcc.concept_id, tcc.concept_name AS custom_concept_name, vc.concept_name AS existing_concept_name,
    tcc.vocabulary_id AS custom_vocabulary_id, vc.vocabulary_id AS existing_vocabulary_id,
    tcc.concept_code AS custom_concept_code, vc.concept_code AS existing_concept_code
FROM
    omop_cdm.tmp_custom_concept tcc -- Concetti custom che volevamo inserire
INNER JOIN
    omop_cdm.concept vc           -- Concetti attualmente nella tabella finale (dopo il merge)
    ON  tcc.concept_id = vc.concept_id -- Stesso ID
    AND tcc.concept_name <> vc.concept_name; -- Ma nome diverso (o altri attributi chiave)

-- -------------------------------------------------------------------
-- Pulizia finale delle tabelle temporanee di questo script
-- (tmp_custom_mapping NON viene cancellata qui, potrebbe servire per debug)
-- -------------------------------------------------------------------
\echo 'Pulizia tabelle temporanee del processo custom (tranne tmp_custom_mapping)...'
DROP TABLE IF EXISTS omop_cdm.tmp_custom_concept;
DROP TABLE IF EXISTS omop_cdm.tmp_custom_concept_relationship;
DROP TABLE IF EXISTS omop_cdm.tmp_custom_vocabulary;
-- Le tabelle tmp_voc_* erano TEMP TABLE di sessione, quindi vengono droppate automaticamente
-- alla fine della sessione, ma è buona norma fare DROP esplicito se non servono più.
DROP TABLE IF EXISTS omop_cdm.tmp_voc_concept; -- Se create come persistenti
DROP TABLE IF EXISTS omop_cdm.tmp_voc_concept_relationship; -- Se create come persistenti
DROP TABLE IF EXISTS omop_cdm.tmp_voc_vocabulary; -- Se create come persistenti

\echo 'Processamento vocabolari custom completato.'
\echo 'Controllare omop_cdm.tmp_custom_concept_skipped per eventuali conflitti non gestiti.'