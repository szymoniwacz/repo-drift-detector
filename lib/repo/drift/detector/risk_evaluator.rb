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
          has_high_risk = !signals.high_risk_files.empty?

          {
            level: risk_tier(total_changes, ratio, has_high_risk),
            reasons: risk_reason_tokens(total_changes, ratio, has_high_risk)
          }
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
