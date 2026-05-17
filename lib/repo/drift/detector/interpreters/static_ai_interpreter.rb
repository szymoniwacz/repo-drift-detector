# frozen_string_literal: true

require 'repo/drift/detector/explanation/ai_response_composer'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'

module Repo
  module Drift
    module Detector
      class StaticAiInterpreter
        def interpret(context, signal_brief: true)
          ctx = normalize_context(context)
          PromptBuilder.new(ctx).build

          AiResponseComposer.new(ctx).compose(include_signal_insights: signal_brief)
        end

        private

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
