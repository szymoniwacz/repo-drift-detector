# frozen_string_literal: true

require 'repo/drift/detector/ai/open_ai_client'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'

module Repo
  module Drift
    module Detector
      module Interpreters
        class AiInterpreter
          RESPONDER_INSTRUCTIONS = [
            'Write a concise explanation in an engineering tone.',
            'Explain only from the deterministic signals provided above.',
            'Do not invent architecture, intent, or risks beyond those signals.',
            'Do not mention file names or paths that were not provided.',
            'Do not speculate about hidden intent.'
          ].join("\n")

          def initialize(client: nil)
            @client = client
          end

          def interpret(context)
            ctx = normalize_context(context)
            prompt = build_prompt(ctx)
            ai_client.complete(prompt)
          end

          private

          attr_reader :client

          def build_prompt(ctx)
            [PromptBuilder.new(ctx).build, RESPONDER_INSTRUCTIONS].join("\n\n")
          end

          def ai_client
            @ai_client ||= client || Ai::OpenAiClient.new
          end

          def normalize_context(context)
            return context.to_h if context.is_a?(ExplanationContext)

            data = context.transform_keys(&:to_sym)
            return normalize_patterns(data) if data.key?(:repository_patterns)

            ExplanationContext.new(data).to_h
          end

          def normalize_patterns(data)
            data.tap do |normalized|
              normalized[:repository_patterns] = normalized[:repository_patterns].transform_keys(&:to_sym)
            end
          end
        end
      end
    end
  end
end
