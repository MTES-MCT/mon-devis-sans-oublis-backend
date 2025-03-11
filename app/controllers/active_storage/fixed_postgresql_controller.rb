# frozen_string_literal: true

module ActiveStorage
  # Extend https://github.com/lsylvester/active_storage-postgresql/blob/main/app/controllers/active_storage/postgresql_controller.rb
  # to fix integration with ActiveStorage::Verifier
  # See API routes mounting for the difference
  class FixedPostgresqlController < ActiveStorage::PostgresqlController
    private

    def decode_verified_key
      if params.key?(:signed_id)
        return ActiveSupport::HashWithIndifferentAccess.new(
          ActiveStorage.verifier.verified(params[:signed_id], purpose: :blob_key)
        )
      end

      super
    end
  end
end
