-- Script de nettoyage du schéma Metabase avant import
DROP SCHEMA IF EXISTS mdso_analytics CASCADE;

-- Recréation du schéma
CREATE SCHEMA mdso_analytics;