-- Script d'export des données anonymisées vers des fichiers CSV dans le répertoire courant

-- Export de quote_checks
\copy (SELECT * FROM export_anonymized.quote_checks) TO './quote_checks.csv' WITH CSV HEADER;

-- Export de quotes_cases  
\copy (SELECT * FROM export_anonymized.quotes_cases) TO './quotes_cases.csv' WITH CSV HEADER;

-- Export de quote_check_feedbacks
\copy (SELECT * FROM export_anonymized.quote_check_feedbacks) TO './quote_check_feedbacks.csv' WITH CSV HEADER;

-- Export de quote_error_edits
\copy (SELECT * FROM export_anonymized.quote_error_edits) TO './quote_error_edits.csv' WITH CSV HEADER;

-- Export de processing_logs
\copy (SELECT * FROM export_anonymized.processing_logs) TO './processing_logs.csv' WITH CSV HEADER;