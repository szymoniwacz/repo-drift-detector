# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class ExplanationContext
        SIGNAL_KEYS = %i[
          risk_level
          risk_score
          changed_file_count
          production_file_count
          test_file_count
          documentation_file_count
          unsafe_change_ratio
          high_risk_file_count
          large_change_count
        ].freeze

        def initialize(summary_data)
          @summary_data = normalize_keys(summary_data)
        end

        def to_h
          signal_fields.merge(repository_patterns: repository_patterns)
        end

        private

        attr_reader :summary_data

        def signal_fields
          SIGNAL_KEYS.to_h { |key| [key, signal_value(key)] }
        end

        def signal_value(key)
          value = summary_data[key]
          key == :risk_level ? value.to_s : value
        end

        def repository_patterns
          {
            tests_present: test_file_count.positive?,
            documentation_updated: documentation_file_count.positive?,
            production_only_change: production_only_change?
          }
        end

        def production_only_change?
          production_file_count.positive? &&
            test_file_count.zero? &&
            documentation_file_count.zero?
        end

        def production_file_count
          summary_data.fetch(:production_file_count, 0)
        end

        def test_file_count
          summary_data.fetch(:test_file_count, 0)
        end

        def documentation_file_count
          summary_data.fetch(:documentation_file_count, 0)
        end

        def normalize_keys(data)
          data.transform_keys(&:to_sym)
        end
      end
    end
  end
end
