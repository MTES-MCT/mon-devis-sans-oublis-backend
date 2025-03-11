# frozen_string_literal: true

# Extend URI class
class UriExtended
  # Extract host and port if provided
  def self.host_with_port(url)
    uri = URI.parse(url)
    raise URI::InvalidURIError if uri.host.blank?

    port_part = if (uri.scheme == "http" && uri.port != 80) ||
                   (uri.scheme == "https" && uri.port != 443)
                  ":#{uri.port}"
                end

    "#{uri.host}#{port_part}"
  end
end
