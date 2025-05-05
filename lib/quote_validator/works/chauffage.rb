# frozen_string_literal: true

#################################################
####              CHAUFFAGE                  ####
#################################################

module QuoteValidator
  module Works
    # Validator for the Work
    class Chauffage < Base
      def validate_chauffage(geste)
        add_error_if("chauffage_puissance_manquant", geste[:puissance].blank?, geste)
        add_error_if("chauffage_marque_manquant", geste[:marque].blank?, geste)
        add_error_if("chauffage_reference_manquant", geste[:reference].blank?, geste)
        add_error_if("chauffage_etas_manquant", geste[:ETAS].blank?, geste) # en %

        # TODO: à challenger
        add_error_if(
          "chauffage_remplacement_chaudiere_condensation_manquant",
          geste[:remplacement_chaudiere_condensation].blank?,
          geste
        )
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def validate_chaudiere_biomasse(geste)
        validate_chauffage(geste)

        # buche, granulé, copeaux ...
        add_error_if("chaudiere_type_combustible_manquant", geste[:type_combustible].blank?, geste)
        add_error_if("chaudiere_type_chargement_manquant", geste[:type_chargement].blank?, geste) # manuelle ou auto
        # externe/interne, neuf/existant, Textile/maconner
        add_error_if("chaudiere_type_silo_manquant", geste[:type_silo].blank?, geste)
        add_error_if("chaudiere_contenance_silo_manquant", geste[:contenance_silo].blank?, geste)
        add_error_if(
          "chaudiere_contenance_silo_trop_petit",
          geste[:contenance_silo].present? && geste[:contenance_silo].to_i && Integer(geste[:contenance_silo]) < 225,
          geste,
          type: "wrong"
        )

        # TODO: V1 : Valeur EtAS :
        # - ≥ 77 % pour les chaudières ≤ 20 kW
        # - ≥ 79 % pour les chaudières supérieur à 20 kW (supérieur à 78% pour MaPrimeRenov' ?? TODO vérif)

        # Si label, pas besoin de vérifier les emissions
        unless geste[:label_flamme_verte]
          add_error_if("chaudiere_emission_CO_manquant", geste[:emission_monoxyde_carbone].blank?, geste)
          # Emission monoxyde de carbone rapportée (CO) à 10% d’O2 (mg/Nm3)
          # TODO V1 ≤600mg/Nm3 pour manuelle et ≤400mg/Nm3 pour automatique)

          add_error_if("chaudiere_emission_COG_manquant", geste[:emission_composés_organique].blank?, geste)
          # Emission de composés organiques volatiles (COG) (mg/Nm3) rapportée à 10% d’O2
          # TODO V1 :(≤ 20mg/Nm3 pour manuelle ≤16mg/Nm3 pour automatique)

          add_error_if("chaudiere_emission_particule_manquant", geste[:emission_particules].blank?, geste)
          # Emission de particules (mg/Nm3)
          # todo V1 : (≤40 pour manuelle et ≤30 pour automatique)

          add_error_if("chaudiere_emission_nox_manquant", geste[:emission_oxydes_azotes].blank?, geste)
          # Emissions d’oxydes d’azote (NOx) rapporté à 10% d’O2 (mg/Nm3)
          # TODO (≤200 pour les deux)
        end

        # Régulateur. TODO : A challenger si on met en V0 ?
        add_error_if("chaudiere_marque_regulateur_manquant", geste[:marque_regulateur].blank?, geste)
        add_error_if("chaudiere_reference_regulateur_manquant", geste[:reference_regulateur].blank?, geste)
        # TODO: V1 : Classe IV selon classification européenne
        add_error_if("chaudiere_classe_regulateur_manquant", geste[:classe_regulateur].blank?, geste)
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize
      def validate_poele_insert(geste)
        validate_chauffage(geste)

        add_error_if("poele_type_combustible_manquant", geste[:type_combustible].blank?, geste) # buche, granulé
        add_error_if("poele_rendement_energetique_manquant", geste[:rendement_energetique].blank?, geste)

        # TODO: V1 : vérifier valeur ETAS (ɳs) (≥ 80% pour granulé, ≥ 65% pour bûches)

        return if geste[:label_flamme_verte]

        add_error_if("poele_emission_CO_manquant", geste[:emission_monoxyde_carbone].blank?, geste)
        # Emission de monoxyde de carbone rapporté à 13% d’O2) (mg/Nm3)
        # TODO V1 : (≤1500 pour bûches ≤ 300 pour granulé)

        add_error_if("poele_emission_COG_manquant", geste[:emission_composés_organique].blank?, geste)
        # Emission de composés organiques Volatile (COG) rapporté à 13% d’O2(mgC/Nm3)
        # TODO V1 : (≤120 si bûches ≤ 60 si granulé)

        add_error_if("poele_emission_particule_manquant", geste[:emission_particules].blank?, geste)
        # Emission de particules rapportée à 13% d’O2(mg/Nm3)
        # TODO V1 / (≤40 si bûches ≤ 30 pour granulé)

        add_error_if("poele_emission_nox_manquant", geste[:emission_oxydes_azotes].blank?, geste)
        # Emission d’oxydes d’azotes (NOx) rapporté à 13% d’O2 (mg/Nm3)
        # TODO V1 / (≤ 200 pour les deux)
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize
      def validate_systeme_solaire_combine(geste)
        validate_chauffage(geste)

        add_error_if("ssc_marque_capteurs_manquant", geste[:marque_capteurs].blank?, geste)
        add_error_if("ssc_reference_capteurs_manquant", geste[:reference_capteurs].blank?, geste)
        add_error_if("ssc_type_capteurs_manquant", geste[:type_capteurs].blank?, geste)
        add_error_if("ssc_surface_captage_manquant", geste[:surface_captage].blank?, geste) # m2
        # Todo V1 : Vérifier valeur
        # ≥ 6m2 MPR
        # ≥ 8m2 CEE

        add_error_if("ssc_productivite_capteurs_manquant", geste[:productivite_capteurs].blank?, geste) # W/m2
        # TODO : Que CEE ? V1, vérifier valeur : ≥ 600 W/m2
        add_error_if("ssc_volume_ballon_manquant", geste[:volume_ballon].blank?, geste)
        # (peut être associé à plusieurs ballons)
        # >300L MPR
        # >400L CEE
        # Si ≤500L → classe efficacité C à minima(MPR uniquement ?)
        # TODO V1, vérifier valeur + certification (que CEE? CSTBat ou solar keymark ou equivalente)

        # TODO: V1 : profil de soutirage

        add_error_if("ssc_energie_appoint_manquant", geste[:energie_appoint].blank?, geste) # electricité, gaz...

        # TODO: V1 :valeur ETAS
        # ≥ 82% si EES de l’appoint séparé inférieur à 82 %
        # ≥ 90% si EES de l’appoint inférieur à 90 %
        # ≥ 98% si EES de l’appoint ≥ 90 % et inférieur à 98 %. Sinon supérieur d’au moins 5 points à l’EES de l’appoint
      end
      # rubocop:enable Metrics/AbcSize

      def validate_pac(geste)
        validate_chauffage(geste)

        # air-eau, eau-eau, air-air, hybride -> TODO Verifier si besoin de l'indication sur le devis
        add_error_if("pac_type_manquant", geste[:type].blank?, geste)
        add_error_if(
          "pac_regime_temperature_manquant",
          geste[:regime_temperature].blank?,
          geste
        ) # basse, moyenne, haute
        # R410A -  attention, celui ci va être restreint, R32 …
        add_error_if("pac_type_fluide_frigorigene_manquant", geste[:type_fluide_frigorigene].blank?, geste)

        # TODO: V1, verifier valeur ETAS :
        # ≥ 126% si basse T
        # ≥ 111% si Haute T

        add_error_if("pac_cop_chauffage_manquant", geste[:COP].blank?, geste) # TODO: V1 Check if SCOP is required too.
      end

      def validate_pac_air_air(geste)
        fields = {
          "pac_air_air_scop_manquant" => :SCOP,
          "pac_air_air_puissance_nominale_manquant" => :puissance_nominale
        }

        fields.each do |error_message, field|
          add_error_if(error_message, geste[field].blank?, geste)
        end
      end

      protected

      def add_error_if(code, condition, geste, type: "missing")
        super(code, condition,
                  type:,
                  category: "gestes",
                  geste:,
                  provided_value: geste[:intitule])
      end
    end
  end
end
