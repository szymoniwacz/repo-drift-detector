# frozen_string_literal: true

require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'
require 'repo/drift/detector/interpreters/explanation_interpreter'

module Repo
  module Drift
    module Detector
      class StaticAiInterpreter < ExplanationInterpreter
        SIGNAL_BRIEF_LABEL = 'Signal brief:'

        def interpret(context, signal_brief: true)
          ctx = normalize_context(context)
          sections = [assessment_line(ctx), coverage_note(ctx)]
          sections << signal_brief_section(ctx) if signal_brief

          sections.compact.join("\n\n")
        end

        def signal_brief_section(ctx)
          "#{SIGNAL_BRIEF_LABEL}\n#{PromptBuilder.new(ctx).build}"
        end

        private

        def assessment_line(ctx)
          level = ctx.fetch(:risk_level).to_s
          score = ctx.fetch(:risk_score)
          changed = ctx.fetch(:changed_file_count)

          "Assessed repository drift risk as #{level} with a risk score of #{score} " \
            "across #{changed} changed file(s), using only the provided file-change signals."
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
