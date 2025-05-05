# frozen_string_literal: true

#################################################
####              VENTILATION                ####
#################################################

module QuoteValidator
  module Works
    # Validator for the Work
    class Ventilation < Base
      # rubocop:disable Metrics/MethodLength
      def validate_ventilation(geste)
        fields = {
          "vmc_type_manquant" => :type_vmc,
          # VMC simple flux hygroréable de type A (Hygro A)
          # VMC simple flux hygroréable de type B (Hygro B)
          # VMC double flux avec échangeur
          "vmc_marque_caisson_manquant" => :marque_caisson,
          "vmc_reference_caisson_manquant" => :reference_caisson,
          "vmc_marque_bouche_extraction_manquant" => :marque_bouche_extraction,
          "vmc_reference_bouche_extraction_manquant" => :reference_bouche_extraction,
          "vmc_nombre_bouche_extraction_manquant" => :nombre_bouche_extraction,
          "vmc_classe_caisson_manquant" => :classe_caisson,
          "vmc_puissance_manquant" => :puissance_absobée_pondéréé_moteur
          # Puissance electrique du moteur en fonction de la config du logement
          # exprimé en (W-Th-C) (doit être basse conso)
        }

        fields.each do |error_message, field|
          add_error_if(error_message, geste[field].blank?, geste)
        end
      end
      # rubocop:enable Metrics/MethodLength

      def validate_vmc_simple_flux(geste)
        validate_ventilation(geste)

        fields = {
          "vmc_simple_flux_nombre_bouches_entree_dair_manquant" => :nombre_bouches_entree_dair,
          "vmc_simple_flux_marque_bouches_entree_dair_manquant" => :marque_bouches_entree_dair,
          "vmc_simple_flux_reference_bouches_entree_dair_manquant" => :reference_bouches_entree_dair,
          "vmc_simple_flux_emplacement_bouches_entree_dair_manquant" => :emplacement_bouches_entree_dair
        }

        # TODO : - Marque et référence et type des bouches d’entrée d’air
        # Nombre et emplacement (pour rappel uniquement dans les pièces seches)
        # Si menuisier qui installe → à Préciser dans le devis

        # TODO: V1 : vérifier classe energetique du caisson B ou supérieur
        # TODO V1 : ⇒ Caisson basse conso avec puissance electrique absobée pondéréé ≤ 15 WThC
        # (configuration T4 avec 1 salle de bain et 1WC)

        fields.each do |error_message, field|
          add_error_if(error_message, geste[field].blank?, geste)
        end
      end

      def validate_vmc_double_flux(geste)
        validate_ventilation(geste)

        fields = {
          "vmc_double_flux_marque_bouches_soufflage_manquant" => :marque_bouches_soufflage,
          "vmc_double_flux_reference_bouches_soufflage_manquant" => :reference_bouches_soufflage,
          "vmc_double_flux_emplacement_bouches_soufflage_manquant" => :emplacement_bouches_soufflage,
          "vmc_double_flux_nombre_bouches_soufflage_manquant" => :nombre_bouches_soufflage
        }

        # TODO: V1 :
        # Marque et référence  nombre et emplace des bouches de soufflage
        # Caisson de classe d’efficacité énergétique A ou supérieur (MPR)
        # Efficacité thermique de l’échangeur > 85% (Equivalent à un caisson certifié NF 205 ou equivalent)

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
                  value: geste[:intitule])
      end
    end
  end
end
