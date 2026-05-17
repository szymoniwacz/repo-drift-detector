# frozen_string_literal: true

require 'repo/drift/detector/analyzer'
require 'repo/drift/detector/config'
require 'repo/drift/detector/git_diff_error'
require 'repo/drift/detector/renderers/text_renderer'
require 'repo/drift/detector/renderers/json_renderer'
require_relative 'analysis_summary'
require_relative 'analyze/argument_validator'

module Repo
  module Drift
    module Detector
      module Commands
        class Analyze
          FAIL_ON_LEVELS = {
            'low' => 0,
            'medium' => 1,
            'high' => 2
          }.freeze

          def initialize(argv)
            @argv = argv
          end

          def call
            ArgumentValidator.new(argv).validate
            load_config!

            deliver_output(render_analysis_content)
            handle_fail_on
          rescue GitDiffError => e
            abort_git_diff_error(e)
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

          def json?
            option_value('--format') == 'json'
          end

          def render_analysis_content
            if json?
              Renderers::JsonRenderer.new.render(summary)
            else
              Renderers::TextRenderer.new.render(analyzer: analyzer, goal: goal, base: base)
            end
          end

          def abort_git_diff_error(error)
            warn error.message
            exit 2
          end

          def summary
            analysis_summary.to_h
          end

          def analysis_summary
            @analysis_summary ||= AnalysisSummary.new(analyzer: analyzer, goal: goal, base: base)
          end

          def handle_fail_on
            return unless fail_on

            current_level = FAIL_ON_LEVELS[analyzer.risk_level.to_s]
            exit 1 if current_level >= FAIL_ON_LEVELS[fail_on]
          end

          def fail_on
            option_value('--fail-on')
          end

          def output_path
            option_value('--output')
          end

          def deliver_output(content)
            path = output_path
            if path
              write_output_file(content, path)
              puts "Analysis written to #{path}"
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
