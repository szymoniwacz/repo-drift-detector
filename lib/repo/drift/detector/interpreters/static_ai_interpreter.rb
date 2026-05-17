# frozen_string_literal: true

require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'
require 'repo/drift/detector/interpreters/explanation_interpreter'

module Repo
  module Drift
    module Detector
      class StaticAiInterpreter < ExplanationInterpreter
        UNSAFE_RATIO_THRESHOLD = 3.0

        def interpret(context, signal_brief: true)
          ctx = normalize_context(context)
          build_internal_prompt(ctx)

          sections = [assessment_line(ctx), coverage_note(ctx)]
          sections << interpretive_signal_insights(ctx) if signal_brief

          sections.compact.join("\n\n")
        end

        private

        def build_internal_prompt(ctx)
          PromptBuilder.new(ctx).build
        end

        def interpretive_signal_insights(ctx)
          [
            risk_profile_insight(ctx),
            change_scope_insight(ctx),
            unsafe_ratio_insight(ctx),
            high_risk_files_insight(ctx),
            large_changes_insight(ctx)
          ].compact.join("\n\n")
        end

        def assessment_line(ctx)
          level = ctx.fetch(:risk_level).to_s
          score = ctx.fetch(:risk_score)
          changed = ctx.fetch(:changed_file_count)

          "Assessed repository drift risk as #{level} with a risk score of #{score} " \
            "across #{changed} changed file(s), using only the provided file-change signals."
        end

        def risk_profile_insight(ctx)
          level = ctx.fetch(:risk_level).to_s
          score = ctx.fetch(:risk_score)
          "Taken together, the signals point to #{level} repository drift risk with a score of #{score}."
        end

        def change_scope_insight(ctx)
          count = ctx.fetch(:changed_file_count)
          production = ctx.fetch(:production_file_count)
          test = ctx.fetch(:test_file_count)
          documentation = ctx.fetch(:documentation_file_count)

          "The diff touches #{count} file(s): #{production} production, #{test} test, " \
            "and #{documentation} documentation file(s)."
        end

        def unsafe_ratio_insight(ctx)
          ratio = ctx.fetch(:unsafe_change_ratio).to_f
          return unless ratio >= UNSAFE_RATIO_THRESHOLD

          formatted = format('%.1f', ratio)
          "The unsafe change ratio of #{formatted} suggests production-heavy change relative to " \
            'test coverage in this diff.'
        end

        def high_risk_files_insight(ctx)
          count = ctx.fetch(:high_risk_file_count)
          return unless count.positive?

          label = count == 1 ? 'file' : 'files'
          "#{count} high-risk #{label} in the change set may amplify review and drift risk."
        end

        def large_changes_insight(ctx)
          count = ctx.fetch(:large_change_count)
          return unless count.positive?

          label = count == 1 ? 'file exceeds' : 'files exceed'
          "#{count} #{label} the large-change threshold, indicating concentrated churn."
        end

        def coverage_note(ctx)
          return production_only_coverage_note if ctx.fetch(:repository_patterns)[:production_only_change]

          notes = production_coverage_notes(ctx)
          notes.empty? ? nil : notes.join(' ')
        end

        def production_only_coverage_note
          'Production file changes are present without corresponding test or documentation file changes.'
        end

        def production_coverage_notes(ctx)
          patterns = ctx.fetch(:repository_patterns)
          return [] unless ctx.fetch(:production_file_count).positive?

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
