#!/bin/bash
set -e

echo "=== Export et anonymisation DB MDSO vers Metabase ==="

# Variables d'environnement
SOURCE_DB_URL="${DATABASE_URL}"
TARGET_DB_URL="${METABASE_DATA_DB_URL}"
SCRIPT_DIR="$(dirname "$0")"

# Fonction de gestion d'erreur
handle_error() {
    echo "Erreur durant l'export"
    # Log seulement si la table existe
    psql $SOURCE_DB_URL -c "INSERT INTO export_logs (status, message) VALUES ('error', 'Erreur durant l export');" 2>/dev/null || true
    exit 1
}

# Capture les erreurs
trap 'handle_error' ERR

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

# Log de démarrage
psql $SOURCE_DB_URL -c "INSERT INTO export_logs (status, message) VALUES ('started', 'Export en cours');"

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

# Comptage des enregistrements exportés
TOTAL_RECORDS=$(psql $TARGET_DB_URL -t -c "
SELECT 
    (SELECT count(*) FROM quote_checks) +
    (SELECT count(*) FROM quote_check_feedbacks) +
    (SELECT count(*) FROM quotes_cases)
;" | tr -d ' ' || echo "0")

# Log de succès
psql $SOURCE_DB_URL -c "INSERT INTO export_logs (status, message, records_exported) VALUES ('success', 'Export terminé avec succès', $TOTAL_RECORDS);"

echo "=== Export terminé avec succès ==="
echo "Total enregistrements exportés: $TOTAL_RECORDS"

# Statistiques finales
echo "Tables créées dans la DB Metabase :"
psql $TARGET_DB_URL -c "\dt"

echo ""
echo "Nombre d'enregistrements par table :"
psql $TARGET_DB_URL -c "
SELECT 'quote_checks' as table_name, count(*) as count FROM quote_checks
UNION ALL
SELECT 'quote_check_feedbacks' as table_name, count(*) as count FROM quote_check_feedbacks
UNION ALL
SELECT 'quotes_cases' as table_name, count(*) as count FROM quotes_cases
ORDER BY table_name;
"