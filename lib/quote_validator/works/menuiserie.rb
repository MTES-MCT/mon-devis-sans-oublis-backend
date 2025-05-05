# frozen_string_literal: true

#################################################
####              MENUISERIE                 ####
#################################################

module QuoteValidator
  module Works
    # Validator for the Work
    class Menuiserie < Base
      # validation des critères communs à toutes les menuiseries
      # rubocop:disable Metrics/AbcSize
      def validate_menuiserie(geste)
        add_error_if("menuiserie_marque_manquant", geste[:marque].blank?, geste)
        add_error_if("menuiserie_reference_manquant", geste[:reference].blank?, geste)
        add_error_if("menuiserie_type_materiau_manquant", geste[:type_materiaux].blank?, geste) # bois, alu, pvc ...
        add_error_if("menuiserie_localisation_manquant", geste[:localisation].blank?, geste)

        return unless geste[:type] != "menuiserie_volet_isolant"

        add_error_if("menuiserie_type_vitrage_manquant", geste[:type_vitrage].blank?, geste) # simple - double vitrage
        add_error_if("menuiserie_type_pose_manquant", geste[:type_pose].blank?, geste) # renovation ou depose totale
        # nu intérieur, nu extérieur, tunnel ...
        add_error_if("menuiserie_position_paroie_manquant", geste[:position_paroie].blank?, geste)
      end
      # rubocop:enable Metrics/AbcSize

      def validate_menuiserie_fenetre(geste)
        validate_menuiserie(geste)
        add_error_if("menuiserie_uw_fenetre_manquant", geste[:uw].blank?, geste)
        add_error_if("menuiserie_sw_fenetre_manquant", geste[:sw].blank?, geste)
        # V1, check valeurs : Uw ≤ 1,3 W/m².K et Sw ≥ 0,3 OU Uw ≤ 1,7 W/m².K et Sw ≥ 0,36
      end

      def validate_menuiserie_fenetre_toit(geste)
        validate_menuiserie(geste)
        add_error_if("menuiserie_uw_fenetre_toit_manquant", geste[:uw].blank?, geste)
        add_error_if("menuiserie_sw_fenetre_toit_manquant", geste[:sw].blank?, geste)
        # V1, check valeurs : (Uw ≤ 1,5 W/m².K et Sw ≤ 0,36 )
      end

      def validate_menuiserie_porte(geste)
        validate_menuiserie(geste)
        add_error_if("menuiserie_ud_porte_manquant", geste[:ud].blank?, geste) # TODO : Que CEE ?
        # v1, check valeurs : Ud ≤ 1,7 W/m².K
      end

      def validate_menuiserie_volet_isolant(geste)
        validate_menuiserie(geste)

        add_error_if("menuiserie_deltar_volet_manquant", geste[:deltaR].blank?, geste) # TODO: Que CEE ?
        # v1, check valeurs :La résistance thermique additionnelle DeltaR (DeltaR ≥ 0,22 m².K/W)
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
