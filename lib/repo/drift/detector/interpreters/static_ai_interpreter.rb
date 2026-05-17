# frozen_string_literal: true

require 'repo/drift/detector/ai_response_composer'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'
require 'repo/drift/detector/interpreters/explanation_interpreter'

module Repo
  module Drift
    module Detector
      class StaticAiInterpreter < ExplanationInterpreter
        def interpret(context, signal_brief: true)
          ctx = normalize_context(context)
          build_internal_prompt(ctx)

          AiResponseComposer.new(ctx).compose(include_signal_insights: signal_brief)
        end

        private

        def build_internal_prompt(ctx)
          PromptBuilder.new(ctx).build
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
