# frozen_string_literal: true

# Base serializer for all serializers
class BaseSerializer < ActiveModel::Serializer
  # Do not render null attributes in response
  def attributes(*args)
    super.compact # Removes nil values
  end
end
