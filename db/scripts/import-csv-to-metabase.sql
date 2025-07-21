-- Script d'import des CSV vers la DB Metabase dans le schéma mdso_analytics

BEGIN;

-- Création et import quote_checks
CREATE TABLE mdso_analytics.quote_checks (
    id UUID,
    profile VARCHAR(50),
    renovation_type VARCHAR(100),
    source_name VARCHAR(100),
    validation_controls_count INTEGER,
    validation_errors JSONB,
    validation_control_codes JSONB,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    case_id UUID,
    parent_id UUID,
    reference VARCHAR(100),
    validation_error_edited_at TIMESTAMP,
    text TEXT,
    comment TEXT
);

\copy mdso_analytics.quote_checks FROM './quote_checks.csv' WITH CSV HEADER;

-- Création et import quotes_cases
CREATE TABLE mdso_analytics.quotes_cases (
    id UUID,
    profile VARCHAR(50),
    renovation_type VARCHAR(100),
    source_name VARCHAR(100),
    validation_controls_count INTEGER,
    validation_errors JSONB,
    validation_control_codes JSONB,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    finished_at TIMESTAMP,
    reference VARCHAR(100)
);

\copy mdso_analytics.quotes_cases FROM './quotes_cases.csv' WITH CSV HEADER;

-- Création et import quote_check_feedbacks
CREATE TABLE mdso_analytics.quote_check_feedbacks (
    id UUID,
    quote_check_id UUID,
    validation_error_details_id VARCHAR(100),
    rating INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    email VARCHAR(100),
    comment TEXT
);

\copy mdso_analytics.quote_check_feedbacks FROM './quote_check_feedbacks.csv' WITH CSV HEADER;

-- Création et import quote_error_edits
CREATE TABLE mdso_analytics.quote_error_edits (
    id UUID,
    validation_error_edits JSONB,
    validation_error_edited_at TIMESTAMP,
    created_at TIMESTAMP
);

\copy mdso_analytics.quote_error_edits FROM './quote_error_edits.csv' WITH CSV HEADER;

COMMIT;