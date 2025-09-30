# frozen_string_literal: true

module QuoteReader
  # Read Quote text to extract Quote attributes Naively
  class NaiveText < Text # rubocop:disable Metrics/ClassLength
    VERSION = "0.0.1"

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def read
      return {} if text.blank?

      @read_attributes = TrackingHash.nilify_empty_values({
                                                            # 1. Quote informations
                                                            devis: self.class.find_mention_devis(text),
                                                            # numero_devis: self.class.find_numero_devis(text),
                                                            client: {
                                                              # adresse: self.class.find_adresses(text).first,
                                                              # adresse_chantier: self.class.find_adresse_chantier(text)
                                                            },
                                                            pro: {
                                                              # adresse: self.class.find_adresse_pro(text),
                                                              # capital: self.class.find_capital(text),
                                                              # forme_juridique: self.class.find_forme_juridique(text),
                                                              # labels: self.class.find_label_numbers(text),
                                                              numero_tva: self.class.find_numeros_tva(text).first,
                                                              # raison_sociale: self.class.find_raison_sociale(text),
                                                              # rge_number: self.class.find_rge_numbers(text).first,
                                                              siret: self.class.find_sirets(text).first
                                                            },

                                                            # 2. Generic personal and professional informations
                                                            # adresses: self.class.find_adresses(text),
                                                            emails: self.class.find_emails(text),
                                                            ibans: self.class.find_ibans(text),
                                                            # labels: self.class.find_label_numbers(text),
                                                            names: [
                                                              # self.class.find_raison_sociale(text)
                                                            ],
                                                            numeros_tva: self.class.find_numeros_tva(text),
                                                            powered_by: self.class.find_powered_by(text),
                                                            rcss: self.class.find_rcss(text),
                                                            sirets: self.class.find_sirets(text),
                                                            telephones: self.class.find_telephones(text),
                                                            terms: self.class.find_terms(text),
                                                            uris: self.class.find_uris(text)
                                                          })
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    NUMBER_REFERENCE_REGEX = /n?[.°]/i

    BETWEEN_LABEL_VALUE_REGEX = /\s*(?:#{NUMBER_REFERENCE_REGEX})?\s*(?::\s*)?/i
    EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
    FORME_JURIDIQUE_REGEX = /
    (?:                   # Begin group for legal forms
      E\.?I             | # Entreprise Individuelle
      E\.?I\.?R\.?L     | # Entreprise Individuelle à Responsabilité Limitée
      E\.?U\.?R\.?L     | # Entreprise Unipersonnelle à Responsabilité Limitée
      S\.?A\.?R\.?L     | # Société à Responsabilité Limitée
      S\.?A\.?S\.?U?    | # Société par Actions Simplifiée (Unipersonnelle optional)
      S\.?N\.?C         | # Société en Nom Collectif
      S\.?C\.?O\.?P     | # Société Coopérative Ouvrière de Production
      G\.?I\.?E         | # Groupement d'Intérêt Économique
      S\.?E\.?M         | # Société d'Économie Mixte
      S\.?A             # Société Anonyme
    )
    \.?                 # Optional period at the end
    /xi
    FRENCH_ADDRESS_REGEX = /(?:\d{1,4}\s)?(?:[A-Za-zÀ-ÖØ-öø-ÿ'\-\s]+),?\s(?:\d{5})\s(?:[A-Za-zÀ-ÖØ-öø-ÿ'\-\s]+)/i
    FRENCH_CHARACTER_REGEX = /[\wÀ-ÖØ-öø-ÿ]/i
    PHONE_REGEX = /(?:\(?\+?33\)?)?\s?(?:[\s.]*\d\d){5}/i # TODO: find better
    RCS_REGEX = /R\.?C\.?S\.?(?:\s+[A-Za-zÀ-ÖØ-öø-ÿ\s-]+)?(?:\s+[AB])?\s+\d{9}/i
    SPACE_WITHOUT_NEWLINE_REGEX = /[ \t\f\v\r]*/i
    URI_REGEX = %r{(?:https?|ftp)://(?:www\.)?[^\s/$.?#].[^\s]*|www\.[^\s/$.?#].[^\s]*}i

    SIRET_REGEX = /\d{3}#{SPACE_WITHOUT_NEWLINE_REGEX}\d{3}#{SPACE_WITHOUT_NEWLINE_REGEX}\d{3}#{SPACE_WITHOUT_NEWLINE_REGEX}\d{5}/i # rubocop:disable Layout/LineLength

    def self.find_adresses(text)
      (text.scan(/Adresse#{BETWEEN_LABEL_VALUE_REGEX}(#{FRENCH_CHARACTER_REGEX}+)/i).flatten +
        text.scan(/(#{FRENCH_ADDRESS_REGEX})/i).flatten).filter_map { it&.strip }.uniq
    end

    def self.find_adresse_chantier(text)
      text[/Adresse chantier#{BETWEEN_LABEL_VALUE_REGEX}(#{FRENCH_CHARACTER_REGEX}+)/i, 1].presence ||
        find_adresses(text).first
    end

    def self.find_adresse_pro(text)
      text[/Adresse Pro#{BETWEEN_LABEL_VALUE_REGEX}(#{FRENCH_CHARACTER_REGEX}+)/i, 1].presence ||
        find_adresses(text).first
    end

    def self.find_assurance(text)
      text[/Assurance(?:\s+décennale)?#{BETWEEN_LABEL_VALUE_REGEX}((?:[#{FRENCH_CHARACTER_REGEX}:]+\s+)+(?:#{NUMBER_REFERENCE_REGEX}\s*)?(?:contrat\s+#{FRENCH_CHARACTER_REGEX}*\s*\d+)?)/i, 1].presence # rubocop:disable Layout/LineLength
    end

    def self.find_capital(text)
      text[/(?:Capitale?|capilâide)(?:\s+de)?#{BETWEEN_LABEL_VALUE_REGEX}(\d+(?: \d{3})*)#{SPACE_WITHOUT_NEWLINE_REGEX}€/i, 1].presence # rubocop:disable Layout/LineLength
    end

    def self.find_emails(text)
      text.scan(/\b(#{EMAIL_REGEX})\b/i).flatten.filter_map { it&.strip }.uniq
    end

    def self.find_forme_juridique(text)
      text[/\b(#{FORME_JURIDIQUE_REGEX})\b/, 1].presence
    end

    def self.find_ibans(text)
      text.scan(
        /(?:IBAN|RIB)#{BETWEEN_LABEL_VALUE_REGEX}(FR\d{2}\s?(?:\d{4}\s?){2,5}#{FRENCH_CHARACTER_REGEX}?\d{2})/i
      ).flatten.filter_map { it&.strip }.uniq
    end

    def self.find_label_numbers(text)
      # Warning : insure caracter before not match the IBAN
      text.scan(
        %r{(?:\A|.*?#{BETWEEN_LABEL_VALUE_REGEX})((?:(?:CPLUS|QB|QPAC|QPV|QS|VPLUS)#{SPACE_WITHOUT_NEWLINE_REGEX}/#{SPACE_WITHOUT_NEWLINE_REGEX}|(?:R|E-)?E)#{SPACE_WITHOUT_NEWLINE_REGEX}\d{5,6})(?!\n)}i # rubocop:disable Layout/LineLength
      ).flatten.filter_map { it&.strip }.uniq
    end

    def self.find_mention_devis(text)
      text[/devis/i] if text
    end

    def self.find_numero_devis(text)
      text[/DEVIS\s+N.?\s*(#{FRENCH_CHARACTER_REGEX}*\d{4,})/i, 1].presence
    end

    def self.find_numeros_tva(text)
      text.scan(/\bFR[A-Z0-9]{2}\d{9}\b/i).flatten.filter_map { it&.strip }.uniq
    end

    def self.find_powered_by(text)
      text.scan(
        /Powered by TCPDF \(www\.tcpdf\.org\)/i
      )
    end

    def self.find_raison_sociale(text)
      forme_jurique_raison_sociale_regex = /#{FORME_JURIDIQUE_REGEX}\s+.+|.+\s+#{FORME_JURIDIQUE_REGEX}/i

      text[/(#{forme_jurique_raison_sociale_regex})(?:\s+.*)?\Z/, 1].presence ||
        text[/\A(?:.*\s)?+(#{forme_jurique_raison_sociale_regex}\s+.+)\s+/, 1].presence ||
        text[/Raison sociale#{BETWEEN_LABEL_VALUE_REGEX}(#{FRENCH_CHARACTER_REGEX}+)/i, 1].presence
    end

    def self.find_rge_numbers(text)
      find_label_numbers(text).select { |label_number| label_number.start_with?(/(?:R|E-)?E?/i) }
    end

    def self.find_rcss(text)
      text.scan(/\b(#{RCS_REGEX})\b/i).flatten.filter_map { it&.strip }.uniq
    end

    def self.find_sirets(text)
      text.scan(/\b(#{SIRET_REGEX})\b/i).flatten.filter_map(&:strip).uniq
    end

    def self.find_telephones(text)
      text.scan(
        /(?:T[eé]l\.?(?:[eé]phone)#{BETWEEN_LABEL_VALUE_REGEX})?(#{PHONE_REGEX})/i
      ).flatten.filter_map { it&.strip }.uniq
    rescue Regexp::TimeoutError => e # Skip too long RegExp
      ErrorNotifier.notify(e)
      []
    end

    def self.find_terms(text)
      text.scan(
        /CONDITIONS(?: G[EÉ]N[EÉ]RALES DE)? VENTE.+\z/im
      )
    end

    def self.find_uris(text)
      text.scan(/\b(#{URI_REGEX})\b/i).flatten.filter_map { it&.strip }.uniq
    end
  end
end
