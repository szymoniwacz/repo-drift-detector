# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class ExplanationInterpreter
        def interpret(_context)
          raise NotImplementedError, "#{self.class} must implement #interpret"
        end
      end
    end
  end
end
