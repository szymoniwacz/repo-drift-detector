# frozen_string_literal: true

require 'repo/drift/detector/analyzer'

require 'json'

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
            risk_level: :risk_level
          }.freeze

          def initialize(argv)
            @argv = argv
          end

          def call
            if json?
              puts JSON.generate(summary)
            else
              puts 'Analyzing repository drift...'
              puts "Goal: #{goal}"
              puts "Base: #{base}"
              print_analysis
            end
          end

          private

          attr_reader :argv

          def print_analysis
            print_changed_file_count
            print_changed_files
            print_change_stats
            print_large_change_files
            print_documentation_files
            print_test_files
            print_production_files
            print_unsafe_change_ratio
            print_high_risk_files
            print_risk_level
          end

          def goal
            option_value('--goal')
          end

          def base
            option_value('--base')
          end

          def analyzer
            @analyzer ||= Analyzer.new(base: base)
          end

          def option_value(name)
            index = argv.index(name)
            argv[index + 1] if index
          end

          def print_changed_file_count
            puts
            puts "Changed file count: #{analyzer.changed_file_count}"
          end

          def print_changed_files
            puts
            puts 'Changed files:'
            analyzer.changed_files.each { |file| puts "- #{file}" }
          end

          def print_change_stats
            puts
            puts 'Change stats:'
            analyzer.changed_file_stats.each do |stat|
              puts "- #{stat[:file]} (+#{stat[:added]}/-#{stat[:removed]}) total=#{stat[:total_changes]}"
            end
          end

          def print_large_change_files
            files = analyzer.large_change_files

            puts
            puts 'Large changes:'
            if files.empty?
              puts '- none'
            else
              files.each do |stat|
                puts "- #{stat[:file]} total=#{stat[:total_changes]}"
              end
            end
          end

          def print_documentation_files
            files = analyzer.documentation_files

            puts
            puts 'Documentation files:'
            if files.empty?
              puts '- none'
            else
              files.each { |file| puts "- #{file}" }
            end
          end

          def print_test_files
            files = analyzer.test_files

            puts
            puts 'Test files:'
            if files.empty?
              puts '- none'
            else
              files.each { |file| puts "- #{file}" }
            end
          end

          def print_production_files
            files = analyzer.production_files

            puts
            puts 'Production files:'
            if files.empty?
              puts '- none'
            else
              files.each { |file| puts "- #{file}" }
            end
          end

          def print_unsafe_change_ratio
            puts
            puts "Unsafe change ratio: #{format('%.1f', analyzer.unsafe_change_ratio)}"
          end

          def print_risk_level
            puts
            puts "Risk level: #{analyzer.risk_level}"
          end

          def print_high_risk_files
            files = analyzer.high_risk_files

            puts
            puts 'High risk files:'
            if files.empty?
              puts '- none'
            else
              files.each { |file| puts "- #{file}" }
            end
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
        end
      end
    end
  end
end
