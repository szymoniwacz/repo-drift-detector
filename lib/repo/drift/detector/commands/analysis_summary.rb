# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      module Commands
        class AnalysisSummary
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

          def initialize(analyzer:, goal:, base:)
            @analyzer = analyzer
            @goal = goal
            @base = base
          end

          def to_h
            payload = summary_metrics.merge(goal: goal, base: base)
            payload.merge(summary: machine_readable_summary(payload))
          end

          private

          attr_reader :analyzer, :goal, :base

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
        end
      end
    end
  end
end
