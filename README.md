# Mon Devis Sans Oublis

## Introduction

Ce repo est le code source pour faire tourner la plateforme [Mon Devis Sans Oublis](https://mon-devis-sans-oublis.beta.gouv.fr/) (MDSO) basé sur certains services et outils choisis :

**Le projet est encore en tout début de phase de construction et donc sujet à évolutions à travers des cyclse courts.**

* [Ruby on Rails](https://rubyonrails.org/) version 7 comme boîte à outil et socle technique applicatif ;
* le [DSFR](https://www.systeme-de-design.gouv.fr/) pour réutiliser les éléments graphiques officiels via la [librairie de
composants DSFR](https://github.com/betagouv/dsfr-view-components)
* PostgreSQL comme base de données pour stocker les données ;
*  des solutions de LLM pour interroger les devis, via la boîte à outils [LangChain](https://rubydoc.info/gems/langchainrb)
*** Albert API d'Etalab
*** Mistral.ai : données publiques et/ou anonymisées
*** Ollama : un modèle Llama local
* l'API Data de l'ADEME pour croiser les données d'entreprises qualifiées ;
* des annuaires officiels de professionnels pour croiser des données ;
* ~~[Publi.codes](https://publi.codes/) pour un moteur de validation basé sur des règles~~ (plus utilisé pour le moment) ;
* Sentry pour monitorer et être alerté en cas d'erreur ;
* Matomo pour mesurer et comprendre l'usage via des analytics ;
* RSpec comme framework de tests ;
* Rswag comme outil de documentation au format Swagger/ OpenAPI de l'API à travers des tests ;
* Rubocop (RSpec et Rails) pour le linting ;
* Docker pour avoir un environnement de développement ;
* ClamAV pour scanner les fichiers déposés.

## Moteur et fonctionnement interne / Architecture

```mermaid
sequenceDiagram
    actor User as Usager
    participant Frontend as Interface MDSO Frontend
    participant Backend as Interface MDSO Backend

    participant QuoteCheckCheckJob as Process traitement
    participant Albert LLM as API Albert AI LLM
    participant Albert OCR as API Albert AI OCR LLM
    participant Mistral LLM as API Mistral AI LLM
    participant Tesseract as Tesseract OCR

    participant BO as Back Office MDSO

    User->>Frontend: Dépose un document type PDF
    Frontend->>Backend: Transmet le fichier
    Backend->>Backend: Sauvegarde le fichier QuoteFile et génère un QuoteCheck
    Backend->>Frontend: Identifiant pour suivre le statut du QuoteCheck

    activate QuoteCheckCheckJob
    Backend->>QuoteCheckCheckJob: process asynchrone démarrage
    Backend-->>Backend: Transformation du PDF en images par page (QuoteFileImagifyPdfJob)
    Backend-->>Backend: Vérification de la non présence de virus (QuoteFileSecurityScanJob)

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Extraction automatique du texte du PDF si bien formatté
    QuoteCheckCheckJob->>QuoteCheckCheckJob: Sinon extraction du texte via OCR (Albert / Mistral / Tesseract) UNIQUEMENT VIA BO

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Extraction des données du texte via méthode naïve
    QuoteCheckCheckJob->>QuoteCheckCheckJob: Réduction du texte si conditions générales

    QuoteCheckCheckJob<<->>Albert LLM: Extraction des données personnelles et administratives
    QuoteCheckCheckJob<<->>ADEME API: Extension des données commerciales et certifications via recherche SIRET

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Anonymisation du texte
    
    QuoteCheckCheckJob->>Frontend: Si erreur lecture ou texte vide renvoit d'une erreur

    QuoteCheckCheckJob<<->>Mistral LLM: Extraction des données gestes et caractéristiques du texte anonymisé

    QuoteCheckCheckJob->>QuoteCheckCheckJob: Validation des données selon algorithme Ruby maison et ajout d'erreurs

    QuoteCheckCheckJob->>Backend: retours avec données et erreurs
    deactivate QuoteCheckCheckJob

    Backend->>Frontend: Retour API et affichage du résultat
```

Nous suivons les recommendations et les conventions du framework Ruby on Rails et de la communauté.

- dossier `lib` : pour les parties isolées qui pourraient être externalisées, comme la communication avec des services externes
- dossier `app/services` : pour organiser la logique métier propre et interne à notre projet

Les fichiers devis sont traités par le `QuoteChecksController` qui les envoient aux services:
- `QuoteReader` lisant le devis brut puis extractant les information du devis de manière naïve en se basant sur le texte du PDF et via solutions LLM avec croisement de données d'annuaires publiques de la rénovation
- puis ces attributs de devis sont vérifier par le `QuoteValdiator` qui controlle un ensemble de règles et renvoit les erreurs correspondantes

### Traitement des images / OCR

Différentes briques sont mises à contribution et encore en évaluation:

* pour la reconnaissance des images et lire leur contenu via OCR
  * Surya (Python) 
  * tesseract (natif)
* pour transformer les PDF en images
  * librairie Poppler `pdftoppm` (natif)
  * la gem MiniMagick (IM) `mini_magick` avec ImageMagick 6.9 (comme sur Scalingo) (natif)

### Tester un devis en local

`docker compose exec web rake 'quote_checks:create[tmp/devis_tests/DC004200PAC-Aireau+Chauffe eau thermo.pdf]' | less`

#### Forcer un devis à valide

```
quote_check_id = "76c35e1c-4d8d-479d-a62a-4f36511a5041"
QuoteCheck.find(quote_check_id).update!(validation_errors: nil, validation_error_edits: nil)
```

## API

- au format REST JSON
- protéger via authentification HTTP Basic avec Bearer hashé
- voir fichier de documentation de l'API  au format OpenAPI Swagger et interface bac à sable interractif sur `/api-docs`
- regénération et mise à jour de la documentation à partir des spécifications tests via `make doc`

### API Accès

- ajouter ou modifier la variable d'environnement type `MDSO_API_KEY_FOR_[PARTNER]` exemple `MDSO_API_KEY_FOR_AMI`
  via le dashboard Scalingo onglet Environnement dans le contexte souhaité `staging` / `production`
  avec une valeur générée via `rails secret` par exemple
- redémarrer l'application via le dashboard Scalingo onglet Ressources
- vérifier sur le back office MDSO onglet "API Keys" la présence de l'accès
- tester si besoin via le playground API doc du contexte correspondant

## Démarrage

```shell
docker-compose up
```

ou si vous l'installez directement (non recommandé)

```shell
DATABASE_URL='postgresql://postgres:dummy@localhost:5433' bin/rails server -b 0.0.0.0
```

## Environnement

Tout l'environnement est configuré pour et depuis [Docker](https://www.docker.com/). Des
commandes utiles sont fournies dans le [Makefile](./Makefile).

## Installation de tesseract sous Mac OSX

`brew install tesseract tesseract-lang`

```sh
mkdir -p /opt/homebrew/share/tessdata
cd /opt/homebrew/share/tessdata
curl -O https://github.com/tesseract-ocr/tessdata_best/raw/main/fra.traineddata
# check that you really download the file and it's not empty
```

## Back office

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
