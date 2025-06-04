# frozen_string_literal: true

module ActiveAdmin
  # Specialized view helpers for ActiveAdmin
  module ViewHelpers
    def local_time(time)
      time&.in_time_zone("Europe/Paris")&.strftime("%d/%m/%Y %H:%M")
    end
  end
end
