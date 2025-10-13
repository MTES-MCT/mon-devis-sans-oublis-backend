-- Script de nettoyage du schéma Metabase avant import
DROP SCHEMA IF EXISTS mdso_analytics CASCADE;

-- Recréation du schéma
CREATE SCHEMA mdso_analytics;

-- User "mon_devis_s_9315" extracted from Metabase Saclingo App $DATABASE_URL

-- Grant usage on schema
GRANT USAGE ON SCHEMA mdso_analytics TO mon_devis_s_9315;

-- Grant SELECT (read-only) on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA mdso_analytics TO mon_devis_s_9315;

-- Grant SELECT on future tables (optional, but recommended)
ALTER DEFAULT PRIVILEGES IN SCHEMA mdso_analytics 
    GRANT SELECT ON TABLES TO mon_devis_s_9315;
