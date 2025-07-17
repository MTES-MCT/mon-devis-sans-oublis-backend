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
        geste_reconnu = true

        gestes.each_with_index do |geste, index| # rubocop:disable Metrics/BlockLength
          geste[:index] = index
          geste_reconnu = true

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
            geste_reconnu = false
            next

          else
            geste_reconnu = false
            e = NotImplementedError.new("Geste inconnu '#{geste[:type]}' is not listed")
            ErrorNotifier.notify(e)

            "geste_inconnu"
          end

          validate_prix_geste(geste) if geste_reconnu
        end

        add_validator_errors(
          isolation,
          menuiserie,
          chauffage,
          eau_chaude,
          ventilation
        )
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

      def validate_prix_geste(geste) # rubocop:disable Metrics/MethodLength
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
    end
  end
end
