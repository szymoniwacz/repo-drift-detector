# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class RiskEvaluator
        def initialize(signals, config)
          @signals = signals
          @config = config
        end

        def risk_level
          assessment[:level]
        end

        def risk_score
          assessment[:score]
        end

        def risk_reasons
          assessment[:reasons]
        end

        private

        attr_reader :signals, :config

        def assessment
          @assessment ||= build_assessment
        end

        def build_assessment
          total_changes = signals.changed_file_stats.sum { |stat| stat[:total_changes] }
          ratio = signals.unsafe_change_ratio
          high_risk_count = signals.high_risk_files.count
          large_change_count = large_change_count_from(signals)
          has_high_risk = high_risk_count.positive?

          {
            level: risk_tier(total_changes, ratio, has_high_risk),
            score: risk_score_value(total_changes, ratio, high_risk_count, large_change_count),
            reasons: risk_reason_tokens(total_changes, ratio, has_high_risk)
          }
        end

        def large_change_count_from(signals)
          if signals.respond_to?(:large_change_files)
            signals.large_change_files.count
          else
            signals.changed_file_stats.count { |stat| stat[:total_changes] >= 20 }
          end
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

        def risk_score_value(total_changes, ratio, high_risk_count, large_change_count)
          score = 0
          score += score_from_total_changes(total_changes)
          score += score_from_unsafe_change_ratio(ratio)
          score += score_from_high_risk_files(high_risk_count)
          score += score_from_large_change_count(large_change_count)
          [score, 100].min
        end

        def score_from_total_changes(total_changes)
          max_points = 40
          threshold = config.high_change_threshold.to_f
          return 0 if threshold.zero?

          [((total_changes / threshold) * max_points).to_i, max_points].min
        end

        def score_from_unsafe_change_ratio(ratio)
          max_points = 25
          threshold = config.unsafe_change_ratio_threshold.to_f
          return 0 if threshold.zero?

          [((ratio / threshold) * max_points).to_i, max_points].min
        end

        def score_from_high_risk_files(count)
          [count * 10, 20].min
        end

        def score_from_large_change_count(count)
          [count * 8, 15].min
        end
      end
    end
  end
end
