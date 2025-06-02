# frozen_string_literal: true

# Base serializer for all serializers
class BaseSerializer < ActiveModel::Serializer
  DATE_FORMAT = "%Y-%m-%d"
  DATETIME_FORMAT = "%Y-%m-%dT%H:%M:%S%z" # ISO 8601 format via .iso8601 method

  # Do not render null attributes in response
  def attributes(*args)
    super.compact # Removes nil values
  end

  def created_at
    format_datetime(object.created_at)
  end

  def updated_at
    format_datetime(object.updated_at)
  end

  protected

  def format_date(date)
    date&.strftime(DATE_FORMAT)
  end

  def format_datetime(datetime)
    datetime&.iso8601
  end
end
