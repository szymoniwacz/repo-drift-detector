# frozen_string_literal: true

require 'repo/drift/detector/analyzer'
require 'repo/drift/detector/config'
require 'repo/drift/detector/deterministic_interpreter'
require 'repo/drift/detector/explanation_comparison'
require 'repo/drift/detector/explanation_context'
require 'repo/drift/detector/static_ai_interpreter'
require_relative 'analysis_summary'
require_relative 'explain/argument_validator'
require_relative 'explain/content_renderer'

module Repo
  module Drift
    module Detector
      module Commands
        class Explain
          DEFAULT_INTERPRETER = 'deterministic'

          INTERPRETERS = {
            'deterministic' => DeterministicInterpreter,
            'static-ai' => StaticAiInterpreter
          }.freeze

          def initialize(argv)
            @argv = argv
          end

          def call
            ArgumentValidator.new(argv).validate
            load_config!

            deliver_output(render_content)
          end

          private

          attr_reader :argv

          def goal
            option_value('--goal')
          end

          def base
            option_value('--base')
          end

          def analyzer
            @analyzer ||= Analyzer.new(base: base, config: load_config!)
          end

          def load_config!
            @load_config ||= Config.load
          rescue ConfigError => e
            warn e.message
            exit 2
          end

          def option_value(name)
            index = argv.index(name)
            argv[index + 1] if index
          end

          def compare?
            argv.include?('--compare')
          end

          def json?
            option_value('--format') == 'json'
          end

          def markdown?
            option_value('--format') == 'markdown'
          end

          def render_content
            ContentRenderer.new(self).render
          end

          def report_payload
            return analysis_summary.merge(comparison: comparison_data) if compare?

            analysis_summary.merge(
              interpreter: interpreter_name,
              explanation: explanation_text
            )
          end

          def comparison_data
            @comparison_data ||= ExplanationComparison.build(explanation_context)
          end

          def analysis_summary
            @analysis_summary ||= AnalysisSummary.new(analyzer: analyzer, goal: goal, base: base).to_h
          end

          def explanation_text
            @explanation_text ||= explanation_interpreter.interpret(explanation_context)
          end

          def interpreter_name
            @interpreter_name ||= option_value('--interpreter') || DEFAULT_INTERPRETER
          end

          def explanation_interpreter
            @explanation_interpreter ||= interpreter_for(interpreter_name)
          end

          def interpreter_for(name)
            INTERPRETERS.fetch(name).new
          end

          def explanation_context
            @explanation_context ||= ExplanationContext.new(analysis_summary.fetch(:summary))
          end

          def output_path
            option_value('--output')
          end

          def deliver_output(content)
            path = output_path
            if path
              write_output_file(content, path)
              puts "Explanation written to #{path}"
            else
              puts content
            end
          end

          def write_output_file(content, path)
            File.write(path, content)
          rescue SystemCallError => e
            warn "Cannot write output to #{path}: #{e.message}"
            exit 2
          end
        end
      end
    end
  end
end
