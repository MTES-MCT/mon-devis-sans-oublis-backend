# frozen_string_literal: true

require "nokogiri"

require_relative "quote_error_email_generator_wordings"

# Generate email content for quote errors
# Transcribed from React component QuoteErrorSharingCard of the frontend:
# https://github.com/MTES-MCT/mon-devis-sans-oublis-frontend/blob/main/src/components/QuoteErrorSharingCard/QuoteErrorSharingCard.modal.tsx
# TODO: Refactor in more Ruby way but stick with serialization source to ensure clean data access
class QuoteErrorEmailGenerator # rubocop:disable Metrics/ClassLength
  attr_reader :quote_check, :quotes_case

  # Filter active errors (not deleted)
  def self.get_active_errors(error_list)
    error_list.reject(&:deleted)
  end

  # Generate email header in HTML
  def self.generate_email_header(filename = nil, date_analyse = Time.zone.now)
    nom_fichier = filename || QuoteErrorEmailGeneratorWordings.file_unknown

    "#{QuoteErrorEmailGeneratorWordings.get_email_header(date_analyse, nom_fichier)}\n\n"
  end

  # Generate header for a case
  def self.generate_case_email_header(quotes_case, date_analyse = Time.zone.now)
    id_dossier = quotes_case.id || "Identifiant inconnu"

    "#{QuoteErrorEmailGeneratorWordings.get_case_email_header(date_analyse, id_dossier)}\n\n"
  end

  # Generate admin errors section in HTML
  def self.generate_admin_section(admin_errors)
    return "" if admin_errors.empty?

    error_items = admin_errors
                  .map { |error| "      <li>#{error.title}</li>" }
                  .join("\n")

    "  <li><strong>#{QuoteErrorEmailGeneratorWordings.administrative_section}</strong>\n    " \
      "<ul>\n" \
      "#{error_items}\n    " \
      "</ul>\n  " \
      "</li>\n  " \
      "<br>\n"
  end

  # Group technical errors by geste
  def self.group_errors_by_geste(gestes_errors)
    gestes_errors.each_with_object({}) do |error, error_groups|
      geste_id = error.geste_id || QuoteErrorEmailGeneratorWordings.not_specified
      error_groups[geste_id] ||= []
      error_groups[geste_id] << error
    end
  end

  # Generate technical section in HTML
  def self.generate_technical_section(gestes_errors, gestes = []) # rubocop:disable Metrics/MethodLength
    return "" if gestes_errors.empty?

    errors_by_geste = group_errors_by_geste(gestes_errors)

    gestes_sections = errors_by_geste.map do |geste_id, errors|
      geste = gestes.find { |g| g.id == geste_id }
      geste_intitule = geste&.intitule || "#{QuoteErrorEmailGeneratorWordings.not_specified} #{geste_id}"

      error_items = errors
                    .map { |error| "        <li>#{error.title}</li>" }
                    .join("\n")

      "      <li><strong>#{geste_intitule}</strong>\n        " \
        "<ul>\n" \
        "#{error_items}\n        " \
        "</ul>\n      " \
        "</li>"
    end.join("\n      <br>\n")

    "  <li><strong>#{QuoteErrorEmailGeneratorWordings.technical_section}</strong>\n    " \
      "<ul>\n" \
      "#{gestes_sections}\n    " \
      "</ul>\n  " \
      "</li>\n  " \
      "<br>\n"
  end

  # Separate errors by category
  def self.separate_errors_by_category(errors)
    admin_errors = error_details_admin(errors)
    gestes_errors = error_details_gestes(errors)
    incoherence_errors = errors&.filter { it["category"] == "case_incoherence" }

    {
      admin_errors:,
      gestes_errors:,
      incoherence_errors:
    }
  end

  # Generate incoherence section
  def self.generate_incoherence_section(incoherence_errors)
    return "" if incoherence_errors.empty?

    error_items = incoherence_errors
                  .map { |error| "      <li>#{error.title}</li>" }
                  .join("\n")

    "  <li><strong>Erreurs de cohérence entre devis</strong>\n    " \
      "<ul>\n" \
      "#{error_items}\n    " \
      "</ul>\n  " \
      "</li>\n  " \
      "<br>\n"
  end

  # Generate content for individual quote
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.generate_quote_section(quote, index) # rubocop:disable Metrics/MethodLength
    return "" if quote.error_details.blank?

    active_errors = get_active_errors(quote.error_details)
    return "" if active_errors.empty?

    separated = separate_errors_by_category(active_errors)
    admin_errors = separated[:admin_errors]
    gestes_errors = separated[:gestes_errors]

    admin_section = admin_errors.any? ? generate_admin_section(admin_errors) : ""
    technical_section = gestes_errors.any? ? generate_technical_section(gestes_errors, quote.gestes || []) : ""

    return "" if admin_section.empty? && technical_section.empty?

    sections = [admin_section, technical_section].reject(&:empty?)

    "  <li><strong>Devis #{index + 1} - #{quote.filename}</strong>\n    " \
      "<ul>\n" \
      "#{sections.join}    </ul>\n  " \
      "</li>\n  " \
      "<br>\n"
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # Generate email content from separated error lists (QuoteCheck mode)
  # admin_error_list, gestes_error_list, gestes = [], filename = nil
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.generate_email_content(quote_check) # rubocop:disable Metrics/MethodLength
    quote_check = wrap_serializer(quote_check, QuoteCheckSerializer)

    admin_error_list = error_details_admin(quote_check.error_details) || []
    gestes_error_list = error_details_gestes(quote_check.error_details) || []
    gestes = quote_check.gestes || []
    filename = quote_check.filename

    date_string = quote_check.finished_at || quote_check.started_at || quote_check.created_at
    date_analyse = date_string ? Time.zone.parse(date_string) : Time.zone.now

    active_admin_errors = get_active_errors(admin_error_list)
    active_gestes_errors = get_active_errors(gestes_error_list)

    if active_admin_errors.empty? && active_gestes_errors.empty?
      return "<p>#{QuoteErrorEmailGeneratorWordings.no_errors}</p>"
    end

    header = generate_email_header(filename, date_analyse)
    admin_section = generate_admin_section(active_admin_errors)
    technical_section = generate_technical_section(active_gestes_errors, gestes)

    sections = [admin_section, technical_section].reject(&:empty?)

    if sections.empty?
      header + "<p>#{QuoteErrorEmailGeneratorWordings.no_errors}</p>"
    else
      header + "<ul>\n#{sections.join}\n</ul>"
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # Generate email content for a QuoteCase (case/dossier)
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def self.generate_case_email_content(quotes_case) # rubocop:disable Metrics/MethodLength
    quotes_case = wrap_serializer(quotes_case, QuotesCaseSerializer)

    date_string = quotes_case.finished_at || quotes_case.started_at || quotes_case.created_at
    date_analyse = date_string ? Time.zone.parse(date_string) : Time.zone.now

    header = generate_case_email_header(quotes_case, date_analyse)

    case_errors = quotes_case.error_details ? get_active_errors(quotes_case.error_details) : []
    separated = separate_errors_by_category(case_errors)
    incoherence_errors = separated[:incoherence_errors]

    incoherence_section = generate_incoherence_section(incoherence_errors)

    quote_sections = (quotes_case.quote_checks || [])
                     .each_with_index
                     .map { |quote, index| generate_quote_section(quote, index) }
                     .reject(&:empty?)

    all_sections = [incoherence_section, *quote_sections].reject(&:empty?)

    if all_sections.empty?
      header + "<p>#{QuoteErrorEmailGeneratorWordings.no_errors}</p>"
    else
      header + "<ul>\n#{all_sections.join}\n</ul>"
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # Reuse JSON serialization like frontend ensure to data access and format
  def self.wrap_serializer(object, serializer_class)
    serializer = serializer_class.new(object)
    serialization = ActiveModelSerializers::Adapter.create(serializer)
    json = JSON.parse(serialization.to_json)

    HashOstruct.new(json).to_ostruct_recursive
  end

  def self.error_details_admin(error_details)
    error_details&.filter { it["category"] == "admin" }
  end

  def self.error_details_gestes(error_details)
    error_details&.filter { it["category"] == "gestes" }
  end

  def initialize(quote_object = nil, quote_check: nil, quotes_case: nil)
    value = quote_object || quotes_case || quote_check
    case value
    when QuotesCase
      @quotes_case = value
    when QuoteCheck
      @quote_check = value
    else
      raise ArgumentError, "Either quote_check or quotes_case must be provided"
    end
  end

  def html
    @html ||= if quotes_case
                self.class.generate_case_email_content(quotes_case)
              elsif quote_check
                self.class.generate_email_content(quote_check)
              end
  end

  def text
    Nokogiri::HTML(html).text.gsub(/\A\n+|\n+\z/, "") if html
  end
end
