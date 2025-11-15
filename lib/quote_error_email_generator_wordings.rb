# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# From https://github.com/MTES-MCT/mon-devis-sans-oublis-frontend/blob/main/src/components/QuoteErrorSharingCard/QuoteErrorSharingCard.modal.content.wordings_tsx  def self.wordings
# rubocop:enable Layout/LineLength
class QuoteErrorEmailGeneratorWordings
  def self.file_unknown
    "Fichier inconnu"
  end

  def self.get_email_header(date_analyse, nom_fichier)
    "<p>Bonjour,</p>

<p>Pour être conforme aux attendus des aides, voici les erreurs (détectées lors de l'analyse du #{to_locale_date_string_fr(date_analyse)} du Devis #{nom_fichier}) à corriger. En corrigeant ces erreurs maintenant, vous optimisez vos chances d'une instruction sans demandes complémentaires et vous gagnerez donc beaucoup de temps.</p>" # rubocop:disable Layout/LineLength
  end

  def self.get_case_email_header(date_analyse, id_dossier)
    "<p>Bonjour,</p>

<p>Pour être conforme aux attendus des aides, voici les erreurs (détectées lors de l'analyse du #{to_locale_date_string_fr(date_analyse)} du Dossier #{id_dossier}) à corriger. En corrigeant ces erreurs maintenant, vous optimisez vos chances d'une instruction sans demandes complémentaires et vous gagnerez donc beaucoup de temps.</p>" # rubocop:disable Layout/LineLength
  end

  def self.administrative_section
    "Mentions administratives"
  end

  def self.technical_section
    "Descriptif technique des gestes"
  end

  def self.not_specified
    "Non spécifié"
  end

  def self.no_errors
    "Aucune erreur à signaler."
  end

  # Ruby equivalent to JavaScript toLocaleDateString("fr-FR")
  def self.to_locale_date_string_fr(date)
    date.strftime("%d/%m/%Y")
  end
end
