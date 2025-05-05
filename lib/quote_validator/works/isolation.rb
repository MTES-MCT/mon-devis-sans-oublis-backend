# frozen_string_literal: true

#################################################
####              ISOLATION                  ####
#################################################

module QuoteValidator
  module Works
    # Validator for the Work
    class Isolation < Base
      # Validation des critères communs aux différentes isolations
      def validate_isolation(geste)
        add_error_if("isolation_marque_manquant", geste[:marque_isolant].blank?, geste)
        add_error_if("isolation_reference_manquant", geste[:reference_isolant].blank?, geste)
        add_error_if("isolation_surface_manquant", geste[:surface_isolant].blank?, geste) # TODO : check unité ?
        add_error_if("isolation_epaisseur_manquant", geste[:epaisseur_isolant].blank?, geste) # TODO : check unité ?
        add_error_if("isolation_r_manquant", geste[:resistance_thermique].blank?, geste)

        # TODO : V1 - vérifier les normes
        validate_norme(geste)
      end

      def validate_norme(geste)
        acermi = geste[:numero_acermi]
        norme = geste[:norme_calcul_resistance]

        add_error_if("isolation_norme_acermi_manquant", norme.blank? && acermi.blank?, geste)
      end

      def validate_protection(geste)
        add_error_if(
          "isolation_parement_fixation_protection_manquant",
          !geste[:presence_parement] && !geste[:presence_protection] && !geste[:presence_fixation],
          geste
        )
      end

      def validate_isolation_ite(geste)
        validate_isolation(geste)
        # TODO : check valeur R en V1 - R ≥ 3,7 m².K/W ou R ≥ 4.4 m².K/W si MAR

        # TODO : V1 - présence parement, protection et fixation (pour être éligible MPR, TODO quid CEE)
        validate_protection(geste)
      end

      def validate_isolation_combles(geste)
        validate_isolation(geste)
        # TODO : check valeur R en V1 - R  ≥ 7 m².K/W MPR
      end

      def validate_isolation_rampants(geste)
        validate_isolation(geste)
        # TODO : check valeur R en V1 - R  ≥ 6 m².K/W MPR
      end

      def validate_isolation_toiture_terrasse(geste)
        validate_isolation(geste)

        # TODO : check valeur R en V1 - R ≥ 4,5 m².K/W ou R ≥ 6,5 m².K/W si MAR
        add_error_if(
          "isolation_type_isolation_toiture_terrasse_manquant",
          geste[:type_isolation_toiture_terrasse].blank?,
          geste
        )
      end

      def validate_isolation_iti(geste)
        validate_isolation(geste)
        # TODO : check valeur R en V1 - R ≥ 3,70 m².K/W
        # Protection des conduits de fumées

        # TODO : V1 - présence parement, protection et fixation (pour être éligible MPR, TODO quid CEE)
        validate_protection(geste)
      end

      def validate_isolation_plancher_bas(geste)
        validate_isolation(geste)

        # TODO : check valeur R en V1 - R ≥ 3 m².K/W pour les planchers bas sur sous-sol,
        # sur vide sanitaire ou sur passage ouvert

        add_error_if("isolation_localisation_plancher_bas_manquant", geste[:localisation].blank?, geste)
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
