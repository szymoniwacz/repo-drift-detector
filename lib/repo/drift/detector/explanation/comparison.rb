# frozen_string_literal: true

require 'repo/drift/detector/interpreters/deterministic_interpreter'
require 'repo/drift/detector/interpreters/static_ai_interpreter'

module Repo
  module Drift
    module Detector
      class ExplanationComparison
        NOTES = [
          'deterministic explanation is more signal-oriented',
          'static-ai explanation is more interpretive'
        ].freeze

        def self.build(context)
          deterministic = DeterministicInterpreter.new
          static_ai = StaticAiInterpreter.new

          {
            deterministic: deterministic.interpret(context),
            static_ai: static_ai.interpret(context, signal_brief: false),
            notes: NOTES
          }
        end
      end
    end
  end
end
