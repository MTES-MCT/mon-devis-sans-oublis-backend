-- Script d'export des données anonymisées vers un fichier SQL
-- Génère les requêtes INSERT pour l'import dans Metabase

\o /tmp/anonymized_data.sql
\echo '-- Export des données anonymisées MDSO vers Metabase'
\echo 'BEGIN;'
\echo ''

-- Export de la table quote_checks
\echo '-- Table quote_checks'
\echo 'INSERT INTO quote_checks (id, status, created_at, updated_at, user_identifier, amount, region, work_type, energy_type) VALUES'
SELECT string_agg(
    '(' || 
    COALESCE(id::text, 'NULL') || ', ' ||
    COALESCE(quote_literal(status), 'NULL') || ', ' ||
    COALESCE(quote_literal(created_at::text), 'NULL') || '::timestamp, ' ||
    COALESCE(quote_literal(updated_at::text), 'NULL') || '::timestamp, ' ||
    COALESCE(quote_literal(user_identifier), 'NULL') || ', ' ||
    COALESCE(amount::text, 'NULL') || ', ' ||
    COALESCE(quote_literal(region), 'NULL') || ', ' ||
    COALESCE(quote_literal(work_type), 'NULL') || ', ' ||
    COALESCE(quote_literal(energy_type), 'NULL') ||
    ')',
    E',\n'
) || ';'
FROM export_anonymized.quote_checks;

\echo ''

-- Export de la table quote_check_feedbacks
\echo '-- Table quote_check_feedbacks'
\echo 'INSERT INTO quote_check_feedbacks (id, quote_check_id, rating, created_at, updated_at, comment) VALUES'
SELECT string_agg(
    '(' || 
    COALESCE(id::text, 'NULL') || ', ' ||
    COALESCE(quote_check_id::text, 'NULL') || ', ' ||
    COALESCE(rating::text, 'NULL') || ', ' ||
    COALESCE(quote_literal(created_at::text), 'NULL') || '::timestamp, ' ||
    COALESCE(quote_literal(updated_at::text), 'NULL') || '::timestamp, ' ||
    COALESCE(quote_literal(comment), 'NULL') ||
    ')',
    E',\n'
) || ';'
FROM export_anonymized.quote_check_feedbacks;

\echo ''

-- Export de la table quotes_cases
\echo '-- Table quotes_cases'
\echo 'INSERT INTO quotes_cases (id, quote_check_id, case_type, severity, created_at, updated_at, description) VALUES'
SELECT string_agg(
    '(' || 
    COALESCE(id::text, 'NULL') || ', ' ||
    COALESCE(quote_check_id::text, 'NULL') || ', ' ||
    COALESCE(quote_literal(case_type), 'NULL') || ', ' ||
    COALESCE(quote_literal(severity), 'NULL') || ', ' ||
    COALESCE(quote_literal(created_at::text), 'NULL') || '::timestamp, ' ||
    COALESCE(quote_literal(updated_at::text), 'NULL') || '::timestamp, ' ||
    COALESCE(quote_literal(description), 'NULL') ||
    ')',
    E',\n'
) || ';'
FROM export_anonymized.quotes_cases;

\echo ''
\echo 'COMMIT;'
\o