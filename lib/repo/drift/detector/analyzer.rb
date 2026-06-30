# frozen_string_literal: true

require_relative 'git_diff'
require_relative 'risk_evaluator'
require_relative 'config'
require_relative 'line_finding_extractor'

module Repo
  module Drift
    module Detector
      class Analyzer
        def initialize(base:, config: nil)
          @base = base
          @config_override = config
        end

        def changed_files
          git_diff.changed_file_names.split("\n").reject(&:empty?)
        end

        def changed_file_count
          changed_files.count
        end

        def documentation_files
          changed_files.select do |file|
            file == 'README.md' ||
              file.start_with?('docs/') ||
              file.end_with?('.md')
          end
        end

        def test_files
          changed_files.select do |file|
            file.start_with?('spec/') ||
              file.include?('/spec/') ||
              file.start_with?('test/') ||
              file.end_with?('_spec.rb')
          end
        end

        def production_files
          changed_files - documentation_files - test_files
        end

        def unsafe_change_ratio
          prod_count = production_files.count
          return 0.0 if prod_count.zero?

          test_count = test_files.count
          prod_count.to_f / [test_count, 1].max
        end

        def changed_file_stats
          git_diff.numstat_lines.split("\n").filter_map do |line|
            added, removed, file = line.split("\t", 3)
            next if file.nil?

            {
              file: file,
              added: added.to_i,
              removed: removed.to_i,
              total_changes: added.to_i + removed.to_i
            }
          end
        end

        def line_findings
          @line_findings ||= LineFindingExtractor.new(
            diff: git_diff.unified_diff,
            production_files: production_files
          ).call
        end

        def large_change_files(threshold: 20)
          changed_file_stats.select do |stat|
            stat[:total_changes] >= threshold
          end
        end

        def risk_level
          risk_evaluator.risk_level
        end

        def risk_reasons
          risk_evaluator.risk_reasons
        end

        def risk_score
          risk_evaluator.risk_score
        end

        def high_risk_files
          production_files.select do |file|
            file.include?('cli') ||
              file.include?('commands') ||
              file.include?('analyzer')
          end
        end

        private

        def git_diff
          @git_diff ||= GitDiff.new(base: @base)
        end

        def resolved_config
          @resolved_config ||= @config_override || Config.load
        end

        def risk_evaluator
          @risk_evaluator ||= RiskEvaluator.new(self, resolved_config)
        end
      end
    end
  end
end
