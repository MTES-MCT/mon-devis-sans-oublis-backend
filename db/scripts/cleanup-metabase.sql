-- Script de nettoyage de la DB Metabase avant import
-- Supprime toutes les tables de données existantes

DROP TABLE IF EXISTS quote_check_feedbacks CASCADE;
DROP TABLE IF EXISTS quote_checks CASCADE;
DROP TABLE IF EXISTS quote_files CASCADE;
DROP TABLE IF EXISTS quotes_cases CASCADE;
DROP TABLE IF EXISTS processing_logs CASCADE;
DROP TABLE IF EXISTS good_jobs CASCADE;
DROP TABLE IF EXISTS active_storage_blobs CASCADE;
DROP TABLE IF EXISTS active_storage_attachments CASCADE;