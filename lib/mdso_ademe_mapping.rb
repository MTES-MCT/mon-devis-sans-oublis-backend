# frozen_string_literal: true

# Mapping of ADEME certificate names to MDSO GESTE types
class MdsoAdemeMapping
  # See nom_certificat "Libellé du certificat" on https://data.ademe.fr/data-fair/api/v1/datasets/liste-des-entreprises-rge-2/api-docs.json
  ADEME_DOMAINE_TO_MDSO_GESTE_TYPE = {
    "Isolation par l'intérieur des murs ou rampants de toitures  ou plafonds" =>
      %w[isolation_thermique_par_interieur_ITI isolation_rampants_toiture],
    "Chauffe-Eau Thermodynamique" => "chauffe_eau_thermo",
    "Pompe à chaleur : chauffage" => %w[pac_air_eau pac_eau_eau pac_air_air pac_hybride],
    "Fenêtres, volets, portes donnant sur l'extérieur" =>
    %w[menuiserie_fenetre menuiserie_volet_isolant menuiserie_porte],
    "Isolation des combles perdus" => "isolation_comble_perdu",
    "Isolation des murs par l'extérieur" => "isolation_thermique_par_exterieur_ITE",
    "Poêle ou insert bois" => "poele_insert",
    "Chaudière condensation ou micro-cogénération gaz ou fioul" => nil,
    "Isolation des toitures terrasses ou des toitures par l'extérieur" => "isolation_toiture_terrasse",
    "Fenêtres de toit" => "menuiserie_fenetre_toit",
    "Ventilation mécanique" => %w[vmc_simple_flux vmc_double_flux],
    "Panneaux solaires photovoltaïques" => nil,
    "Isolation des planchers bas" => "isolation_plancher_bas",
    "Audit énergétique Maison individuelle" => nil,
    "Radiateurs électriques, dont régulation." => nil,
    "Architecte" => nil,
    "Chaudière bois" => "chaudiere_biomasse",
    "Chauffage et/ou eau chaude solaire" => %w[chauffe_eau_solaire_individuel systeme_solaire_combine],
    "Audit énergétique Logement collectif" => nil,
    "Etude thermique reglementaire" => nil,
    "Etude solaire photovoltaïque" => nil,
    "Etude forage géothermique" => nil,
    "Etude bois énergie" => nil,
    "Projet complet de rénovation" => nil,
    "Etude solaire thermique" => nil,
    "Etude ACV" => nil,
    "Etude système technique bâtiment" => nil,
    "Etude eclairage" => nil,
    "Inconnu" => nil,
    "Etude enveloppe du bâtiment" => nil,
    "Commisionnement" => nil,
    "Forage géothermique" => nil
  }.to_h do |ademe_domain, mdso_geste_types|
    unknown_geste_types = Array.wrap(mdso_geste_types) - GesteTypes::VALUES
    raise ::NotImplemented, "Unknown Geste type #{unknown_geste_types}" if unknown_geste_types.any?

    [ademe_domain, mdso_geste_types]
  end.sort.to_h.freeze

  ADEME_NOM_CERTIFICAT_TO_MDSO_GESTE_TYPE = {
    "QUALIBAT-RGE" => nil,
    "QualiPAC module Chauffage et ECS" => nil,
    "Certificat OPQIBI" => nil,
    "Tableau de l´Ordre" => nil,
    "Qualibois Eau" => nil,
    "QualiPV 36" => nil,
    "Qualibois Air" => nil,
    "Certificat Qualifelec RGE" => nil,
    "Ventilation +" => nil,
    "Qualisol CESI" => nil,
    "Chauffage +" => %w[chauffe_eau_thermo chauffe_eau_solaire_individuel],
    "QualiPV 500" => nil,
    "Qualisol Combi" => nil,
    "CertiRénov RGE par CERQUAL Qualitel Certification" => nil,
    "QualiPAC module CET" => nil,
    "CERTIBAT-RGE" => nil,
    "AUDIT ENERGETIQUE BATIMENT" => nil,
    "Qualiforage Sonde" => nil,
    "Qualiforage Nappe" => nil,
    "Qualisol Collectif" => nil,
    "RGE Etudes Audits énergétiques Batiments" => nil,
    "CERTIFACT_EUSKADI_EKO" => nil,
    "CERTIFACT_RLB_SQA" => nil,
    "CERTIFICAT_ABCDOMUS" => nil,
    "CERTIFICAT_ADFACTO" => nil,
    "CERTIFICAT_BATIMEX" => nil,
    "CERTIFICAT_BETREC_IG" => nil,
    "CERTIFICAT_BET_PHILIPPE_POULAIN" => nil,
    "CERTIFICAT_CABINET_BAZIN" => nil,
    "CERTIFICAT_CABINET_DENIZOU" => nil,
    "CERTIFICAT_CABINET_HENRI_BRUGNONI_INGENIERIE_HBI" => nil,
    "CERTIFICAT_DPS" => nil,
    "CERTIFICAT_ECHOS" => nil,
    "CERTIFICAT_ECR_HABITAT" => nil,
    "CERTIFICAT_EMIOS" => nil,
    "CERTIFICAT_GBA_CO" => nil,
    "CERTIFICAT_GEXPERTISE" => nil,
    "CERTIFICAT_PLENETUDE" => nil,
    "CERTIFICAT_P_ET_G_PLENETUDE" => nil,
    "CERTIFICAT_SARL_DOMINIQUE_CALLIET" => nil,
    "Certiforage module Sonde" => nil
  }.to_h do |ademe_certificate, mdso_geste_types|
    unknown_geste_types = Array.wrap(mdso_geste_types) - GesteTypes::VALUES
    raise ::NotImplemented, "Unknown Geste type #{unknown_geste_types}" if unknown_geste_types.any?

    [ademe_certificate, mdso_geste_types]
  end.sort.to_h.freeze

  def self.ademe_geste_types(domaine: nil, nom_certificat: nil)
    [
      ADEME_DOMAINE_TO_MDSO_GESTE_TYPE[domaine],
      ADEME_NOM_CERTIFICAT_TO_MDSO_GESTE_TYPE[nom_certificat]
    ].flatten.compact.uniq.sort
  end

  def self.geste_types_with_certification
    (
      ADEME_DOMAINE_TO_MDSO_GESTE_TYPE.values +
      ADEME_NOM_CERTIFICAT_TO_MDSO_GESTE_TYPE.values
    ).flatten.compact.uniq.sort
  end
end
