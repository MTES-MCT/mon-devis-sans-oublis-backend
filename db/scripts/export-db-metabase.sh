#!/bin/bash
set -e

echo "=== Export et anonymisation DB MDSO vers Metabase ==="

# Variables d'environnement
SOURCE_DB_URL="${DATABASE_URL}"
TARGET_DB_URL="${METABASE_DATA_DB_URL}"
SCRIPT_DIR="$(dirname "$0")"

# Vérifications
if [ -z "$SOURCE_DB_URL" ]; then
    echo "Erreur: DATABASE_URL non définie"
    exit 1
fi

if [ -z "$TARGET_DB_URL" ]; then
    echo "Erreur: METABASE_DATA_DB_URL non définie"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/anonymize-data.sql" ]; then
    echo "Erreur: Fichier anonymize-data.sql introuvable"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/cleanup_metabase_db.sql" ]; then
    echo "Erreur: Fichier cleanup_metabase_db.sql introuvable"
    exit 1
fi

echo "Étape 1: Création des tables anonymisées dans la DB source..."
psql $SOURCE_DB_URL -f "$SCRIPT_DIR/anonymize-data.sql"

echo "Étape 2: Export des données anonymisées..."
pg_dump $SOURCE_DB_URL \
    --schema=export_anonymized \
    --data-only \
    --inserts \
    --no-owner \
    --no-privileges > /tmp/anonymized_data.sql

# Enlever le préfixe du schéma dans le dump
sed -i 's/export_anonymized\.//g' /tmp/anonymized_data.sql

echo "Étape 3: Nettoyage de la DB Metabase..."
psql $TARGET_DB_URL -f "$SCRIPT_DIR/cleanup_metabase_db.sql"

echo "Étape 4: Import des données vers Metabase..."
psql $TARGET_DB_URL -f /tmp/anonymized_data.sql

echo "Étape 5: Nettoyage des fichiers temporaires..."
rm -f /tmp/anonymized_data.sql

# Nettoyage du schéma temporaire dans la DB source
echo "Étape 6: Nettoyage du schéma temporaire..."
psql $SOURCE_DB_URL -c "DROP SCHEMA IF EXISTS export_anonymized CASCADE;"

echo "=== Export terminé avec succès ==="

# Statistiques finales
echo "Tables créées dans la DB Metabase :"
psql $TARGET_DB_URL -c "\dt"

echo ""
echo "Nombre d'enregistrements par table :"
psql $TARGET_DB_URL -c "
SELECT 'quote_checks' as table_name, count(*) as count FROM quote_checks
UNION ALL
SELECT 'quote_files' as table_name, count(*) as count FROM quote_files  
UNION ALL
SELECT 'quote_check_feedbacks' as table_name, count(*) as count FROM quote_check_feedbacks
UNION ALL
SELECT 'quotes_cases' as table_name, count(*) as count FROM quotes_cases
ORDER BY table_name;
"