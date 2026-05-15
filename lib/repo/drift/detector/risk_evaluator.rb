# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class RiskEvaluator
        def initialize(signals)
          @signals = signals
        end

        def risk_level
          assessment[:level]
        end

        def risk_reasons
          assessment[:reasons]
        end

        private

        attr_reader :signals

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
          [].tap do |tokens|
            tokens << 'total_changes_above_100' if total_changes > 100
            tokens << 'unsafe_change_ratio_above_threshold' if ratio >= 3.0
            tokens << 'total_changes_above_20' if total_changes > 20
            tokens << 'high_risk_files_detected' if has_high_risk
          end
        end

        def risk_tier(total_changes, ratio, has_high_risk)
          return :high if total_changes > 100 || ratio >= 3.0
          return :medium if total_changes > 20 || has_high_risk

          :low
        end
      end
    end
  end
end
