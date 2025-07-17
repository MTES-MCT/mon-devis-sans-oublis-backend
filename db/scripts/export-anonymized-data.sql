-- Script d'export des données anonymisées vers un fichier SQL

\o /tmp/anonymized_data.sql

\echo '-- Export des données anonymisées MDSO vers Metabase'
\echo 'BEGIN;'
\echo ''

\echo '-- Table quote_checks'
\echo 'CREATE TABLE quote_checks AS SELECT * FROM export_anonymized.quote_checks WHERE 1=0;'
\echo 'INSERT INTO quote_checks SELECT * FROM export_anonymized.quote_checks;'
\echo ''

\echo '-- Table quotes_cases'
\echo 'CREATE TABLE quotes_cases AS SELECT * FROM export_anonymized.quotes_cases WHERE 1=0;'
\echo 'INSERT INTO quotes_cases SELECT * FROM export_anonymized.quotes_cases;'
\echo ''

\echo '-- Table quote_check_feedbacks'
\echo 'CREATE TABLE quote_check_feedbacks AS SELECT * FROM export_anonymized.quote_check_feedbacks WHERE 1=0;'
\echo 'INSERT INTO quote_check_feedbacks SELECT * FROM export_anonymized.quote_check_feedbacks;'
\echo ''

\echo '-- Table quote_error_edits'
\echo 'CREATE TABLE quote_error_edits AS SELECT * FROM export_anonymized.quote_error_edits WHERE 1=0;'
\echo 'INSERT INTO quote_error_edits SELECT * FROM export_anonymized.quote_error_edits;'
\echo ''

\echo 'COMMIT;'

\o