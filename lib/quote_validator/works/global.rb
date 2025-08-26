# frozen_string_literal: true

module QuoteValidator
  module Works
    # Validator for the Quote
    class Global < Base # rubocop:disable Metrics/ClassLength
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

      def rge_labels
        @rge_labels ||= Array.wrap(pro[:rge_labels]&.presence).filter_map do |rge|
          RgeValidator.validate_format!(rge)
        rescue RgeValidator::ArgumentError
          nil
        end.uniq
      end

      def siret
        pro[:siret]&.presence
      end

      def qualifications_per_geste_type # rubocop:disable Metrics/MethodLength
        @qualifications_per_geste_type ||= RgeValidator.rge_qualifications(siret:)
                                                       .each_with_object({}) do |qualification, hash|
          geste_types = RgeValidator.ademe_geste_types(
            nom_certificat: qualification.fetch("nom_certificat"),
            domaine: qualification.fetch("domaine")
          ).compact.uniq

          geste_types.each do |type|
            hash[type] ||= []
            hash[type] << qualification
          end

          hash
        end
      rescue QuoteValidator::Base::ArgumentError
        @qualifications_per_geste_type = []
      end

      def geste_types_with_certification
        @geste_types_with_certification ||= RgeValidator.geste_types_with_certification
      end

      # doit valider les critères techniques associés aux gestes présents dans le devis
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      def validate
        isolation = Works::Isolation.new(quote, quote_id:)
        menuiserie = Works::Menuiserie.new(quote, quote_id:)
        chauffage = Works::Chauffage.new(quote, quote_id:)
        eau_chaude = Works::EauChaude.new(quote, quote_id:)
        ventilation = Works::Ventilation.new(quote, quote_id:)

        gestes = quote[:gestes] || []

        gestes.each_with_index do |geste, index| # rubocop:disable Metrics/BlockLength
          geste[:index] = index

          case geste[:type]

          # ISOLATION
          when "isolation_thermique_par_exterieur_ITE",
               /^isolation_thermique_par_exterieur_/i # LLM invented
            isolation.validate_isolation_ite(geste)
          when "isolation_comble_perdu", "isolation_combles_perdues"
            isolation.validate_isolation_combles(geste)
          when "isolation_rampants_toiture"
            isolation.validate_isolation_rampants(geste)
          when "isolation_toiture_terrasse"
            isolation.validate_isolation_toiture_terrasse(geste)
          when "isolation_thermique_par_interieur_ITI",
               /^isolation_thermique_par_interieur_/i # LLM invented
            isolation.validate_isolation_iti(geste)
          when "isolation_plancher_bas"
            isolation.validate_isolation_plancher_bas(geste)

          # MENUISERIEs
          when "menuiserie_fenetre"
            menuiserie.validate_menuiserie_fenetre(geste)
          when "menuiserie_fenetre_toit"
            menuiserie.validate_menuiserie_fenetre_toit(geste)
          when "menuiserie_porte"
            menuiserie.validate_menuiserie_porte(geste)
          when "menuiserie_volet_isolant"
            menuiserie.validate_menuiserie_volet_isolant(geste)

          # CHAUFFAGE
          when "chaudiere_biomasse"
            chauffage.validate_chaudiere_biomasse(geste)
          when "poele_insert"
            chauffage.validate_poele_insert(geste)
          when "systeme_solaire_combine"
            chauffage.validate_systeme_solaire_combine(geste)
          when "pac", "pac_air_eau", "pac_hybride", "pac_eau_eau",
               "pompe_a_chaleur", /pompe_._chaleur/ # LLM invented
            chauffage.validate_pac(geste)
          when "pac_air_air"
            chauffage.validate_pac_air_air(geste)

          # EAU CHAUDE SANITAIRE
          when "chauffe_eau_solaire_individuel"
            eau_chaude.validate_cesi(geste)
          when "chauffe_eau_thermo", "chauffe_eau_thermodynamique"
            eau_chaude.validate_chauffe_eau_thermodynamique(geste)

          # VENTILATION
          when "vmc_simple_flux",
            "ventilation" # LLM invented
            ventilation.validate_vmc_simple_flux(geste)
          when "vmc_double_flux"
            ventilation.validate_vmc_double_flux(geste)

          # DEPOSE CUVE A FIOUL

          # SYSTEME DE REGULATION

          # AUDIT ENERGETIQUE

          when "", nil
            next

          else
            e = NotImplementedError.new("Geste inconnu '#{geste[:type]}' is not listed")
            ErrorNotifier.notify(e)

            "geste_inconnu"
          end
        end

        add_validator_errors(
          isolation,
          menuiserie,
          chauffage,
          eau_chaude,
          ventilation
        )

        gestes.each do |geste|
          validate_prix_geste(geste)
          validate_rge_geste(geste) if siret
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

      def validate_prix_geste(geste) # rubocop:disable Metrics/MethodLength
        geste_type = geste[:type].to_s
        return unless QuoteCheck::GESTE_TYPES.include?(geste_type)

        # Valider qu'on a le prix HT sur chaque geste et son taux de TVA
        # {
        #   prix_ht: decimal;
        #   prix_unitaire_ht: decimal;
        #   taux_tva: decimal
        #   prix_ttc: decimal
        #   quantite: decimal
        #   unite: texte
        # }
        add_error_if(
          "geste_prix_ht_manquant",
          geste[:prix_ht].blank?,
          category: "gestes",
          type: "missing",
          provided_value: geste[:intitule],
          geste: geste
        )
        add_error_if(
          "geste_prix_unitaire_ht_manquant",
          geste[:prix_unitaire_ht].blank?,
          category: "gestes",
          type: "missing",
          provided_value: geste[:intitule],
          geste: geste
        )

        add_error_if(
          "geste_taux_tva_manquant",
          geste[:taux_tva].blank?,
          category: "gestes",
          type: "missing",
          provided_value: geste[:intitule],
          geste: geste
        )
      end

      # Validate the RGE geste type matching only if the pro has a RGE label
      # (SIRET correspondance and date are already managed in global RGE check)
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def validate_rge_geste(geste) # rubocop:disable Metrics/MethodLength
        geste_type = geste[:type].to_s
        return unless geste_types_with_certification.include?(geste_type)

        qualifications_for_geste_type = qualifications_per_geste_type[geste_type]
        geste_type_has_rge = qualifications_for_geste_type&.any? || false
        add_error_if(
          "geste_rge_non_correspondant",
          !geste_type_has_rge,
          geste: geste,
          provided_value: geste_type,
          category: "gestes",
          type: "warning"
        )
        return unless geste_type_has_rge

        other_rges = rge_labels - qualifications_for_geste_type.map { RgeValidator.id_to_rge(it.fetch("_id")) }.uniq
        code = "geste_rge_non_mentionne"
        rge_link_uri = RgeValidator.rge_link
        add_error_if(
          code,
          qualifications_for_geste_type.none? do |qualification|
            RgeValidator.rge_for_id?(rge_labels, qualification.fetch("_id"))
          end,
          geste: geste,
          provided_value: "#{geste_type} #{rge_labels}",
          solution: I18n.t(
            "quote_validator.errors.#{code}_infos_html",
            default: nil,
            rge: other_rges.first,
            rge_link: rge_link_uri && ApplicationController.helpers.link_to(rge_link_uri, rge_link_uri)
          )&.strip,
          category: "gestes",
          type: "warning"
        )

        formatted_date = RgeValidator.validate_date!(date) if date.present?
        return unless formatted_date

        add_error_if(
          "geste_rge_hors_date",
          qualifications_for_geste_type.none? do |qualification|
            formatted_date.between?(
              Date.parse(qualification.fetch("date_debut")),
              Date.parse(qualification.fetch("date_fin"))
            )
          end,
          geste: geste,
          provided_value: "#{geste_type} #{I18n.l(formatted_date, format: :long, locale: :fr)}",
          category: "gestes",
          type: "warning"
        )
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
    end
  end
end
