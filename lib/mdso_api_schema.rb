# frozen_string_literal: true

require_relative "geste_types"

# Swagger OpenAPI schema definitions for MDSO API
class MdsoApiSchema # rubocop:disable Metrics/ClassLength
  TYPE_FICHIERS = %w[devis facture autre].freeze # See prompt and lib/quote_validator/file.rb

  def self.prompt_attributes(attributes = %i[
    noms adresses telephones raison_sociales sirets ville_immatriculation_rcss numero_rcss rnes assurances numero_rge
    emails numeros_tva ibans uris client_noms_de_famille client_prenoms client_civilite client_adresses pro_adresses
    forme_juridiques capital_social type_fichier
  ])
    <<~PROMPT
      Contexte : Nous avons un devis pdf, nous avons sorti le texte pour pouvoir l’analyser. Il s’agit d’un devis de rénovation énergétique d’un artisan pour un particulier. Nous devons récupérer tous les attributs qui permettent d'identifier le client, l'artisan et le chantier.#{' '}

      Rôle : Vous êtes un expert en lecture de devis et vous devez récupérer les données structurées du devis pour les intégrer dans un JSON suivant la liste clé/instruction suivante. Vous gardez les clés proposées sans les modifier. Vous renvoyez les données exactement telles qu'elles apparaissent dans le texte, sans transformation ou modification.#{' '}

      #{attributes.map { "- **#{it}** : #{quote_check_private_data_qa_attribute_description!(it)}" }.join("\n")}

      Instructions :

      1. Récupérez les informations générales du devis et intégrez-les dans le JSON.
      2. Si un attribut n'est pas explicitement mentionné dans le texte, laissez-le vide dans le JSON et ne le déduisez pas.
      3. N'oubliez pas de vérifier que les données sont correctes et complètes avant de les traiter.
      4. Le JSON doit avoir maximum 21 entrées et ne pas rajouter d'entrées en plus de celles demandées ci-dessus
      5. Rajoutez dans le JSON, l'attribut suivant : {"version": "2.0.3"}
      6. Ne déduisez aucune information. Si une information n'est pas présente dans le texte, laissez le champ vide.


      Réfléchissez étape par étape.


      Vous ne répondrez que par le JSON
      Ne fournissez pas d’explications.
    PROMPT
  end

  def self.api_error_light(properties: {}) # rubocop:disable Metrics/MethodLength
    {
      type: :object,
      properties: {
        error: { type: :string },
        error_details: {
          type: :array,
          items: { "$ref" => "#/components/schemas/quote_check_error_details_light" },
          description: "liste des erreurs avec détails dans ordre à afficher",
          nullable: true
        },
        valid: { type: :boolean, nullable: true },
        message: {
          type: :array,
          items: { type: :string }
        }
      }.merge(properties),
      additionalProperties: false
    }
  end

  def self.data_check_result(items_schema = nil) # rubocop:disable Metrics/MethodLength
    schema = {
      type: :object,
      properties: {
        error_details: {
          type: :array,
          items: quote_check_error_details_light,
          description: "liste des erreurs avec détails dans ordre à afficher",
          nullable: true
        },
        valid: { type: :boolean, nullable: true }
      },
      additionalProperties: false
    }

    if items_schema
      schema[:properties][:results] = {
        type: :array,
        items: items_schema,
        description: "liste des résultats correspondant à la requête",
        nullable: true
      }
    end

    schema
  end

  def self.geste_properties # rubocop:disable Metrics/MethodLength
    %i[
      classe_caisson
      classe_energetique_ballon
      classe_regulateur
      contenance_silo
      COP
      deltaR
      emission_composés_organique
      emission_monoxyde_carbone
      emission_oxydes_azotes
      emission_particules
      emplacement
      emplacement_bouches_entree_dair
      emplacement_bouches_soufflage
      energie_appoint
      epaisseur_isolant
      ETAS
      fluide_capteur
      intitule
      label_flamme_verte
      localisation
      marque
      marque_bouche_extraction
      marque_bouches_entree_dair
      marque_bouches_soufflage
      marque_caisson
      marque_capteurs
      marque_isolant
      marque_regulateur
      nombre_bouche_extraction
      nombre_bouches_entree_dair
      nombre_bouches_extraction
      nombre_bouches_soufflage
      norme_calcul_resistance
      numero_acermi
      numero_ligne
      position_paroie
      presence_fixation
      presence_note_dimensionnement
      presence_parement
      presence_protection
      prix_ht
      prix_ttc
      prix_unitaire_ht
      productivite_capteurs
      profil_soutirage
      puissance
      puissance_absobée_pondéréé_moteur
      puissance_nominale
      quantite
      reference
      reference_bouche_extraction
      reference_bouches_entree_dair
      reference_bouches_soufflage
      reference_caisson
      reference_capteurs
      reference_isolant
      reference_regulateur
      regime_temperature
      remplacement_chaudiere_condensation
      rendement_energetique
      resistance_thermique
      SCOP
      surface_captage
      surface_capteur
      surface_isolant
      sw
      taux_tva
      type
      type_appoint
      type_capteurs
      type_chargement
      type_combustible
      type_fluide_frigorigene
      type_installation
      type_isolation_toiture_terrasse
      type_materiaux
      type_menuiserie
      type_pose
      type_silo
      type_vitrage
      type_vmc
      ud
      unite
      uw
      volume
      volume_ballon
    ].index_with do |_key| # TODO: make it dynamic according to Geste Type and fix type
      { type: :string, nullable: true, description: "peut-être un type autre que chaîne de caractères" }
    end.merge(
      %i[
        label_flamme_verte
        mention_devis
        presence_fixation
        presence_note_dimensionnement
        presence_parement
        presence_protection
        remplacement_chaudiere_condensation
        separation_prix_fourniture_pose
        validite
      ].index_with do |_key|
        { type: :boolean, nullable: true }
      end
    ).merge(
      %i[
        emission_composés_organique
        emission_monoxyde_carbone
        emission_oxydes_azotes
        emission_particules
        nombre_bouche_extraction
        nombre_bouches_entree_dair
        nombre_bouches_extraction
        nombre_bouches_soufflage
        volume
      ]
      .index_with do |_key|
        { type: :number, nullable: true }
      end
    ).merge(
      %i[
        contenance_silo
        COP
        epaisseur_isolant
        montant_tva_total
        prix_ht
        prix_ht_total
        prix_total_ht
        prix_total_ttc
        prix_ttc
        prix_unitaire_ht
        productivite_capteurs
        puissance
        puissance_absobée_pondéréé_moteur
        puissance_nominale
        quantite
        rendement_energetique
        resistance_thermique
        SCOP
        surface_captage
        surface_capteur
        surface_isolant
        sw
        taux_tva
        uw
        volume_ballon
      ].index_with do |_key|
        float_type(nullable: true)
      end
    ).merge(
      type: { "$ref" => "#/components/schemas/geste_type", nullable: true },
      deltaR: {
        oneOf: [
          { type: :string },
          float_type
        ],
        nullable: true
      },
      ETAS: {
        oneOf: [
          { type: :string },
          float_type
        ],
        nullable: true
      },
      numero_acermi: {
        oneOf: [
          { type: :string },
          { type: :array, items: { type: :string } }
        ],
        nullable: true
      },
      ud: {
        oneOf: [
          { type: :string },
          float_type
        ],
        nullable: true
      }
    )
  end

  def self.quote_check_error_details_light(properties: {}, required: %w[code])
    {
      type: :object,
      properties: { code: { "$ref" => "#/components/schemas/quote_check_error_code" } }.merge(properties),
      additionalProperties: false,
      required:
    }
  end

  def self.quote_check_private_data_qa_attribute_description!(attribute)
    quote_check_private_data_qa_attributes[:properties].fetch(attribute.to_sym).fetch(:description)
  end

  def self.quote_check_private_data_qa_attributes # rubocop:disable Metrics/MethodLength
    # rubocop:disable Layout/LineLength
    {
      type: :object,
      nullable: true,
      properties: {
        client: {
          type: :object,
          properties: {
            adresse: { type: :string, nullable: true },
            civilite: { type: :string, nullable: true },
            nom: { type: :string, nullable: true },
            prenom: { type: :string, nullable: true }
          },
          additionalProperties: false
        },
        pro: {
          type: :object,
          properties: {
            adresse: { type: :string, nullable: true },
            assurance: { type: :string, nullable: true },
            capital: { type: :string, nullable: true },
            forme_juridique: { type: :string, nullable: true },
            numero_tva: { type: :string, nullable: true },
            raison_sociale: { type: :string, nullable: true },
            rcs: { type: :string, nullable: true },
            rcs_ville: { type: :string, nullable: true },
            rge_labels: { type: :array, items: { type: :string } },
            rne: { type: :string, nullable: true },
            siret: { type: :string, nullable: true }
          },
          additionalProperties: false
        },
        noms: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des Noms et prénoms propres mentionnés (individus)."
        },
        rnes: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des numéros RNE (Registre national des entreprises)."
        },
        uris: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des URL et site internet détectés."
        },
        ibans: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des IBAN détectés."
        },
        emails: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des adresses email identifiables."
        },
        sirets: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des numéros SIRET et/ou SIREN."
        },
        type_fichier: {
          type: :string,
          enum: TYPE_FICHIERS,
          nullable: true,
          description: "enum(devis, facture, autre); (\"devis\" pour les devis de rénovation énergétique, \"facture\" pour les factures de rénvoation énergétique, \"autre\" si tu ne détexte pas de poste de travaux de rénovation énergétique compris dans la liste gestes_pertinents)"
        },
        version: {
          type: :string
        },
        adresses: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des adresses postales identifiées."
        },
        assurances: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des numéros et références liées à des contrats d'assurance, notamment l'assurance décennale."
        },
        numero_rge: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des numéros de certification RGE mentionnés. (le format doit être comme un des exemples ci après QB/74612,QS/51778, QPV/59641, QPAC/59641, CPLUS/67225, VPLUS/49707, RE/75071, QFRG/49335, E-E181506  ou RE16128)"
        },
        telephones: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des numéros de téléphone formatés."
        },
        numero_rcss: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des numéros RCS explicitement écrits. Ne pas inclure la ville d'immatriculation dans cet attribut. C'est un nombre à 9 chiffres et doit être explicitement écrit."
        },
        rcs: {
          type: :string,
          nullable: true,
          description: "numéro RCS de l'entreprise, si détecté"
        },
        rcs_ville: {
          type: :string,
          nullable: true,
          description: "ville d'immatriculation RCS de l'entreprise, si détecté"
        },
        rne: {
          type: :string,
          nullable: true,
          description: "numéro RNE de l'entreprise, si détecté"
        },
        numeros_tva: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des numéros de TVA mentionnés (peut être assimilé au Numéro d’Identification Intracommunautaire)"
        },
        pro_adresses: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des adresses postales identifiées des prestataires professionels mentionnés."
        },
        capital_social: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste de capital social identifiés des prestataires professionnels mentionnés."
        },
        client_prenoms: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des prénoms des clients particuliers mentionnés (individus)."
        },
        client_adresses: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des adresses postales identifiées des clients particuliers mentionnés."
        },
        client_civilite: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des civilités des clients particuliers mentionnés (individus) - Il s'agit très souvent d'une abréviation dont voici quelques exemples 'M', 'Mr', 'M.', 'Mme', 'Monsieur', 'Madame'...etc, La civilité comprise dans le devis peut représenter un couple (2 personnes), comme par exemple au pluriel ou avec un 'et'."
        },
        raison_sociales: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des noms d'entreprises identifiables."
        },
        forme_juridiques: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des forme juridiques identifiées des prestataires professionnels mentionnés. La forme juridique peut être comprise dans le nom de la structure directement. (quelques exemples : association, SAS, SASU, EURL, SARL, Entrepreneur individuel ...)"
        },
        client_noms_de_famille: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des Noms propres des clients particuliers mentionnés (individus)."
        },
        ville_immatriculation_rcss: {
          type: :array,
          nullable: true,
          items: { type: :string },
          description: "Liste des villes d'immatriculation au RCS de la structure. Ne remplissez cet attribut que si la ville d'immatriculation au RCS est explicitement indiquée dans le texte. Si elle ne l'est pas, laissez cet attribut vide."
        }
      },
      additionalProperties: false,
      strict: true
    }
    # rubocop:enable Layout/LineLength
  end
end
