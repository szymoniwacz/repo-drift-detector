# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      module Renderers
        class ComparisonTextRenderer
          def render(comparison)
            [
              '=== Deterministic explanation ===',
              comparison.fetch(:deterministic),
              '',
              '=== Static AI explanation ===',
              comparison.fetch(:static_ai),
              '',
              '=== Comparison notes ===',
              *comparison.fetch(:notes).map { |note| "- #{note}" }
            ].join("\n")
          end
        end
      end
    end
  end
end
