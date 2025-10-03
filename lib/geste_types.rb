# frozen_string_literal: true

# Types of renovation actions (gestes)
module GesteTypes
  # From QA prompts
  GROUPS = {
    "Chauffage" => %w[
      chaudiere_biomasse
      systeme_solaire_combine
      poele_insert
      pac_air_air
      pac_air_eau
      pac_hybride
      pac_eau_eau
    ],
    "Eau chaude sanitaire" => %w[
      chauffe_eau_solaire_individuel
      chauffe_eau_thermo
    ],
    "Isolation" => %w[
      isolation_thermique_par_exterieur_ITE
      isolation_thermique_par_interieur_ITI
      isolation_comble_perdu
      isolation_rampants_toiture
      isolation_toiture_terrasse
      isolation_plancher_bas
    ],
    "Menuiserie" => %w[
      menuiserie_fenetre
      menuiserie_volet_isolant
      menuiserie_fenetre_toit
      menuiserie_porte
    ],
    "Ventilation" => %w[
      vmc_double_flux
      vmc_simple_flux
    ]
  }.freeze

  VALUES = GROUPS.values.flatten.freeze

  def self.json_schema
    path = Rails.root.join("swagger/v1/mon-devis-sans-oublis_api_v1_internal_swagger.yaml")
    yml = YAML.safe_load_file(path)
    yml.dig("components", "schemas").fetch("geste_type")
  end
end
