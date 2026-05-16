# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class RiskEvaluator
        LINES_SCORE_MAX = 40
        RATIO_SCORE_MAX = 25
        HIGH_RISK_FILES_SCORE_MAX = 20
        LARGE_CHANGES_SCORE_MAX = 15
        SCORE_CAP = 100

        HIGH_RISK_FILES_SCORE_DENOMINATOR = 4
        LARGE_CHANGES_SCORE_DENOMINATOR = 3

        def initialize(signals, config)
          @signals = signals
          @config = config
        end

        def risk_level
          assessment[:level]
        end

        def risk_reasons
          assessment[:reasons]
        end

        def risk_score
          assessment[:score]
        end

        private

        attr_reader :signals, :config

        def assessment
          @assessment ||= build_assessment
        end

        def build_assessment
          inputs = assessment_inputs

          {
            level: risk_tier(inputs[:total_changes], inputs[:ratio], inputs[:has_high_risk]),
            reasons: risk_reason_tokens(inputs[:total_changes], inputs[:ratio], inputs[:has_high_risk]),
            score: compute_risk_score(inputs)
          }
        end

        def assessment_inputs
          total_changes = signals.changed_file_stats.sum { |stat| stat[:total_changes] }
          {
            total_changes: total_changes,
            ratio: signals.unsafe_change_ratio,
            has_high_risk: !signals.high_risk_files.empty?,
            high_risk_count: signals.high_risk_files.size,
            large_change_count: signals.large_change_files.size
          }
        end

        def compute_risk_score(inputs)
          score = scaled_points(inputs[:total_changes], config.high_change_threshold, LINES_SCORE_MAX) +
                  scaled_points(inputs[:ratio], config.unsafe_change_ratio_threshold, RATIO_SCORE_MAX) +
                  scaled_points(inputs[:high_risk_count], HIGH_RISK_FILES_SCORE_DENOMINATOR,
                                HIGH_RISK_FILES_SCORE_MAX) +
                  scaled_points(inputs[:large_change_count], LARGE_CHANGES_SCORE_DENOMINATOR,
                                LARGE_CHANGES_SCORE_MAX)

          [score, SCORE_CAP].min
        end

        def scaled_points(value, scale_to, max_points)
          return 0 if scale_to <= 0 || value <= 0

          [(value.to_f / scale_to * max_points).floor, max_points].min
        end

        def risk_reason_tokens(total_changes, ratio, has_high_risk)
          h = config.high_change_threshold
          m = config.medium_change_threshold
          r = config.unsafe_change_ratio_threshold

          [].tap do |tokens|
            tokens << "total_changes_above_#{h}" if total_changes > h
            tokens << 'unsafe_change_ratio_above_threshold' if ratio >= r
            tokens << "total_changes_above_#{m}" if total_changes > m
            tokens << 'high_risk_files_detected' if has_high_risk
          end
        end

        def risk_tier(total_changes, ratio, has_high_risk)
          h = config.high_change_threshold
          m = config.medium_change_threshold
          r = config.unsafe_change_ratio_threshold

          return :high if total_changes > h || ratio >= r
          return :medium if total_changes > m || has_high_risk

          :low
        end
      end
    end
  end
end
