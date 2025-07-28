-- Script d'export analytics MDSO pour Metabase

-- 0. Table pour stocker les logs
CREATE TABLE IF NOT EXISTS export_logs (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(50) DEFAULT 'metabase_export',
    status VARCHAR(20) NOT NULL,
    message TEXT,
    records_exported INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tables simples avec données brutes pour analyses dans Metabase
DROP SCHEMA IF EXISTS export_anonymized CASCADE;
CREATE SCHEMA export_anonymized;

-- 1. Table principale des analyses de devis (avec anonymisation)
CREATE TABLE export_anonymized.quote_checks AS 
SELECT 
    id,
    profile,
    renovation_type,
    source_name,
    validation_controls_count,
    validation_errors,
    validation_control_codes,
    created_at,
    updated_at,
    started_at,
    finished_at,
    case_id,
    parent_id,
    reference,
    validation_error_edited_at,
    -- Anonymisation du texte sensible
    CASE 
        WHEN text IS NOT NULL THEN 'Contenu anonymisé pour export Metabase'
        ELSE NULL 
    END as text,
    CASE 
        WHEN comment IS NOT NULL THEN 'Commentaire anonymisé'
        ELSE NULL 
    END as comment
FROM quote_checks;

-- 2. Table des dossiers/cas
CREATE TABLE export_anonymized.quotes_cases AS 
SELECT 
    id,
    profile,
    renovation_type,
    source_name,
    validation_controls_count,
    validation_errors,
    validation_control_codes,
    created_at,
    updated_at,
    finished_at,
    reference
FROM quotes_cases;

-- 3. Table des feedbacks/corrections (avec anonymisation)
CREATE TABLE export_anonymized.quote_check_feedbacks AS 
SELECT 
    id,
    quote_check_id,
    validation_error_details_id,
    rating,
    created_at,
    updated_at,
    -- Anonymisation des données sensibles
    'email-anonymise@example.com' as email,
    CASE 
        WHEN comment IS NOT NULL THEN 'Commentaire anonymisé'
        ELSE NULL 
    END as comment
FROM quote_check_feedbacks;

-- 4. Table des modifications d'erreurs
CREATE TABLE export_anonymized.quote_error_edits AS 
SELECT 
    id,
    validation_error_edits,
    validation_error_edited_at,
    created_at
FROM quote_checks 
WHERE validation_error_edits IS NOT NULL;

-- 5. Table des logs de traitement (avec anonymisation)
CREATE TABLE export_anonymized.processing_logs AS
SELECT 
    id,
    tags,
    processable_type,
    processable_id,
    -- Conversion des JSONB en TEXT pour éviter les erreurs d'export
    CASE 
        WHEN input_parameters IS NULL THEN NULL
        ELSE input_parameters::text
    END as input_parameters,
    CASE 
        WHEN output_result IS NULL THEN NULL
        ELSE output_result::text
    END as output_result,
    started_at,
    finished_at
FROM processing_logs;
