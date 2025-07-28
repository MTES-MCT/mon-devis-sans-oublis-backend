#!/bin/bash
set -e

echo "=== Export et anonymisation DB MDSO vers Metabase (CSV) ==="

# Vérification si l'export est activé
if [ "$ENABLE_METABASE_EXPORT" != "true" ]; then
    echo "Export Metabase désactivé (ENABLE_METABASE_EXPORT != 'true')"
    echo "Pour activer: export ENABLE_METABASE_EXPORT=true"
    exit 0
fi

echo "Export Metabase activé, démarrage..."

# Variables d'environnement
SOURCE_DB_URL="${DATABASE_URL}"
TARGET_DB_URL="${METABASE_DATA_DB_URL}"
SCRIPT_DIR="$(dirname "$0")"

# Définition du répertoire cible
if [ -w "/app" ]; then
    WORK_DIR="/app"
elif [ -w "." ]; then
    WORK_DIR="."
else
    WORK_DIR="/tmp"
fi

echo "Répertoire : $WORK_DIR"

# Chemins des fichiers CSV
CSV_FILES=(
    "$WORK_DIR/quote_checks.csv" 
    "$WORK_DIR/quotes_cases.csv" 
    "$WORK_DIR/quote_check_feedbacks.csv" 
    "$WORK_DIR/quote_error_edits.csv"
    "$WORK_DIR/processing_logs.csv"
)

# Fonction de nettoyage des fichiers CSV
cleanup_csv_files() {
    echo "Nettoyage des fichiers CSV temporaires..."
    for file in "${CSV_FILES[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "Supprimé: $file"
        fi
    done
}

# Fonction de gestion d'erreur
handle_error() {
    echo "Erreur durant l'export"
    cleanup_csv_files
    # Log seulement si la table existe
    psql $SOURCE_DB_URL -c "INSERT INTO export_logs (status, message) VALUES ('error', 'Erreur durant l export CSV');" 2>/dev/null || true
    exit 1
}

# Capture les erreurs et nettoyage automatique
trap 'handle_error' ERR
trap 'cleanup_csv_files' EXIT

# Vérifications
if [ -z "$SOURCE_DB_URL" ]; then
    echo "Erreur: DATABASE_URL non définie"
    exit 1
fi

if [ -z "$TARGET_DB_URL" ]; then
    echo "Erreur: METABASE_DATA_DB_URL non définie"
    exit 1
fi

# Vérification des fichiers SQL nécessaires
REQUIRED_FILES=("anonymize-data.sql" "cleanup-metabase.sql" "export-anonymized-data.sql" "import-csv-to-metabase.sql" "cleanup-anonymized-source-data.sql")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo "Erreur: Fichier $file introuvable"
        exit 1
    fi
done

# Nettoyage des fichiers CSV existants
cleanup_csv_files

echo "Étape 1: Création des tables anonymisées dans la DB source..."
psql $SOURCE_DB_URL -f "$SCRIPT_DIR/anonymize-data.sql"

# Log de démarrage
psql $SOURCE_DB_URL -c "INSERT INTO export_logs (status, message) VALUES ('started', 'Export CSV en cours');"

echo "Étape 2: Export des données anonymisées vers CSV..."
# Se placer dans le bon répertoire pour l'export
cd "$WORK_DIR"
psql $SOURCE_DB_URL -f "$SCRIPT_DIR/export-anonymized-data.sql"

# Vérification que les CSV ont été créés
echo "Vérification des fichiers CSV créés..."
for file in "${CSV_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Erreur: Fichier CSV manquant: $file"
        exit 1
    fi
    lines=$(wc -l < "$file")
    size=$(du -h "$file" | cut -f1)
    echo "Fichier créé: $(basename $file) ($lines lignes, $size)"
done

echo "Étape 3: Nettoyage de la DB Metabase..."
psql $TARGET_DB_URL -f "$SCRIPT_DIR/cleanup-metabase.sql"

echo "Étape 4: Import des CSV vers Metabase..."
psql $TARGET_DB_URL -f "$SCRIPT_DIR/import-csv-to-metabase.sql"

echo "Étape 5: Nettoyage du schéma temporaire..."
psql $SOURCE_DB_URL -f "$SCRIPT_DIR/cleanup-anonymized-source-data.sql"

# Comptage des enregistrements exportés
TOTAL_RECORDS=$(psql $TARGET_DB_URL -t -c "
SELECT 
    (SELECT count(*) FROM mdso_analytics.quote_checks) +
    (SELECT count(*) FROM mdso_analytics.quote_check_feedbacks) +
    (SELECT count(*) FROM mdso_analytics.quotes_cases) +
    (SELECT count(*) FROM mdso_analytics.quote_error_edits) +
    (SELECT count(*) FROM mdso_analytics.processing_logs)
;" | tr -d ' ' || echo "0")

# Log de succès
psql $SOURCE_DB_URL -c "INSERT INTO export_logs (status, message, records_exported) VALUES ('success', 'Export CSV terminé avec succès', $TOTAL_RECORDS);"

echo "=== Export CSV terminé avec succès ==="
echo "Total enregistrements exportés: $TOTAL_RECORDS"

# Statistiques finales
echo "Tables créées dans le schéma mdso_analytics :"
psql $TARGET_DB_URL -c "\dt mdso_analytics.*"

echo ""
echo "Nombre d'enregistrements par table :"
psql $TARGET_DB_URL -c "
SELECT 'quote_checks' as table_name, count(*) as count FROM mdso_analytics.quote_checks
UNION ALL
SELECT 'quote_check_feedbacks' as table_name, count(*) as count FROM mdso_analytics.quote_check_feedbacks
UNION ALL
SELECT 'quotes_cases' as table_name, count(*) as count FROM mdso_analytics.quotes_cases
UNION ALL
SELECT 'quote_error_edits' as table_name, count(*) as count FROM mdso_analytics.quote_error_edits
UNION ALL
SELECT 'processing_logs' as table_name, count(*) as count FROM mdso_analytics.processing_logs
ORDER BY table_name;
"