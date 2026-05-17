# frozen_string_literal: true

require 'repo/drift/detector/analyzer'
require 'repo/drift/detector/config'
require 'repo/drift/detector/renderers/text_renderer'
require 'repo/drift/detector/renderers/json_renderer'
require_relative 'analyze/argument_validator'

module Repo
  module Drift
    module Detector
      module Commands
        class Analyze
          SUMMARY_METRIC_METHODS = {
            changed_file_count: :changed_file_count,
            changed_files: :changed_files,
            change_stats: :changed_file_stats,
            large_changes: :large_change_files,
            documentation_files: :documentation_files,
            test_files: :test_files,
            production_files: :production_files,
            unsafe_change_ratio: :unsafe_change_ratio,
            high_risk_files: :high_risk_files,
            risk_level: :risk_level,
            risk_reasons: :risk_reasons,
            risk_score: :risk_score
          }.freeze

          SUMMARY_COUNT_FIELDS = {
            production_file_count: :production_files,
            test_file_count: :test_files,
            documentation_file_count: :documentation_files,
            high_risk_file_count: :high_risk_files
          }.freeze

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

            content = if json?
                        Renderers::JsonRenderer.new.render(summary)
                      else
                        Renderers::TextRenderer.new.render(analyzer: analyzer, goal: goal, base: base)
                      end

            deliver_output(content)

            handle_fail_on
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

          def summary
            payload = summary_metrics.merge(goal: goal, base: base)
            payload.merge(summary: machine_readable_summary(payload))
          end

          def summary_metrics
            SUMMARY_METRIC_METHODS.transform_values { |method_name| analyzer.public_send(method_name) }
          end

          def machine_readable_summary(payload)
            {
              risk_level: payload[:risk_level],
              risk_score: payload[:risk_score],
              changed_file_count: payload[:changed_file_count],
              unsafe_change_ratio: payload[:unsafe_change_ratio],
              large_change_count: array_metric_size(payload, :large_changes, :large_change_files)
            }.merge(SUMMARY_COUNT_FIELDS.transform_values { |key| array_metric_size(payload, key) })
          end

          def array_metric_size(payload, *keys)
            key = keys.find { |name| payload.key?(name) }
            Array(payload[key]).size
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
