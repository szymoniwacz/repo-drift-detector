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

          case total_changes
          when 0..20
            :low
          when 21..100
            :medium
          else
            :high
          end
        end

        def high_risk_files
          changed_files.select do |file|
            file.include?('cli') ||
              file.include?('commands') ||
              file.include?('analyzer')
          end
        end
      end
    end
  end
end
