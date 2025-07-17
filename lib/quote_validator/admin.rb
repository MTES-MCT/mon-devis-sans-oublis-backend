# frozen_string_literal: true

module QuoteValidator
  # Validator for the Quote
  class Admin < Base # rubocop:disable Metrics/ClassLength
    VERSION = "0.0.1"

    def validate!
      super do
        validate
      end
    end

    protected

    def date
      quote[:date_devis]&.presence
    end

    def pro
      @pro ||= quote[:pro] ||= TrackingHash.new
    end

    def rge
      Array.wrap(pro[:rge_labels]&.presence).first
    end

    def siret
      pro[:siret]&.presence
    end

    # doit valider les mentions administratives du devis
    # rubocop:disable Metrics/AbcSize
    def validate # rubocop:disable Metrics/MethodLength
      # mention devis présente ou non, quote[:mention_devis] est un boolean
      add_error_if(
        "devis_manquant",
        !(quote[:mention_devis] || quote[:devis].present?),
        category: "admin",
        type: "missing"
      )
      add_error_if("numero_devis_manquant", quote[:numero_devis].blank?, category: "admin", type: "warning")

      validate_dates
      validate_pro
      validate_client
      validate_rge_global
      validate_rge_gestes
      validate_prix
    end
    # rubocop:enable Metrics/AbcSize

    # numéro, rue, cp, ville - si pas suffisant numéro de parcelle cadastrale. V0, on check juste la présence ?
    def validate_address(address, type)
      case type
      when "client"
        add_error_if("client_adresse_manquant", address.blank?, category: "admin", type: "missing")
      when "chantier" # ne devrait pas arriver, mais par la suite, faudrait vérifier la justesse de l'adresse
        add_error_if("chantier_adresse_manquant", address.blank?, category: "admin", type: "missing")
      when "pro"
        add_error_if("pro_adresse_manquant", address.blank?, category: "admin", type: "missing")
      end
    end

    # doit valider les mentions administratives associées au client
    def validate_client
      @client = quote[:client] ||= TrackingHash.new

      add_error_if("client_prenom_manquant", @client[:prenom].blank?, category: "admin", type: "missing")
      add_error_if("client_nom_manquant", @client[:nom].blank?, category: "admin", type: "missing")
      add_error_if("client_civilite_manquant", @client[:civilite].blank?, category: "admin", type: "missing")

      validate_client_address
    end

    # vérifier la présence de l'adresse du client.
    # + Warning pour préciser que l'adresse de facturation = adresse de chantier si pas de présence
    def validate_client_address
      client_address = @client[:adresse]
      validate_address(client_address, "client")

      # site_address = @client[:adresse_chantier]
      # if site_address.blank?
      #   add_error("chantier_facturation_idem", category: "admin", type: "warning")
      # else
      #   validate_address(site_address, "chantier")
      # end
    end

    # date d'emission, date de pré-visite (CEE uniquement ?),
    # validité (par défaut 3 mois -> Juste un warning),
    # Date de début de chantier (CEE uniquement)
    # rubocop:disable Metrics/AbcSize
    def validate_dates
      # date_devis
      add_error_if("date_devis_manquant", quote[:date_devis].blank?, category: "admin", type: "missing")

      # date_debut_chantier
      date_chantier = quote[:date_debut_chantier]
      delai_debut_chantier = quote[:delai_debut_chantier]
      add_error_if("date_chantier_manquant", date_chantier.blank? && delai_debut_chantier.blank?, category: "admin",
                                                                                                  type: "warning")

      # date_pre_visite
      add_error_if("date_pre_visite_manquant", quote[:date_pre_visite].blank?, category: "admin", type: "warning")

      # validite
      add_error_if("date_validite_manquant", !quote[:validite], category: "admin", type: "warning")
    end
    # rubocop:enable Metrics/AbcSize

    def validate_prix
      # Valider qu'on a une séparation matériaux et main d'oeuvre
      # TODO V2, il faudra sûrement vérifier la séparation pose / fourniture par geste et non juste un boolean.
      add_error_if("separation_fourniture_pose_manquant", !quote[:separation_prix_fourniture_pose],
                   category: "admin", type: "missing")

      # Valider qu'on a le prix total HT / TTC
      add_error_if("prix_total_ttc_manquant", quote[:prix_total_ttc].blank?, category: "admin", type: "missing")
      add_error_if("prix_total_ht_manquant", quote[:prix_total_ht].blank?, category: "admin", type: "missing")
      # Valider qu'on a le montant de TVA pour chacun des taux
      # {taux_tva: decimal;
      # prix_ht_total: decimal;
      # montant_tva_total: decimal
      # }
      # TODO Vérifier si utile de le faire ?
      # tvas = quote[:tva] || []
      # tvas.each do |tva|
      # end
    end

    # doit valider les mentions administratives associées à l'artisan
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def validate_pro
      @pro = quote[:pro] ||= TrackingHash.new

      add_error_if("pro_raison_sociale_manquant", @pro[:raison_sociale].blank?, category: "admin", type: "missing")
      # on essaie de récupérer la forme juridique pendant l'anonymisation mais aussi avec le LLM.
      add_error_if("pro_forme_juridique_manquant",
                   @pro[:forme_juridique].blank? && quote[:pro_forme_juridique].blank?,
                   category: "admin", type: "missing")
      add_error_if("tva_manquant", @pro[:numero_tva].blank?, category: "admin", type: "missing")
      # TODO: check format tva : FR et de 11 chiffres
      # (une clé informatique de 2 chiffres et le numéro SIREN à 9 chiffres de l'entreprise)

      # TODO: rajouter une condition si personne physique professionnelle et dans ce cas pas de SIRET nécessaire
      add_error_if("capital_manquant", @pro[:capital].blank?, category: "admin", type: "missing")
      add_error_if("siret_manquant", @pro[:siret].blank?, category: "admin", type: "missing")
      # beaucoup de confusion entre SIRET (14 chiffres pour identifier un etablissement)
      # et SIREN (9 chiffres pour identifier une entreprise)
      add_error_if("siret_format_erreur",
                   @pro[:siret]&.gsub(/\s+/, "")&.length != 14 && @pro[:siret]&.length&.positive?,
                   category: "admin",
                   type: "wrong")

      rcs_present = @pro[:rcs].present? || @pro[:rne].present? || (@pro[:rcs_ville].present? && @pro[:siret].present?)

      add_error_if("rcs_manquant", !rcs_present, category: "admin", type: "missing")
      add_error_if("rcs_ville_manquant", rcs_present && @pro[:rcs_ville].blank?, category: "admin", type: "missing")

      add_error_if("pro_assurance_manquant", @pro[:assurance].blank?, category: "admin", type: "missing")

      validate_pro_address
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def validate_pro_address
      address = @pro[:adresse]
      validate_address(address, "pro")
    end

    # Validate the RGE geste type matching only if the pro has a RGE label
    # (SIRET correspondance and date are already managed in global RGE check)
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def validate_rge_gestes # rubocop:disable Metrics/MethodLength
      return unless rge || siret

      geste_types_with_certification = RgeValidator.geste_types_with_certification

      rge_qualifications = RgeValidator.rge_qualifications(siret:, rge:)
      qualifications_per_geste_type = rge_qualifications.each_with_object({}) do |qualification, hash|
        qualification_geste_types = RgeValidator.ademe_geste_types(
          nom_certificat: qualification.fetch("nom_certificat"),
          domaine: qualification.fetch("domaine")
        ).compact.uniq

        qualification_geste_types.each do |geste_type|
          hash[geste_type] ||= []
          hash[geste_type] << qualification
        end
      end

      gestes = quote[:gestes] || []
      gestes.each_with_index do |geste, index|
        geste[:index] = index

        geste_type = geste[:type].to_s
        next unless geste_types_with_certification.include?(geste_type)

        geste_type_has_rge = qualifications_per_geste_type.key?(geste_type)
        add_error_if(
          "geste_rge_non_correspondant",
          !geste_type_has_rge,
          geste:,
          provided_value: geste_type,
          category: "admin",
          type: "warning"
        )
        next unless geste_type_has_rge

        next unless date

        add_error_if(
          "geste_rge_hors_date",
          qualifications_per_geste_type[geste_type].none? do |qualification|
            date.between?(Date.parse(qualification.fetch("date_debut")), Date.parse(qualification.fetch("date_fin")))
          end,
          geste:,
          provided_value: "#{geste_type} #{I18n.l(date, format: :long, locale: :fr)}",
          category: "admin",
          type: "warning"
        )
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def validate_rge_global # rubocop:disable Metrics/MethodLength
      add_error_if("rge_manquant", pro[:rge_labels].blank?, category: "admin", type: "missing")

      return unless siret && rge

      begin
        RgeValidator.valid?(siret:, rge:, date:)
      rescue QuoteValidator::Base::ArgumentError => e
        add_error_if(
          e.error_code,
          true,
          category: "admin",
          type: "error"
        )
      end
    end
  end
end
