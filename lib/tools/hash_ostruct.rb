# frozen_string_literal: true

require "ostruct" # Included in Rails

# A Hash subclass that can be converted to OpenStruct recursively
class HashOstruct < Hash
  def initialize(hash = {})
    super()
    merge!(hash)
  end

  def to_ostruct_recursive
    OpenStruct.new(transform_values do |value| # rubocop:disable Style/OpenStructUse
      case value
      when Array
        value.map { |item| item.is_a?(Hash) ? HashOstruct.new(item).to_ostruct_recursive : item }
      when Hash
        HashOstruct.new(value).to_ostruct_recursive
      else
        value
      end
    end)
  end
end
