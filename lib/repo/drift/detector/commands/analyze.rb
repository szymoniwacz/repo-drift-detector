# frozen_string_literal: true

require 'repo/drift/detector/analyzer'
require 'repo/drift/detector/config'
require 'repo/drift/detector/renderers/text_renderer'
require 'repo/drift/detector/renderers/json_renderer'

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
            risk_reasons: :risk_reasons
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
            validate_fail_on
            load_config!

            if json?
              Renderers::JsonRenderer.new.render(summary)
            else
              Renderers::TextRenderer.new.render(analyzer: analyzer, goal: goal, base: base)
            end

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
            summary_metrics.merge(goal: goal, base: base)
          end

          def summary_metrics
            SUMMARY_METRIC_METHODS.transform_values { |method_name| analyzer.public_send(method_name) }
          end

          def handle_fail_on
            return unless fail_on

            current_level = FAIL_ON_LEVELS[analyzer.risk_level.to_s]
            exit 1 if current_level >= FAIL_ON_LEVELS[fail_on]
          end

          def validate_fail_on
            return unless fail_on
            return if FAIL_ON_LEVELS.key?(fail_on)

            warn "Invalid --fail-on value '#{fail_on}'. Valid values are: #{FAIL_ON_LEVELS.keys.join(', ')}."
            exit 2
          end

          def fail_on
            option_value('--fail-on')
          end
        end
      end
    end
  end
end
