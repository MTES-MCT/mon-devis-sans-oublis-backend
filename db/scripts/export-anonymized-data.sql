-- Script d'export des données anonymisées vers un fichier SQL

\o /tmp/anonymized_data.sql
\echo '-- Export des données anonymisées MDSO vers Metabase'
\echo 'BEGIN;'
\echo ''

-- Export simple avec SELECT *
\echo '-- Table quote_checks'
SELECT 'INSERT INTO quote_checks SELECT * FROM export_anonymized.quote_checks;';

\echo ''
\echo '-- Table quotes_cases'
SELECT 'INSERT INTO quotes_cases SELECT * FROM export_anonymized.quotes_cases;';

\echo ''
\echo '-- Table quote_check_feedbacks'
SELECT 'INSERT INTO quote_check_feedbacks SELECT * FROM export_anonymized.quote_check_feedbacks;';

\echo ''
\echo '-- Table quote_error_edits'
SELECT 'INSERT INTO quote_error_edits SELECT * FROM export_anonymized.quote_error_edits;';

\echo ''
\echo 'COMMIT;'
\o