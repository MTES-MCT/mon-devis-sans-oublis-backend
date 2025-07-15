-- Script d'anonymisation des données MDSO pour Metabase

-- Supprime et recrée le schéma pour cleaning
DROP SCHEMA IF EXISTS export_anonymized CASCADE;
CREATE SCHEMA export_anonymized;

-- 1. Tables techniques (exclusion pour sécurité)
-- EXCLU : active_storage_attachments (contient des liens vers fichiers sensibles)
-- EXCLU : active_storage_blobs (contient métadonnées des fichiers sensibles) 
-- EXCLU : active_storage_postgresql_files (contient le contenu binaire)

-- 2. Jobs (sans d'anonymisation)
CREATE TABLE export_anonymized.good_jobs AS 
SELECT * FROM good_jobs;

CREATE TABLE export_anonymized.processing_logs AS 
SELECT * FROM processing_logs;

-- 3. Quote files (anonymisation des contenus sensibles)
CREATE TABLE export_anonymized.quote_files AS 
SELECT 
    id,
    'devis_' || id || '.pdf' as filename,
    CASE 
        WHEN hexdigest IS NOT NULL THEN 'Contenu hexdigest anonymisé ' || id 
        ELSE NULL 
    END as hexdigest,
    uploaded_at, 
    created_at, 
    updated_at, 
    content_type,
    NULL as data, -- Exclure le contenu
    CASE 
        WHEN imagified_pages IS NOT NULL THEN 'Contenu imagified_pages anonymisé ' || id 
        ELSE NULL 
    END as imagified_pages,
    CASE 
        WHEN ocr IS NOT NULL THEN 'Contenu OCR anonymisé ' || id 
        ELSE NULL 
    END as ocr,
    security_scan_good, 
    force_ocr, 
    CASE 
        WHEN ocr_result IS NOT NULL THEN 'Contenu OCR result anonymisé ' || id 
        ELSE NULL 
    END as ocr_result
FROM quote_files;

-- 4. Quote checks (anonymisation des textes et commentaires)
CREATE TABLE export_anonymized.quote_checks AS 
SELECT 
    id, 
    file_id, 
    started_at, 
    finished_at, 
    profile,
    CASE 
        WHEN text IS NOT NULL THEN 'Texte de devis anonymisé ' || id
        ELSE NULL 
    END as text,
    anonymised_text,
    CASE 
        WHEN naive_attributes IS NOT NULL THEN 'Contenu naive_attributes anonymisé ' || id 
        ELSE NULL 
    END as naive_attributes,
    naive_version, 
    CASE 
        WHEN qa_attributes IS NOT NULL THEN 'Contenu qa_attributes anonymisé ' || id 
        ELSE NULL 
    END as qa_attributes,
    qa_version,
    CASE 
        WHEN read_attributes IS NOT NULL THEN 'Contenu read_attributes anonymisé ' || id 
        ELSE NULL 
    END as read_attributes,
    validation_errors, 
    validation_version,
    created_at, 
    updated_at, 
    CASE 
        WHEN qa_result IS NOT NULL THEN 'Contenu qa_result anonymisé ' || id 
        ELSE NULL 
    END as qa_result, 
    validation_error_details,
    parent_id, 
    -- private_data_qa_attributes, EXCLU
    -- private_data_qa_version, EXCLU
    -- private_data_qa_result, EXCLU
    metadata, 
    application_version,
    expected_validation_errors, 
    validation_error_edits,
    CASE 
        WHEN comment IS NOT NULL THEN 'Commentaire anonymisé'
        ELSE NULL 
    END as comment,
    commented_at, 
    validation_error_edited_at,
    CASE 
        WHEN file_text IS NOT NULL THEN 'Contenu fichier anonymisé ' || id
        ELSE NULL 
    END as file_text,
    CASE 
        WHEN file_markdown IS NOT NULL THEN 'Contenu markdown anonymisé ' || id
        ELSE NULL 
    END as file_markdown,
    source_name, 
    validation_controls_count, 
    case_id, 
    reference,
    renovation_type, 
    validation_control_codes
FROM quote_checks;

-- 5. Quote check feedbacks (anonymisation des emails et commentaires)
CREATE TABLE export_anonymized.quote_check_feedbacks AS 
SELECT 
    id, 
    quote_check_id, 
    validation_error_details_id,
    CASE 
        WHEN comment IS NOT NULL THEN 'Commentaire feedback anonymisé'
        ELSE NULL 
    END as comment,
    created_at, 
    updated_at,
    CASE 
        WHEN email IS NOT NULL THEN 'user_' || id || '@example.com'
        ELSE NULL 
    END as email,
    rating
FROM quote_check_feedbacks;

-- 6. Quotes cases
CREATE TABLE export_anonymized.quotes_cases AS 
SELECT * FROM quotes_cases;