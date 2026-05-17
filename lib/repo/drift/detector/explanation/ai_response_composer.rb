# frozen_string_literal: true

require 'repo/drift/detector/explanation/context'

module Repo
  module Drift
    module Detector
      class AiResponseComposer
        UNSAFE_RATIO_THRESHOLD = 3.0

        def initialize(context)
          @context = normalize_context(context)
        end

        def compose(include_signal_insights: true)
          sections = [assessment_line, coverage_note]
          sections << interpretive_signal_insights if include_signal_insights

          sections.compact.join("\n\n")
        end

        private

        attr_reader :context

        def interpretive_signal_insights
          [
            risk_profile_insight,
            change_scope_insight,
            unsafe_ratio_insight,
            high_risk_files_insight,
            large_changes_insight
          ].compact.join("\n\n")
        end

        def assessment_line
          level = context.fetch(:risk_level).to_s
          score = context.fetch(:risk_score)
          changed = context.fetch(:changed_file_count)

          "Assessed repository drift risk as #{level} with a risk score of #{score} " \
            "across #{changed} changed file(s), using only the provided file-change signals."
        end

        def risk_profile_insight
          level = context.fetch(:risk_level).to_s
          score = context.fetch(:risk_score)
          "Taken together, the signals point to #{level} repository drift risk with a score of #{score}."
        end

        def change_scope_insight
          count = context.fetch(:changed_file_count)
          production = context.fetch(:production_file_count)
          test = context.fetch(:test_file_count)
          documentation = context.fetch(:documentation_file_count)

          "The diff touches #{count} file(s): #{production} production, #{test} test, " \
            "and #{documentation} documentation file(s)."
        end

        def unsafe_ratio_insight
          ratio = context.fetch(:unsafe_change_ratio).to_f
          return unless ratio >= UNSAFE_RATIO_THRESHOLD

          formatted = format('%.1f', ratio)
          "The unsafe change ratio of #{formatted} suggests production-heavy change relative to " \
            'test coverage in this diff.'
        end

        def high_risk_files_insight
          count = context.fetch(:high_risk_file_count)
          return unless count.positive?

          label = count == 1 ? 'file' : 'files'
          "#{count} high-risk #{label} in the change set may amplify review and drift risk."
        end

        def large_changes_insight
          count = context.fetch(:large_change_count)
          return unless count.positive?

          label = count == 1 ? 'file exceeds' : 'files exceed'
          "#{count} #{label} the large-change threshold, indicating concentrated churn."
        end

        def coverage_note
          return production_only_coverage_note if context.fetch(:repository_patterns)[:production_only_change]

          notes = production_coverage_notes
          notes.empty? ? nil : notes.join(' ')
        end

        def production_only_coverage_note
          'Production file changes are present without corresponding test or documentation file changes.'
        end

        def production_coverage_notes
          patterns = context.fetch(:repository_patterns)
          return [] unless context.fetch(:production_file_count).positive?

          [].tap do |notes|
            notes << missing_test_coverage_note unless patterns[:tests_present]
            notes << missing_documentation_coverage_note unless patterns[:documentation_updated]
          end
        end

        def missing_test_coverage_note
          'Production file changes are present without corresponding test file changes.'
        end

        def missing_documentation_coverage_note
          'Production file changes are present without corresponding documentation file changes.'
        end

        def normalize_context(data)
          return data.to_h if data.is_a?(ExplanationContext)

          normalized = data.transform_keys(&:to_sym)
          return normalize_patterns(normalized) if normalized.key?(:repository_patterns)

          ExplanationContext.new(normalized).to_h
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
