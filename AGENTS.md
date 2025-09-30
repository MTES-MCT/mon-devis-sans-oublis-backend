# AGENTS.md

This file provides guidance to coding assistant when working with code in this repository.

## Development Commands

### Docker (Recommended)
- `docker compose up` - Start all services
- `docker compose run --rm --entrypoint="" web bash` - Access shell
- `make lint` - Run linting with Rubocop
- `make guard` - Run guard for continuous testing
- `make doc` - Generate API documentation

### Rails Commands
- `bundle exec rails server` - Start Rails server
- `bundle exec rspec` - Run tests
- `bundle exec rubocop` - Run linting
- `bundle exec rake rswag:specs:swaggerize PATTERN="spec/**/*_doc_spec.rb"` - Generate API docs

### Testing & Debugging
- Test a single quote: `docker compose exec web rake 'quote_checks:create[tmp/devis_tests/filename.pdf]'`
- Re-check quote: `QuoteCheckCheckJob.perform_later(quote_check_id)`
- Force quote to valid: `QuoteCheck.find(quote_check_id).update!(validation_errors: nil, validation_error_edits: nil)`

## High-Level Architecture

This is a Rails 8 backend for "Mon Devis Sans Oublis" (MDSO), a platform for analyzing renovation quote compliance to accelerate energy renovation funding decisions.

### Core Data Flow
1. **Quote Upload**: Users upload PDF quotes via API
2. **Processing Pipeline**: `QuoteCheckCheckJob` processes files asynchronously
   - PDF → images conversion (`QuoteFileImagifyPdfJob`)
   - Virus scanning (`QuoteFileSecurityScanJob`)
   - Text extraction (direct PDF or OCR via Albert/Mistral/MDSO services)
   - Data extraction using LLMs and naive text parsing
   - External data enrichment (SIRENE, ADEME APIs)
   - Validation against business rules
3. **Results**: Structured data with validation errors returned via API

### Key Models & Controllers
- **QuoteCheck**: Individual quote analysis
- **QuotesCase**: Groups multiple quotes for a renovation project
- **QuoteFile**: File storage and metadata
- **API Controllers**: REST API in `app/controllers/api/v1/`
- **Admin Interface**: ActiveAdmin backend at `/mdso/admin`

### Service Architecture
- **lib/**: External integrations and reusable components
  - `QuoteReader/*`: Text extraction and OCR services
  - `QuoteValidator/*`: Business rule validation
  - `llms/`: LLM integrations (Albert, Mistral, Ollama)
  - `data_sources/`: External APIs (SIRENE, ADEME, API Entreprise)
- **app/services/**: Internal business logic
- **app/jobs/**: Background job processing with GoodJob

### LLM Integration
- **Albert API** (Etalab): Private data extraction and OCR
- **Mistral API**: Anonymized data processing for work gestures
- **Ollama**: Local LLM option
- Configured via environment variables (`ALBERT_API_KEY`, `MISTRAL_API_KEY`, etc.)

### OCR Services
Multiple OCR backends configurable via `MDSO_OCR` environment variable:
- `MdsoOcrMarker` (default)
- Albert OCR
- Mistral OCR
- Custom MDSO OCR services

### Authentication & API Access
- HTTP Basic Authentication with API keys
- Environment variables: `MDSO_API_KEY_FOR_[PARTNER]`
- ProConnect SSO for admin interface

### Background Jobs
- GoodJob (PostgreSQL-backed) for job queue
- Monitor at `/mdso_good_job/`
- Key jobs: `QuoteCheckCheckJob`, `QuoteFileImagifyPdfJob`, `QuoteFileSecurityScanJob`

### File Storage
- Active Storage with PostgreSQL adapter
- ClamAV integration for virus scanning
- PDF to image conversion using Poppler/ImageMagick

### API Documentation
- OpenAPI/Swagger documentation at `/api-docs`
- Generated from RSpec tests using Rswag
- Update with `make doc` command

## Configuration Notes

### Environment Setup
- Copy `.env.example` to `.env.local` (Node.js) or `.env.docker` (Docker)
- Key variables: `DATABASE_URL`, `APPLICATION_HOST`, `ALBERT_API_KEY`, `MISTRAL_API_KEY`
- Never leave environment variables empty - comment out or remove unused ones

### Database
- PostgreSQL 16 required
- UUID primary keys by default
- Metabase export functionality for analytics

### Key File Locations
- Routes split: `config/routes/api.rb` and `config/routes/internal.rb`
- Custom config: `config/custom.rb`
- Job scheduling: `cron.json`
