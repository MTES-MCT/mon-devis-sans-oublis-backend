# frozen_string_literal: true

# attributes = { sirets: ['50432740400035'] }; ExtendedData.new(attributes).extended_attributes
# Add data from other sources
class ExtendedData
  attr_accessor :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def extended_attributes
    return attributes unless attributes

    data_from_sirets(sirets)
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def data_from_sirets(sirets)
    results = sirets.flat_map do |siret|
      DataAdeme.new.historique_rge(qs: "siret:#{siret}").fetch("results")
    end

    {
      extended_data: {
        from_sirets: results
      },

      adresses: results.map { "#{it['adresse']}, #{it['code_postal']} #{it['commune']}" }.uniq.filter(&:presence),
      emails: results.pluck("email").uniq.filter(&:presence),
      rge_labels: results.pluck("code_qualification").uniq.filter(&:presence),
      noms: results.pluck("nom_entreprise").uniq.filter(&:presence),
      telephones: results.pluck("telephone").uniq.filter(&:presence),
      uris: results.pluck("site_internet").uniq.filter(&:presence)
    }
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  def sirets
    (attributes[:sirets] || []).map { it.strip.gsub(/[^\d]/, "") }
                               .group_by { it }
                               .sort_by { |_, group| -group.size }
                               .map(&:first)
  end
end
