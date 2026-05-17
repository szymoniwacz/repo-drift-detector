# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      module Renderers
        class ExplanationMarkdownRenderer
          TITLES = {
            'deterministic' => 'Explanation',
            'static-ai' => 'Static AI Explanation',
            'ai' => 'AI Explanation'
          }.freeze

          def render(interpreter_name:, explanation:)
            title = TITLES.fetch(interpreter_name, 'Explanation')

            ["## #{title}", '', explanation].join("\n")
          end
        end
      end
    end
  end
end
