# frozen_string_literal: true

require 'repo/drift/detector/explanation/comparison'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/interpreters/ai_interpreter'
require 'repo/drift/detector/interpreters/deterministic_interpreter'
require 'repo/drift/detector/interpreters/static_ai_interpreter'
require 'repo/drift/detector/renderers/comparison_markdown_renderer'
require 'repo/drift/detector/renderers/comparison_text_renderer'
require 'repo/drift/detector/renderers/explanation_markdown_renderer'
require 'repo/drift/detector/renderers/json_renderer'
require_relative 'analysis_summary'

module Repo
  module Drift
    module Detector
      module Commands
        class ExplainRunner
          DEFAULT_INTERPRETER = 'deterministic'

          INTERPRETERS = {
            'deterministic' => Interpreters::DeterministicInterpreter,
            'static-ai' => Interpreters::StaticAiInterpreter,
            'ai' => Interpreters::AiInterpreter
          }.freeze

          def initialize(analyzer:, goal:, base:, **options)
            @analyzer = analyzer
            @goal = goal
            @base = base
            @compare = options.fetch(:compare, false)
            @format = options[:format]
            @interpreter = options[:interpreter]
          end

          def render
            return render_compare_output if compare?
            return json_renderer.render(report_payload) if json?
            return render_single_markdown if markdown?

            explanation_text
          end

          def report_payload
            return analysis_summary.merge(comparison: comparison_data) if compare?

            analysis_summary.merge(
              interpreter: interpreter_name,
              explanation: explanation_text
            )
          end

          private

          attr_reader :analyzer, :goal, :base, :compare, :format, :interpreter

          def compare?
            compare
          end

          def json?
            format == 'json'
          end

          def markdown?
            format == 'markdown'
          end

          def interpreter_name
            @interpreter_name ||= interpreter || DEFAULT_INTERPRETER
          end

          def render_compare_output
            data = comparison_data
            return json_renderer.render(report_payload) if json?
            return Renderers::ComparisonMarkdownRenderer.new.render(data) if markdown?

            Renderers::ComparisonTextRenderer.new.render(data)
          end

          def render_single_markdown
            Renderers::ExplanationMarkdownRenderer.new.render(
              interpreter_name: interpreter_name,
              explanation: explanation_text
            )
          end

          def comparison_data
            @comparison_data ||= ExplanationComparison.build(explanation_context)
          end

          def analysis_summary
            @analysis_summary ||= AnalysisSummary.new(
              analyzer: analyzer,
              goal: goal,
              base: base
            ).to_h
          end

          def explanation_context
            @explanation_context ||= ExplanationContext.new(analysis_summary.fetch(:summary))
          end

          def explanation_text
            @explanation_text ||= explanation_interpreter.interpret(explanation_context)
          end

          def explanation_interpreter
            @explanation_interpreter ||= INTERPRETERS.fetch(interpreter_name).new
          end

          def json_renderer
            @json_renderer ||= Renderers::JsonRenderer.new
          end
        end
      end
    end
  end
end
