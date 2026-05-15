# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      module Renderers
        class TextRenderer
          def render(analyzer:, goal:, base:)
            @analyzer = analyzer
            puts 'Analyzing repository drift...'
            puts "Goal: #{goal}"
            puts "Base: #{base}"
            print_analysis
          ensure
            @analyzer = nil
          end

          private

          attr_reader :analyzer

          def print_analysis
            print_changed_file_count
            print_changed_files
            print_change_stats
            print_large_change_files
            print_hyphen_list_section('Documentation files', analyzer.documentation_files)
            print_hyphen_list_section('Test files', analyzer.test_files)
            print_hyphen_list_section('Production files', analyzer.production_files)
            print_unsafe_change_ratio
            print_risk_summary
          end

          def print_risk_summary
            print_hyphen_list_section('High risk files', analyzer.high_risk_files)
            print_risk_level
            print_hyphen_list_section('Risk reasons', risk_reason_lines)
          end

          def risk_reason_lines
            reasons = analyzer.risk_reasons
            return ['none'] if reasons.empty?

            reasons
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
            lines = analyzer.large_change_files.map do |stat|
              "#{stat[:file]} total=#{stat[:total_changes]}"
            end
            print_hyphen_list_section('Large changes', lines)
          end

          def print_hyphen_list_section(title, elements)
            PrintHyphenList.call(title, elements)
          end

          def print_unsafe_change_ratio
            puts
            puts "Unsafe change ratio: #{format('%.1f', analyzer.unsafe_change_ratio)}"
          end

          def print_risk_level
            puts
            puts "Risk level: #{analyzer.risk_level}"
          end

          # Shared hyphen-list formatter keeps this class under RuboCop limits.
          module PrintHyphenList
            module_function

            def call(title, elements)
              puts
              puts "#{title}:"
              if elements.empty?
                puts '- none'
              else
                elements.each { |el| puts "- #{el}" }
              end
            end
          end
        end
      end
    end
  end
end
