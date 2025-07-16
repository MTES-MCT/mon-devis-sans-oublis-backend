-- Script de nettoyage de la DB Metabase avant import
DROP TABLE IF EXISTS quote_checks CASCADE;
DROP TABLE IF EXISTS quotes_cases CASCADE;
DROP TABLE IF EXISTS quote_check_feedbacks CASCADE;
DROP TABLE IF EXISTS quote_error_edits CASCADE;