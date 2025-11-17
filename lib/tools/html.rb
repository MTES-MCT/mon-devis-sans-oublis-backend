# frozen_string_literal: true

require "nokogiri"

# Tools for Html
class Html
  def self.html_to_text(html)
    Nokogiri::HTML(html).text.gsub(/\A\n+|\n+\z/, "") if html
  end
end
