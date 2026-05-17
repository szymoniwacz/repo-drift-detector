# frozen_string_literal: true

require 'repo/drift/detector/explanation_interpreter'
require 'repo/drift/detector/explanation_renderer'

module Repo
  module Drift
    module Detector
      class DeterministicInterpreter < ExplanationInterpreter
        def interpret(context)
          ExplanationRenderer.new(context).render
        end
      end
    end
  end
end
