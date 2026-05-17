# frozen_string_literal: true

require 'repo/drift/detector/explanation/context'

module Repo
  module Drift
    module Detector
      class PromptBuilder
        INTRO = 'Explain repository risk based on these deterministic signals from a repository drift analysis.'
        CONSTRAINT = 'Do not invent architecture, intent, or risks beyond the signals below.'

        SIGNAL_LABELS = {
          risk_level: 'Risk level',
          risk_score: 'Risk score',
          changed_file_count: 'Changed file count',
          production_file_count: 'Production file count',
          test_file_count: 'Test file count',
          documentation_file_count: 'Documentation file count',
          unsafe_change_ratio: 'Unsafe change ratio',
          high_risk_file_count: 'High risk file count',
          large_change_count: 'Large change count'
        }.freeze

        PATTERN_LABELS = {
          tests_present: 'Tests present',
          documentation_updated: 'Documentation updated',
          production_only_change: 'Production-only change'
        }.freeze

        def initialize(context)
          @context = context.is_a?(ExplanationContext) ? context.to_h : normalize_context(context)
        end

        def build
          [
            INTRO,
            CONSTRAINT,
            '',
            'Signals:',
            *signal_lines,
            '',
            'Repository patterns:',
            *pattern_lines
          ].join("\n")
        end

        private

        attr_reader :context

        def signal_lines
          ExplanationContext::SIGNAL_KEYS.map do |key|
            label = SIGNAL_LABELS.fetch(key)
            "- #{label}: #{format_value(context.fetch(key))}"
          end
        end

        def pattern_lines
          PATTERN_LABELS.map do |key, label|
            "- #{label}: #{format_value(context.fetch(:repository_patterns).fetch(key))}"
          end
        end

        def format_value(value)
          return 'true' if value == true
          return 'false' if value == false

          value.to_s
        end

        def normalize_context(data)
          data.transform_keys(&:to_sym).tap do |normalized|
            normalized[:repository_patterns] = normalized[:repository_patterns].transform_keys(&:to_sym)
          end
        end
      end
    end
  end
end
