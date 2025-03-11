# frozen_string_literal: true

# Controller for the Quotes resource
class QuoteChecksController < ApplicationController
  before_action :authenticate, except: %i[profiles], if: -> { !Rails.env.development? }
  before_action :quote_check, only: %i[show edit update]
  before_action :profile, only: %i[new show]

  skip_before_action :verify_authenticity_token, if: -> { request.format.json? && action_name == "new" }

  def index
    @quote_checks = QuoteCheck.order(created_at: :desc).all
  end

  def show
    render_show
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def new
    upload_file = params[:file]

    # Default web form
    if request.format.html? && upload_file.blank?
      @quote_attributes = QuoteCheckService.default_quote_attributes
      render :show
      return
    end

    if upload_file.present?
      @quote_check = QuoteCheckService.new(
        upload_file.tempfile, upload_file.original_filename, params[:profile]
      ).check(qa_llm: params[:qa_llm])
    end

    QuoteCheckMailer.created(@quote_check).deliver_later

    render_show
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def edit
    render_show
  end

  def update
    render_show
  end

  def profiles
    @profiles = QuoteCheck::PROFILES

    respond_to do |format|
      format.html
      format.json { render json: @profiles }
    end
  end

  protected

  def quote_check
    @quote_check ||= QuoteCheck.find(params[:id])
  end

  # rubocop:disable Metrics/MethodLength
  def render_show
    set_quote_check_results

    @quote_check_json_hash = QuoteCheckSerializer.new(quote_check).as_json

    @quote_check_json = {
      errors: @quote_errors,
      error_messages: @quote_errors&.index_with { |error_key| I18n.t("quote_validator.errors.#{error_key}") },
      quote_error_details: @quote_error_details,
      quote_error_categories: @quote_error_categories
    }

    http_status = @quote_valid ? :ok : :unprocessable_entity
    respond_to do |format|
      format.html { render :show, status: http_status }
      format.json do
        render json: @quote_check_json, status: http_status
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def profile
    @profile ||= @quote_check&.profile ||
                 (params[:profile].present? && QuoteCheck::PROFILES.detect { it == params[:profile] })
  end

  def set_quote_check_results
    @quote_attributes = quote_check.read_attributes
    @quote_valid = quote_check.quote_valid?
    @quote_errors = quote_check.validation_errors
    @quote_error_details = quote_check.validation_error_details
    @quote_error_categories = QuoteValidator::Global.error_categories
  end
end
