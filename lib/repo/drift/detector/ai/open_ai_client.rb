# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

require 'repo/drift/detector/ai/configuration_error'

module Repo
  module Drift
    module Detector
      module Ai
        class OpenAiClient
          DEFAULT_MODEL = 'gpt-4o-mini'
          API_URL = 'https://api.openai.com/v1/chat/completions'
          SYSTEM_MESSAGE = 'You explain repository drift risk from deterministic file-change signals only.'

          def initialize(api_key: ENV.fetch('OPENAI_API_KEY', nil), model: ENV.fetch('OPENAI_MODEL', DEFAULT_MODEL))
            @api_key = api_key
            @model = model
          end

          def complete(prompt)
            validate_configuration!

            response_body = perform_request(build_request_body(prompt))
            parse_explanation(response_body)
          end

          private

          attr_reader :api_key, :model

          def validate_configuration!
            return if api_key.is_a?(String) && !api_key.strip.empty?

            raise ConfigurationError,
                  'OPENAI_API_KEY is not set. Export OPENAI_API_KEY to use --interpreter ai.'
          end

          def build_request_body(prompt)
            {
              model: model,
              messages: [
                { role: 'system', content: SYSTEM_MESSAGE },
                { role: 'user', content: prompt }
              ]
            }
          end

          def perform_request(body)
            uri = URI(API_URL)
            request = build_post_request(uri, body)

            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
              response = http.request(request)
              unless response.is_a?(Net::HTTPSuccess)
                raise ConfigurationError, "OpenAI request failed with status #{response.code}."
              end

              return response.body
            end
          end

          def build_post_request(uri, body)
            request = Net::HTTP::Post.new(uri)
            request['Authorization'] = "Bearer #{api_key}"
            request['Content-Type'] = 'application/json'
            request.body = JSON.generate(body)
            request
          end

          def parse_explanation(response_body)
            payload = JSON.parse(response_body)
            content = payload.dig('choices', 0, 'message', 'content')
            return content.strip if content.is_a?(String) && !content.strip.empty?

            raise ConfigurationError, 'OpenAI response did not include explanation text.'
          rescue JSON::ParserError
            raise ConfigurationError, 'OpenAI response was not valid JSON.'
          end
        end
      end
    end
  end
end
