# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"
require "net/http"
require "uri"

module QuoteReader
  module Image
    # Read Quote from image file to extract Quote text via Albert OCR
    class AlbertOcr < Base # rubocop:disable Metrics/ClassLength
      attr_reader :model, :result

      DEFAULT_MODEL = ENV.fetch("ALBERT_OCR_MODEL", "mistralai/Mistral-Small-3.1-24B-Instruct-2503")
      HOST = Llms::Albert::HOST

      def initialize(content, content_type, quote_file: nil, model: DEFAULT_MODEL)
        super(content, content_type, quote_file:)
        @api_key = ENV.fetch("ALBERT_API_KEY")
        @model = model || DEFAULT_MODEL
      end

      def self.configured?
        ENV.key?("ALBERT_API_KEY")
      end

      def self.sort_models(models)
        Llms::Base.sort_models(models)
      end

      # Using Albert OCR model
      def extract_text_from_image(model: nil)
        @model = model if model

        content = albert_ocr(model:)
        raise ResultError, "Content empty" unless content

        @pages_text = @text = content
      rescue Net::ReadTimeout => e
        raise TimeoutError, e
      end

      def ocr
        "AlbertOcr"
      end

      def models
        Llms::Albert.new("").models
      end

      private

      def headers
        {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@api_key}"
        }
      end

      # LLM Chat way
      # NOT RECOMMENDED FOR OCR
      # rubocop:disable Metrics/AbcSize
      def albert_chat(model: nil, model_fallback: true, model_type: "image-text-to-text") # rubocop:disable Metrics/MethodLength
        quote_file.start_processing_log("AlbertOcr", "AlbertOcr/LLM") do # rubocop:disable Metrics/BlockLength
          uri = URI("#{HOST}/chat/completions")
          body = {
            model:,
            messages: [
              { role: "system", content: "retranscrit le fichier au format texte" },
              { role: "user", content: [
                { type: "text", text: "donnes-moi la transcription complète" },
                { type: "image_url",
                  # TODO: sending full file content in Base64 is not working
                  # image_url: "data:#{content_type};base64,#{Base64.encode64(content)}"
                  image_url: file_image_url }
              ] }
            ]
          }

          http = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true)
          http.read_timeout = 120 # seconds
          request = Net::HTTP::Post.new(uri, headers)
          request.body = body.to_json
          response = http.request(request)
          raise TimeoutError if response.code == "504"

          # Auto switch model if not found
          if response.code == "404" && model_fallback
            backup_model = (self.class.sort_models(
              models.filter { it.fetch("type") == model_type }
                    .map { it.fetch("id") }
            ) - [model].compact).first
            raise ResultError, "Model #{model} not found" unless backup_model

            return albert_chat(model: backup_model, model_fallback: false)
          end
          raise ResultError, "Error: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

          @result = JSON.parse(response.body)
          result.dig("choices", 0, "message", "content")
        end
      end
      # rubocop:enable Metrics/AbcSize

      # Packaged way
      # See documentation https://albert.api.etalab.gouv.fr/documentation#tag/Ocr/operation/ocr_v1_ocr_beta_post
      # Currently ONLY PDF
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def albert_ocr(model: nil, model_fallback: true, model_type: "image-text-to-text") # rubocop:disable Metrics/MethodLength
        quote_file.start_processing_log("AlbertOcr", "AlbertOcr/Ocr") do # rubocop:disable Metrics/BlockLength
          connection = Faraday.new(url: HOST, headers: headers.slice("Authorization")) do |f|
            f.request :multipart
            f.request :url_encoded
            f.adapter Faraday.default_adapter
          end

          io = StringIO.new(quote_file.content)
          payload = {
            file: Faraday::Multipart::FilePart.new(io, content_type, quote_file.filename),
            model:
          }
          response = connection.post("/v1/ocr-beta", payload)
          @result = JSON.parse(response.body)

          case response.status
          when 400
            if @result["detail"]&.match?(/file must be/i)
              raise QuoteReader::UnsupportedFileType,
                    @result.fetch("detail")
            end
          when 401, 403
            raise Llms::Albert::UnauthorizedError, @result.fetch("detail")
          when 404
            if @result["detail"]&.match?(/model not found/i) && model_fallback
              backup_model = (self.class.sort_models(
                models.filter { it.fetch("type") == model_type }
                      .map { it.fetch("id") }
              ) - [model].compact).first
              raise ResultError, "Model #{model} not found" unless backup_model

              return albert_ocr(model: backup_model, model_fallback: false)
            end
          end

          raise ResultError, result.fetch("detail") unless result.key?("data")

          result.fetch("data").filter_map do |data|
            raise ResultError, data unless data.key?("content")

            Llms::Base.extract_markdown(data.fetch("content").gsub("Aucun texte détecté", ""))
          end.join("\n\n\n")
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
    end
  end
end
