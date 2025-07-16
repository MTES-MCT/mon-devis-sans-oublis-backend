# frozen_string_literal: true

require "rails_helper"

# Test du script d'anonymisation
# rubocop:disable RSpec/DescribeClass
RSpec.describe "Database Anonymization Script" do
  # Centralisation du chemin du script pour éviter la répétition
  let(:anonymization_script) { Rails.root.join("db/scripts/anonymize-data.sql").read }

  # Création de données de test
  # Ces données contiennent des informations sensibles à anonymiser
  let(:quote_check) do
    create(:quote_check, text: "Données sensibles", comment: "Commentaire sensible")
  end
  let(:quote_file) do
    create(:quote_file, data: "contenu sensible", ocr: "texte OCR sensible")
  end
  let(:quote_check_feedback) do
    create(:quote_check_feedback,
           quote_check: quote_check,
           rating: 5,
           validation_error_details_id: nil)
  end

  # Hook before : initialise les données de test avant chaque exemple
  before do
    # Créer les objets pour initialiser les données en base
    quote_check
    quote_file
    quote_check_feedback
  end

  # Hook after : nettoyage du schéma après chaque test
  after do
    # Supprime le schéma d'export anonymisé pour éviter les conflits entre tests
    ActiveRecord::Base.connection.execute("DROP SCHEMA IF EXISTS export_anonymized CASCADE")
  end

  describe "anonymization process" do
    # Tests de l'anonymisation des données sensibles
    context "when anonymizing sensitive data" do
      before { ActiveRecord::Base.connection.execute(anonymization_script) }

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it "anonymizes quote_checks text correctly" do
        # Récupération des données anonymisées depuis le schéma export_anonymized
        anonymized_checks = ActiveRecord::Base.connection.execute(
          "SELECT * FROM export_anonymized.quote_checks WHERE id = '#{quote_check.id}'"
        )

        # Vérifier que l'enregistrement existe dans le schéma anonymisé
        expect(anonymized_checks.count).to eq(1)
        anonymized_check = anonymized_checks.first

        # Vérifier que les données sensibles ont été remplacées par du texte anonymisé
        expect(anonymized_check["text"]).to include("anonymisé")
        expect(anonymized_check["text"]).not_to include("Données sensibles")
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it "anonymizes quote_check_feedbacks correctly" do
        # Récupération des feedbacks anonymisés
        anonymized_feedbacks = ActiveRecord::Base.connection.execute(
          "SELECT * FROM export_anonymized.quote_check_feedbacks WHERE quote_check_id = '#{quote_check.id}'"
        )

        # Vérifier que l'enregistrement existe
        expect(anonymized_feedbacks.count).to eq(1)
        anonymized_feedback = anonymized_feedbacks.first

        # Vérifier que l'email a été anonymisé
        expect(anonymized_feedback["email"]).to eq("email-anonymise@example.com")
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end

    # Tests de préservation des données analytiques importantes
    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context "when preserving analytical data" do
      # Capture des données originales avant anonymisation
      let(:original_count) { QuoteCheck.count }
      let(:original_profile) { quote_check.profile }

      before { ActiveRecord::Base.connection.execute(anonymization_script) }

      it "preserves the number of records" do
        # Vérification que le nombre total d'enregistrements est conservé
        anonymized_count = ActiveRecord::Base.connection.execute(
          "SELECT COUNT(*) FROM export_anonymized.quote_checks"
        ).first["count"].to_i

        expect(anonymized_count).to eq(original_count)
      end

      it "preserves profile information" do
        # Vérification que les données analytiques non sensibles sont préservées
        # Le profil utilisateur doit rester intact pour permettre les analyses métier
        anonymized_profile = ActiveRecord::Base.connection.execute(
          "SELECT profile FROM export_anonymized.quote_checks WHERE id = '#{quote_check.id}'"
        ).first["profile"]

        expect(anonymized_profile).to eq(original_profile)
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # Tests de création et structure du schéma d'export
    context "when creating schema" do
      before { ActiveRecord::Base.connection.execute(anonymization_script) }

      it "creates export_anonymized schema" do
        # Vérification que le schéma d'export anonymisé a été créé correctement
        schema_exists = ActiveRecord::Base.connection.execute(
          "SELECT 1 FROM information_schema.schemata WHERE schema_name = 'export_anonymized'"
        ).any?

        expect(schema_exists).to be true
      end

      # rubocop:disable RSpec/ExampleLength
      it "creates required tables in schema" do
        # Vérification que les tables principales existent dans le schéma anonymisé
        tables_count = ActiveRecord::Base.connection.execute(
          "SELECT table_name FROM information_schema.tables
           WHERE table_schema = 'export_anonymized'
           AND table_name IN ('quote_checks', 'quote_check_feedbacks', 'quotes_cases')"
        ).count

        expect(tables_count).to be >= 3
      end
      # rubocop:enable RSpec/ExampleLength
    end

    # Tests de gestion des cas limites et valeurs particulières
    context "when handling edge cases" do
      # Création d'un devis avec des valeurs nulles/vides pour tester la robustesse
      let(:empty_quote) { create(:quote_check, text: nil, comment: "") }

      before do
        # Initialiser le devis avec valeurs nulles
        empty_quote
        # Exécuter le script d'anonymisation
        ActiveRecord::Base.connection.execute(anonymization_script)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "handles null values correctly" do
        # Vérification que le script gère correctement les valeurs nulles sans planter
        anonymized_empty = ActiveRecord::Base.connection.execute(
          "SELECT * FROM export_anonymized.quote_checks WHERE id = '#{empty_quote.id}'"
        )

        # Le script ne doit pas planter sur des valeurs nulles
        expect(anonymized_empty.count).to eq(1)
        expect(anonymized_empty.first["text"]).to be_nil
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
# rubocop:enable RSpec/DescribeClass
