# Mon Devis Sans Oublis (MDSO) - Backend

Plateforme d'analyse de conformité de devis pour accélérer la rénovation énergétique des logements en simplifiant l'instruction des dossiers d'aide.

🔗 **[Accéder à la plateforme](https://mon-devis-sans-oublis.beta.gouv.fr/)**

## Prérequis

- **Git** pour cloner le repository
- **Docker Desktop** (recommandé, pour l'exécution avec Docker)

si pas Docker :

- **Ruby** 3.x voir `.ruby-version`
- **Node.js** >= 18 voir `package.json`
- **PostgreSQL** 16 voir `docker-compose.yml`

## Installation

Clonez le repository et installez les dépendances :

```bash
git clone https://github.com/MTES-MCT/mon-devis-sans-oublis-backend.git
cd mon-devis-sans-oublis-backend
docker compose up
```

## Configuration de l'environnement

### Variables d'environnement requises

Configurez les variables d'environnement selon votre méthode d'exécution :

#### Pour l'exécution avec Node.js

1. Copiez le fichier `.env.example` en `.env.local` :

```bash
cp .env.example .env.local
```

2. Éditez le fichier `.env.local` avec les valeurs réelles pour votre environnement de développement.

⚠️ **Important** : Ne laissez jamais de variables d'environnement vides (ex: `VARIABLE=`). Si vous n'avez pas besoin d'une variable, commentez-la avec `#` ou supprimez la ligne complètement.

#### Pour l'exécution avec Docker

1. Copiez le fichier `.env.example` en `.env.docker` :

```bash
cp .env.example .env.docker
```

2. Éditez le fichier `.env.docker` avec les valeurs appropriées pour l'environnement Docker.

⚠️ **Important** : Ne laissez jamais de variables d'environnement vides (ex: `VARIABLE=`). Si vous n'avez pas besoin d'une variable, commentez-la avec `#` ou supprimez la ligne complètement.

### Variables d'environnement principales

| Variable                       | Description                           | Exemple                                                  | Requis    |
| ------------------------------ | ------------------------------------- | -------------------------------------------------------- | --------- |
| `ADEME_SKIP_SSL_VERIFICATION`                     | Ne pas vérifier la connexion SSL avec l'API ADEME             | `false`                            | Optionnel    |
| `ADMIN_EMAILS`                     | Mail ProConnect pouvant accédant aux Back Office             | `toto@gouv.fr,tata@gouv.fr`                            | Optionnel    |
| `ALBERT_API_KEY`                     |              | `longueClé`                            | Requis    |
| `ALBERT_MODEL`                     | Modèle Albert utilisé par défaut si disponible            | `neuralmagic/Meta-Llama-3.1-70B-Instruct-FP8`                            | Optionnel    |
| `APPLICATION_HOST`                     | Host du backend pour générer des liens et la connexion OAuth            | `http://localhost:3000`, `https://api.mon-devis-sans-oublis.beta.gouv.fr`                            | Requis    |
| `APP_ENV`                     | Environnement applicatif, différent du RAILS_ENV technique           | `development`, `staging`, `production`                            | Requis    |
| `BREVO_API_KEY`                     | Pour envoi de mails             | `longueClé`                            | Optionnel    |
| `BREVO_SMTP_USER_NAME`                     |              | `longueClé`                            | Optionnel    |
| `BREVO_SMTP_USER_PASSWORD`                     |              | `longueClé`                            | Optionnel    |
| `DATABASE_URL`                     | URI de connexion à la base PostgreSQL             | `postgresql://postgres:dummy@localhost:5433/development`, `$SCALINGO_POSTGRESQL_URL`                            | Requis    |
| `DEFAULT_EMAIL_FROM`                     |              | `toto@gouv.fr`                            | Optionnel    |
| `FRONTEND_APPLICATION_HOST`                     | Host du frontend pour autoriser API            | `http://localhost:3001`, `https://mon-devis-sans-oublis.beta.gouv.fr`                            | Optionnel    |
| `GOOD_JOB_PASSWORD`                     | Mot de passe accès au Back Office Jobs            | `secret`                            | Requis    |
| `GOOD_JOB_USERNAME`                     | Utilisateur accès au Back Office Jobs            | `secret`                            | Requis    |
| `MATOMO_SITE_ID`                     |             | `123`                            | Optionnel    |
| `MATOMO_TOKEN_AUTH`                     |             | `hash`                            | Optionnel    |
| `MDSO_API_KEY_FOR_MDSO`                     | Clé API pour frontend            | `hash` via `rake secret`                           | Optionnel    |
| `MDSO_API_KEY_FOR_PARTNER1`                     | Clé API pour PARTNER1            | `hash` via `rake secret`                           | Optionnel    |
| `MDSO_API_KEY_FOR_PARTNER2`                     | Clé API pour PARTNER2            | `hash` via `rake secret`                           | Optionnel    |
| `MDSO_API_PASSWORD`                     | Ancienne clé API pour frontend            | `hash` via `rake secret`                           | Optionnel    |
| `MDSO_OCR`                     | Système d'OCR à utiliser par défaut            | `MdsoOcrMarker` ou voir `Rails.application.config.ocrs_configured` | Optionnel    |
| `MDSO_OCR_API_KEY`                     | Clé API du système OCR MDSO            |                            | Optionnel    |
| `MDSO_OCR_HOST`                     | Host du système OCR MDSO            |                            | Optionnel    |
| `MDSO_OCR_MODEL`                     | Modèle du système OCR MDSO utilisé par défaut si disponible            |                            | Optionnel    |
| `MDSO_QUOTE_FILE_MAX_SIZE`                     | Taille du fichier maximum en MB, 50 par défaut            |                            | Optionnel    |
| `MDSO_SITE_PASSWORD`                     | Ancienne clé accès au Back Office            | `hash` via `rake secret`                           | Optionnel    |
| `MISTRAL_API_KEY`                     |              | `longueClé`                            | Requis    |
| `MISTRAL_MODEL`                     | Modèle Mistral utilisé par défaut si disponible            | `mistral-large-latest`                            | Optionnel    |
| `OCRABLE_UNDER_CARACTERS_COUNT`                     | Limite de caractères en deça de laquelle on tente l'OCR automatiquement           |                            | Optionnel    |
| `PRIVATE_DATA_QA_DEFAULT_LLM`                     | LLM utilisé pour extraire les données privées par défaut si disponible            | `mistral`                            | Optionnel    |
| `PRIVATE_DATA_QA_DEFAULT_MODEL`                     | Modèle utilisé pour extraire les données privées par défaut si disponible            | `mistral-large-latest`                            | Optionnel    |
| `PROCONNECT_CLIENT_ID`                     |             | `hash`                            | Optionnel    |
| `PROCONNECT_CLIENT_SECRET`                     |             | `hash`                            | Optionnel    |
| `PROCONNECT_DOMAIN`                     |             | `https://auth.agentconnect.gouv.fr/api/v2`, `https://fca.integ01.dev-agentconnect.fr/api/v2`                            | Optionnel    |
| `QUOTE_CHECK_EMAIL_RECIPIENTS`       | Emails pour être informé des dépôts | `toto@gouv.fr,tata@gouv.fr`                              | Optionnel |
| `RAILS_ENV`                     | Environnement global du framework             | `production` ou `development` en local                            | Optionnel    |
| `RAILS_INBOUND_EMAIL_PASSWORD`                     | Secret pour authentifier les appels emails             | via `bin/rails secret`                            | Optionnel    |
| `RNT_SKIP_SSL_VERIFICATION`                     | Ne pas vérifier la connexion SSL avec le Web Service RNT             | `false`                            | Optionnel    |
| `SENTRY_DSN`       | DSN Sentry pour le tracking d'erreurs | `https://xxx@sentry.io/xxx`                              | Optionnel |
| `SENTRY_ENVIRONMENT`       | Environnement Sentry pour le tracking d'erreurs | `$APP_ENV`                              | Optionnel |
| `WORKS_DATA_QA_DEFAULT_LLM`                     | LLM utilisé pour extraite les données travaux par défaut si disponible            | `mistral`                            | Optionnel    |
| `WORKS_DATA_QA_DEFAULT_MODEL`                     | Modèle utilisé pour extraite les données travaux par défaut si disponible            | `mistral-large-latest`                            | Optionnel    |

### Configuration Scalingo

Scalingo est notre hébergeur type PaaS applicatif :

#### Staging

```bash
APPLICATION_HOST=https://api.mon-devis-sans-oublis.beta.gouv.fr
APP_ENV=staging
DATABASE_URL=$SCALINGO_POSTGRESQL_URL
FRONTEND_APPLICATION_HOST=https://staging.mon-devis-sans-oublis.beta.gouv.fr
# SCALINGO_POSTGRESQL_URL=générer par Scalingo
```

#### Production

```bash
APPLICATION_HOST=https://api.staging.mon-devis-sans-oublis.beta.gouv.fr
APP_ENV=production
DATABASE_URL=$SCALINGO_POSTGRESQL_URL
FRONTEND_APPLICATION_HOST=https://mon-devis-sans-oublis.beta.gouv.fr
# SCALINGO_POSTGRESQL_URL=générer par Scalingo
```

## Technologies sous-jacente utilisées

- [Ruby on Rails](https://rubyonrails.org/) version 8 comme boîte à outil et socle technique applicatif ;
- le [DSFR](https://www.systeme-de-design.gouv.fr/) pour réutiliser les éléments graphiques officiels via la [librairie de
composants DSFR](https://github.com/betagouv/dsfr-view-components)
- PostgreSQL comme base de données pour stocker les données ;
- des solutions de LLM pour interroger les devis, via la boîte à outils [LangChain](https://rubydoc.info/gems/langchainrb)
***Albert API d'Etalab
*** Mistral.ai : données publiques et/ou anonymisées
*** Ollama : un modèle Llama local
- l'API Data de l'ADEME pour croiser les données d'entreprises qualifiées ;
- des annuaires officiels de professionnels pour croiser des données ;
- ~~[Publi.codes](https://publi.codes/) pour un moteur de validation basé sur des règles~~ (plus utilisé pour le moment) ;
- Sentry pour monitorer et être alerté en cas d'erreur ;
- Matomo pour mesurer et comprendre l'usage via des analytics ;
- RSpec comme framework de tests ;
- Rubocop (RSpec et Rails) pour le linting ;
- Docker pour avoir un environnement de développement ;
- ClamAV pour scanner les fichiers déposés.

## Moteur et fonctionnement interne / Architecture

```mermaid
sequenceDiagram
    actor User as Usager
    participant Frontend as Interface MDSO Frontend
    participant Backend as Interface MDSO Backend

    participant QuoteCheckCheckJob as Process traitement
    participant Albert LLM as API Albert AI LLM
    participant Albert OCR as API Albert AI OCR LLM
    participant MDSO OCR
    participant Mistral LLM as API Mistral AI LLM
    participant ~~Tesseract as Tesseract OCR~~

    participant BO as Back Office MDSO

    User->>Frontend: Choisi un dossier de rénovaiton d'ampleur donc multi-devis
    Frontend->>Backend: Créer un QuotesCase pour rassembler le dossier et les documents
    Frontend->>Backend: Transmet les fichiers un à un
    Backend->>Backend: Sauvegarde les fichiers QuoteFiles et génère des QuoteChecks associé au QuotesCase commun
    Backend->>Frontend: Identifiant pour suivre les statuts du QuotesCase global et des QuoteChecks

    User->>Frontend: Dépose un document type PDF
    Frontend->>Backend: Transmet le fichier
    Backend->>Backend: Sauvegarde le fichier QuoteFile et génère un QuoteCheck
    Backend->>Frontend: Identifiant pour suivre le statut du QuoteCheck

    activate QuoteCheckCheckJob
    Backend->>QuoteCheckCheckJob: process asynchrone démarrage
    Backend-->>Backend: Transformation du PDF en images par page (QuoteFileImagifyPdfJob)
    Backend-->>Backend: Vérification de la non présence de virus (QuoteFileSecurityScanJob)

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Extraction automatique du texte du PDF si bien formatté
    QuoteCheckCheckJob->>QuoteCheckCheckJob: Sinon extraction du texte via OCR (Albert / MDSO / Mistral / Tesseract) UNIQUEMENT VIA BO

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Extraction des données du texte via méthode naïve
    QuoteCheckCheckJob->>QuoteCheckCheckJob: Réduction du texte si conditions générales

    QuoteCheckCheckJob<<->>Albert LLM: Extraction des données personnelles et administratives
    QuoteCheckCheckJob<<->>SIRENE API: Extension des données commerciales via recherche SIRET
    QuoteCheckCheckJob<<->>ADEME API: Extension des données commerciales et certifications via recherche SIRET

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Anonymisation du texte
    
    QuoteCheckCheckJob->>Frontend: Si erreur lecture ou texte vide renvoit d'une erreur

    QuoteCheckCheckJob<<->>Mistral LLM: Extraction des données gestes et caractéristiques du texte anonymisé

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Validation des données selon algorithme Ruby maison et ajout d'erreurs, dont vérification cohérence avec données externes (SIRENE, ADEME)

    QuoteCheckCheckJob->>Backend: retours avec données et erreurs
    deactivate QuoteCheckCheckJob

    Backend->>Frontend: Retour API QuotesCase et/ou QuoteCheck(s) avec erreurs cohérence dossier à la volée et affichage du résultat
```

Nous suivons les recommendations et les conventions du framework Ruby on Rails et de la communauté.

- dossier `lib` : pour les parties isolées qui pourraient être externalisées, comme la communication avec des services externes
- dossier `app/services` : pour organiser la logique métier propre et interne à notre projet

Les fichiers devis sont traités par le `QuoteChecksController` qui les envoient aux services:

- `QuoteReader` lisant le devis brut puis extractant les information du devis de manière naïve en se basant sur le texte du PDF et via solutions LLM avec croisement de données d'annuaires publiques de la rénovation
- puis ces attributs de devis sont vérifier par le `QuoteValdiator` qui controlle un ensemble de règles et renvoit les erreurs correspondantes

### Processus de validation

- pour chaque document
  - la validation des informations administratives : présence, valeur et cohérence (SIRET / RGE si indiqué)
  - la validation des caractéristiques techniques des gestes : présence, valeur et cohérence
    - seul le SIRET est utilisé pour chercher un certificat RGE correspondant au type de geste
- pour un dossier : validation de la cohérence des informations entre les documents lorsque présentes

#### Forcer un devis à valide

```
quote_check_id = "76c35e1c-4d8d-479d-a62a-4f36511a5041"
QuoteCheck.find(quote_check_id).update!(validation_errors: nil, validation_error_edits: nil)
```

### Traitement des images via OCR

Différentes briques sont mises à contribution et encore en évaluation via le projet dédié [mon-devis-sans-oublis-backend-ocr](https://github.com/MTES-MCT/mon-devis-sans-oublis-backend-ocr)

- pour la reconnaissance des images et lire leur contenu via OCR dans ce projet
  - ~~Surya (Python)~~
  - ~~tesseract (natif)~~
- pour transformer les PDF en images
  - librairie Poppler `pdftoppm` (natif)
  - la gem MiniMagick (IM) `mini_magick` avec ImageMagick 6.9 (comme sur Scalingo) (natif)

#### Configurer un nouveau service OCR

- vérifier la disponibilité du service via `QuoteReader::Image::MdsoOcr.new("", "").models`
- ajouter une class dédiée type `QuoteReader::Image:MdsoOcrMarker`
- ajouter le nom de la classe dans `config/custom.rb`

### Tester un devis en local

`docker compose exec web rake 'quote_checks:create[tmp/devis_tests/DC004200PAC-Aireau+Chauffe eau thermo.pdf]' | less`

#### Vérifier un devis via email

En mode local `development`

Aller sur http://localhost:3000/rails/conductor/action_mailbox/inbound_emails pour suivre les mails entrants

#### Re-vérifier un devis

```
quote_check_id = "b9705194-02aa-4db7-bc38-5fc2dcb6ce58"
QuoteCheckCheckJob.perform_later(quote_check_id)
```

#### Débugguer anonymisation devis

```
quote_check_id = "47db654b-a9fb-453b-b36f-b0c362279233"
quote_check = QuoteCheck.find(quote_check_id)

file_text = quote_check.file_text || quote_check.text

quote_reader = QuoteReader::Global.new(
  quote_check.file.content,
  quote_check.file.content_type,
  quote_file: quote_check.file
)

private_attributes = quote_check.private_data_qa_attributes || {}
private_extended_attributes = TrackingHash.deep_merge_if_absent(
  private_attributes,
  QuoteDataExtender.new(private_attributes).extended_attributes
)

# From quote_reader.read(file_text:)
anonymized_text = QuoteReader::Anonymizer.new(file_text).anonymized_text(private_extended_attributes)
```

## API

- au format REST JSON
- protéger via authentification HTTP Basic avec Bearer hashé
- voir fichier de documentation de l'API  au format OpenAPI Swagger et interface bac à sable interractif sur `/api-docs`
- regénération et mise à jour de la documentation à partir des spécifications tests via `make doc`

### API Documentation

Nous utilisons Rswag en Ruby pour générer la documentation de notre API MDSO au format OpenAPI.

Elle est disponible dans le dossier `swagger`, avec une version interne à MDSO et une pour les partenaires avec accès API Key.

La documentation se met à jour via la commande `make doc` qui fait appelle au schéma des types situé dans `spec/swagger_helper.rb` et avec les tests `spec/requests/*+doc_spec.rb`.

### API Accès

- ajouter ou modifier la variable d'environnement type `MDSO_API_KEY_FOR_[PARTNER]` exemple `MDSO_API_KEY_FOR_AMI`
  via le dashboard Scalingo onglet Environnement dans le contexte souhaité `staging` / `production`
  avec une valeur générée via `rails secret` par exemple
- redémarrer l'application via le dashboard Scalingo onglet Ressources
- vérifier sur le back office MDSO onglet "API Keys" la présence de l'accès
- tester si besoin via le playground API doc du contexte correspondant

## Installation de tesseract sous Mac OSX

`brew install tesseract tesseract-lang`

```sh
mkdir -p /opt/homebrew/share/tessdata
cd /opt/homebrew/share/tessdata
curl -O https://github.com/tesseract-ocr/tessdata_best/raw/main/fra.traineddata
# check that you really download the file and it's not empty
```

## Back Office (BO)

Un tableau de suivis des devis soumis est disponible sur [/mdso/admin](http://localhost:3000/mdso/admin) sous mot de passe hors développement.

## Tâches asynchrones

Elles sont listées dans la base de données PostgreSQL via le librairie `good_job`.

Un panneau de suivis est disponible sur [/mdso_good_job/](http://localhost:3000/mdso_good_job/) sous mot de passe hors développement.

## Mails

Ils sont envoyés en asynchrones via le service Brevo.

- [Mail previews](http://localhost:3000/rails/mailers/)

## Intégration continue

Une cinématique [GitHub Action](https://github.com/betagouv/mondevissansoublis/tree/main/.github/workflows) est founie qui lance :

- le linting via Rubocop ;
- les tests unitaires ia RSpec ;
- les tests d'intégration.

Cette cinématique commence d'abord par construire l'image Docker
qu'elle transmet ensuite aux trois étapes ci-dessus, ce qui évite de
répéter trois fois l'installation et la configuration du projet sans
sacrifier le parallèlisme de ces étapes.

# Anonymisation et Export vers Metabase

## Metabase

L'instance Metabase tourne sur une application extérieure dédié avec sa propre base de données.

Déploiement et mise à jour via https://github.com/betagouv/metabase-scalingo?tab=readme-ov-file#updating-metabase-on-scalingo

## Vue d'ensemble du processus

Le back-end dispose d'un système d'export automatisé qui permet de copier et anonymiser les données de production vers une base de données dédiée à Metabase pour les analyses et tableaux de bord.

Les données sont exportées dans un schéma dédié `mdso_analytics` pour une organisation claire dans Metabase.

## Architecture du processus

```
DB Source (Production) 
    ↓ (anonymisation)
Schéma temporaire export_anonymized
    ↓ (export CSV)
Fichiers CSV temporaires 
    ↓ (import)
DB Metabase → Schéma mdso_analytics
```

## Scripts d'anonymisation

Le processus d'anonymisation est géré par **6 scripts** situés dans le dossier `db/scripts` :

### Script principal

- **`export-db-metabase.sh`** : Script bash d'orchestration complète

### Scripts SQL

- **`anonymize-data.sql`** : Création des tables avec données anonymisées dans un schéma temporaire
- **`export-anonymized-data.sql`** : Export des données anonymisées vers fichiers CSV
- **`cleanup-metabase.sql`** : Nettoyage et recréation du schéma `mdso_analytics`
- **`import-csv-to-metabase.sql`** : Import des CSV vers le schéma `mdso_analytics`
- **`cleanup-anonymized-source-data.sql`** : Suppression du schéma temporaire dans la DB source

## Variables d'environnement requises

L'export nécessite ces variables d'environnement sur l'application backend :

| Variable | Description | Source | Requis |
|----------|-------------|---------|---------|
| `DATABASE_URL` | URL de la base de données backend | Automatiquement configurée par Scalingo | ✅ |
| `METABASE_DATA_DB_URL` | URL de la base de données Metabase | À configurer manuellement | ✅ |
| `ENABLE_METABASE_EXPORT` | Active/désactive l'export automatique | `true` ou `false` | ✅ |

### Configuration de l'activation/désactivation

```bash
# Activer l'export (recommandé pour la production)
scalingo --app mon-devis-sans-oublis-backend-prod env-set ENABLE_METABASE_EXPORT="true"

# Désactiver l'export (recommandé pour staging/dev)
scalingo --app mon-devis-sans-oublis-backend-staging env-set ENABLE_METABASE_EXPORT="false"
```

**Comportement** :

- Si `ENABLE_METABASE_EXPORT=true` : L'export s'exécute normalement
- Si `ENABLE_METABASE_EXPORT=false` ou non définie : L'export se termine proprement sans erreur
- Message explicite dans les logs pour indiquer l'état (activé/désactivé)

### Configuration de la variable Metabase

```bash
# 1. Récupérer l'URL de la DB Metabase
scalingo --app mon-devis-metabase env | grep DATABASE_URL

# 2. Configurer cette URL sur l'app backend
scalingo --app mon-devis-sans-oublis-backend-staging env-set \
  METABASE_DATA_DB_URL="postgresql://user:password@host:port/database"

# 3. Vérifier la configuration
scalingo --app mon-devis-sans-oublis-backend-staging env | grep DATABASE
```

## Données exportées et anonymisation

### Tables exportées

1. **`quote_checks`** - Analyses de devis principales
2. **`quotes_cases`** - Dossiers/cas de rénovation  
3. **`quote_check_feedbacks`** - Retours utilisateurs
4. **`quote_error_edits`** - Historique des corrections

### Anonymisation appliquée

Pour respecter la confidentialité, les données sensibles sont automatiquement anonymisées :

| Type de données | Anonymisation |
|-----------------|---------------|
| **Contenu des devis** | Remplacé par "Contenu anonymisé pour export Metabase" |
| **Commentaires utilisateurs** | Remplacés par "Commentaire anonymisé" |
| **Emails utilisateurs** | Remplacés par `email-anonymise@example.com` |
| **Texte OCR/PDF** | Exclu de l'export |

Les **données analytiques** (dates, statuts, codes d'erreur, métriques, profils utilisateurs) sont **conservées** pour permettre les analyses.

## Organisation dans Metabase

Les données sont importées dans le schéma `mdso_analytics` avec la structure :

- `mdso_analytics.quote_checks`
- `mdso_analytics.quotes_cases`
- `mdso_analytics.quote_check_feedbacks`
- `mdso_analytics.quote_error_edits`

## Sécurité et nettoyage

- **Fichiers CSV temporaires** : Automatiquement supprimés après chaque exécution
- **Schéma temporaire** : Nettoyé après export
- **Protection Git** : Fichiers `.csv` exclus via `.gitignore`
- **Gestion d'erreur** : Nettoyage automatique même en cas d'échec

## Automatisation

L'export est automatisé via un CRON (défini dans `cron.json`) qui s'exécute **tous les matins à 9h** pour maintenir les données Metabase à jour avec les dernières données anonymisées.

**Important** : Le CRON ne s'exécute que si `ENABLE_METABASE_EXPORT=true`.

## Exécution manuelle

```bash
# Pré-requis : Vérifier que les variables sont configurées
scalingo --app mon-devis-sans-oublis-backend-staging env | grep -E "(METABASE_DATA_DB_URL|ENABLE_METABASE_EXPORT)"

# Lancement de l'export
scalingo --app mon-devis-sans-oublis-backend-staging run db/scripts/export-db-metabase.sh
```

## Surveillance et logs

```bash
# Voir les tâches programmées
scalingo --app mon-devis-sans-oublis-backend-staging cron-tasks

# Consulter les logs d'exécution
scalingo --app mon-devis-sans-oublis-backend-staging logs --filter cron

# Vérifier les logs d'export dans la DB
psql $DATABASE_URL -c "SELECT * FROM export_logs ORDER BY created_at DESC LIMIT 10;"
```
