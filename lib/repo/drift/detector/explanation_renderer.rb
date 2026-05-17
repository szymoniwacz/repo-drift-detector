# frozen_string_literal: true

require 'repo/drift/detector/explanation_context'

module Repo
  module Drift
    module Detector
      class ExplanationRenderer
        DEFAULT_UNSAFE_RATIO_THRESHOLD = 3.0

        OPENING_LINES = {
          'low' => 'Repository risk is low based on the current deterministic file-change signals.',
          'medium' => 'Repository risk is moderate based on the current deterministic file-change signals.',
          'high' => 'Repository risk is elevated based on the current deterministic file-change signals.'
        }.freeze

        REVIEW_GUIDANCE = [
          'Review attention should focus on:',
          '- multi-file consistency',
          '- architecture coherence',
          '- unintended repository drift'
        ].join("\n")

        def initialize(context)
          @context = context.is_a?(ExplanationContext) ? context.to_h : normalize_context(context)
        end

        def render
          sections = [opening_line, *risk_factor_lines]
          sections << REVIEW_GUIDANCE if show_review_guidance?
          sections.join("\n\n")
        end

        private

        attr_reader :context

        def opening_line
          OPENING_LINES.fetch(risk_level) { OPENING_LINES.fetch('medium') }
        end

        def risk_factor_lines
          [
            production_coverage_line,
            unsafe_ratio_line,
            high_risk_files_line,
            large_changes_line,
            accumulation_line
          ].compact
        end

        def production_coverage_line
          if patterns[:production_only_change]
            return 'Production-focused changes were introduced without corresponding tests or documentation updates.'
          end

          return nil unless production_file_count.positive?

          unless patterns[:tests_present]
            return 'Production file changes are present without corresponding test file changes.'
          end

          return if patterns[:documentation_updated]

          'Production file changes are present without corresponding documentation updates.'
        end

        def unsafe_ratio_line
          return unless unsafe_change_ratio >= DEFAULT_UNSAFE_RATIO_THRESHOLD

          "The unsafe change ratio reached: #{format_ratio(unsafe_change_ratio)}."
        end

        def high_risk_files_line
          return unless high_risk_file_count.positive?

          count_label = high_risk_file_count == 1 ? 'file changed' : 'files changed'
          "#{high_risk_file_count} high-risk #{count_label} in this diff."
        end

        def large_changes_line
          return unless large_change_count.positive?

          count_label = large_change_count == 1 ? 'file exceeds' : 'files exceed'
          "#{large_change_count} #{count_label} the large-change threshold."
        end

        def accumulation_line
          return unless risk_level == 'high' && risk_factor_lines_for_accumulation.size > 1

          'Multiple observable risk signals are present together in this change set.'
        end

        def risk_factor_lines_for_accumulation
          [production_coverage_line, unsafe_ratio_line, high_risk_files_line, large_changes_line].compact
        end

        def show_review_guidance?
          %w[medium high].include?(risk_level)
        end

        def risk_level
          context.fetch(:risk_level).to_s
        end

        def production_file_count
          context.fetch(:production_file_count, 0)
        end

        def unsafe_change_ratio
          context.fetch(:unsafe_change_ratio, 0.0).to_f
        end

        def high_risk_file_count
          context.fetch(:high_risk_file_count, 0)
        end

        def large_change_count
          context.fetch(:large_change_count, 0)
        end

        def patterns
          context.fetch(:repository_patterns)
        end

        def format_ratio(value)
          format('%.1f', value.to_f)
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
