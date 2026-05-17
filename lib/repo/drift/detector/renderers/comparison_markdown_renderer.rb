# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      module Renderers
        class ComparisonMarkdownRenderer
          def render(comparison)
            [
              markdown_section('Deterministic Explanation', comparison.fetch(:deterministic)),
              markdown_section('Static AI Explanation', comparison.fetch(:static_ai)),
              markdown_section('Comparison Notes', bullet_list(comparison.fetch(:notes)))
            ].join("\n\n")
          end

          def markdown_section(title, body)
            ["## #{title}", '', body].join("\n")
          end

          def bullet_list(items)
            items.map { |item| "- #{item}" }.join("\n")
          end
        end
      end
    end
  end
end
