# frozen_string_literal: true

# TrackingHash is a subclass of Hash that tracks the keys that are accessed.
class TrackingHash < Hash
  # rubocop:disable Metrics/MethodLength
  def initialize(constructor = {})
    super()

    @keys_accessed = Set.new

    return unless constructor.is_a?(Hash)

    constructor&.each do |key, value|
      self[key] = if value.is_a?(Hash)
                    TrackingHash.new(value)
                  elsif value.is_a?(Array)
                    value.map { it.is_a?(Hash) ? TrackingHash.new(it) : it }
                  else
                    value
                  end
    end
  end

  # rubocop:enable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.nilify_empty_values(value, compact: false, compact_array: true) # rubocop:disable Metrics/MethodLength
    subvalue = case value
               when Hash
                 value.transform_values { nilify_empty_values(it, compact:, compact_array:) }
               when Array
                 if compact_array
                   value.filter_map { nilify_empty_values(it, compact:, compact_array:) }
                 else
                   value.map { nilify_empty_values(it, compact:, compact_array:) }
                 end
               when value.presence
                 value
               end
    return subvalue unless subvalue.methods.include?(:compact)

    compact ? subvalue&.compact : subvalue
  end

  # rubocop:enable Metrics/CyclomaticComplexity
  def [](key)
    @keys_accessed.add(key)

    unless key?(key)
      return super(key.to_s) if key.is_a?(Symbol)

      return super(key.to_sym) if key.is_a?(String)
    end

    super
  end

  def dig(*keys)
    current = self
    keys.each do |key|
      return nil unless current.is_a?(Hash) || current.is_a?(Array)

      current = current[key] # Reuse overwritten methods
    end

    current
  end

  def keys_accessed
    @keys_accessed.to_a.map do |key|
      if self[key].is_a?(TrackingHash)
        { key => self[key].keys_accessed }
      else
        key
      end
    end
  end
end
