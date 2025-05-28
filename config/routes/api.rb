# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  # mount ActiveStorage::Engine => "/rails/active_storage" # For temporary URL generation to share files
  # rails_postgresql_blob GET      /rails/active_storage/postgresql/:signed_id/*filename(.:format)
  # rails_postgresql_service GET      /rails/active_storage/postgresql/:encoded_key/*filename(.:format)
  mount ActiveStorage::PostgreSQL::Engine => "/rails/active_storage" # For temporary URL generation to share files
  # ⚠️ Missing common route rails_postgresql_blob with signed_id
  # rails_postgresql_service GET      /rails/active_storage/postgresql/:encoded_key/*filename(.:format)
  # So override Active Storage PostgreSQL route, see ActiveStorage::FixedPostgresqlController for the fix
  get "/rails/active_storage/postgresql/:signed_id/*filename" => "active_storage/fixed_postgresql#show",
      as: :rails_postgresql_blob

  namespace :api do
    namespace :v1 do
      get "auth/check", to: "auth#check", as: :auth_check

      resources :profiles, only: %i[index]
      resources :renovation_types, only: %i[index]

      scope path: "data_checks", controller: :data_checks do
        get :siret
        get :rge
      end

      resources :quotes_cases, only: %i[create show update]
      resources :quote_checks, only: %i[create show update] do
        collection do
          get :metadata
          get :error_detail_deletion_reasons,
              to: "quote_checks_validation_error_details#validation_error_detail_deletion_reasons"
        end

        resources :feedbacks, only: %i[create], controller: "quote_check_feedbacks"
        resources :quote_checks_validation_error_details,
                  path: "error_details",
                  as: :validation_error_details,
                  only: %i[destroy update] do
          member do
            post "", action: :create
          end
          resources :feedbacks, only: %i[create], controller: "quote_check_feedbacks"
        end
      end
      resources :stats, only: %i[index]
    end
  end

  mount Rswag::Api::Engine => "/api-docs"
  mount Rswag::Ui::Engine => "/api-docs"
end
