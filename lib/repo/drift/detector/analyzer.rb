# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class Analyzer
        def initialize(base:)
          @base = base
        end

        def changed_files
          `git diff --name-only #{@base}`.split("\n")
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
          `git diff --numstat #{@base}`.split("\n").map do |line|
            added, removed, file = line.split("\t")

            {
              file: file,
              added: added.to_i,
              removed: removed.to_i,
              total_changes: added.to_i + removed.to_i
            }
          end
        end

        def large_change_files(threshold: 20)
          changed_file_stats.select do |stat|
            stat[:total_changes] >= threshold
          end
        end

        def risk_level
          total_changes = changed_file_stats.sum { |stat| stat[:total_changes] }
          ratio = unsafe_change_ratio
          has_high_risk = !high_risk_files.empty?

          # High risk conditions
          return :high if total_changes > 100
          return :high if ratio >= 3.0

          # Medium risk conditions
          return :medium if total_changes > 20
          return :medium if has_high_risk

          :low
        end

        def high_risk_files
          production_files.select do |file|
            file.include?('cli') ||
              file.include?('commands') ||
              file.include?('analyzer')
          end
        end
      end
    end
  end
end
