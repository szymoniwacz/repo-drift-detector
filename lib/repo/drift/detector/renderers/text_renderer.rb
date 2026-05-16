# frozen_string_literal: true

require 'stringio'

module Repo
  module Drift
    module Detector
      module Renderers
        class TextRenderer
          def render(analyzer:, goal:, base:)
            @analyzer = analyzer
            @out = StringIO.new
            write_intro(goal, base)
            write_analysis
            @out.string
          ensure
            @analyzer = nil
            @out = nil
          end

          private

          attr_reader :analyzer, :out

          def write_intro(goal, base)
            out.puts 'Analyzing repository drift...'
            out.puts "Goal: #{goal}"
            out.puts "Base: #{base}"
          end

          def write_analysis
            write_changed_file_count
            write_changed_files
            write_change_stats
            write_large_change_files
            write_folder_lists
            write_unsafe_change_ratio
            write_risk_summary
          end

          def write_folder_lists
            PrintHyphenList.call('Documentation files', analyzer.documentation_files, out)
            PrintHyphenList.call('Test files', analyzer.test_files, out)
            PrintHyphenList.call('Production files', analyzer.production_files, out)
          end

          def write_risk_summary
            PrintHyphenList.call('High risk files', analyzer.high_risk_files, out)
            write_risk_level
            write_risk_score
            PrintHyphenList.call('Risk reasons', risk_reason_lines, out)
          end

          def risk_reason_lines
            reasons = analyzer.risk_reasons
            return ['none'] if reasons.empty?

            reasons
          end

          def write_changed_file_count
            out.puts
            out.puts "Changed file count: #{analyzer.changed_file_count}"
          end

          def write_changed_files
            out.puts
            out.puts 'Changed files:'
            analyzer.changed_files.each { |file| out.puts "- #{file}" }
          end

          def write_change_stats
            out.puts
            out.puts 'Change stats:'
            analyzer.changed_file_stats.each do |stat|
              out.puts "- #{stat[:file]} (+#{stat[:added]}/-#{stat[:removed]}) total=#{stat[:total_changes]}"
            end
          end

          def write_large_change_files
            lines = analyzer.large_change_files.map do |stat|
              "#{stat[:file]} total=#{stat[:total_changes]}"
            end
            PrintHyphenList.call('Large changes', lines, out)
          end

          def write_unsafe_change_ratio
            out.puts
            out.puts "Unsafe change ratio: #{format('%.1f', analyzer.unsafe_change_ratio)}"
          end

          def write_risk_level
            out.puts
            out.puts "Risk level: #{analyzer.risk_level}"
          end

          def write_risk_score
            out.puts "Risk score: #{analyzer.risk_score}"
          end

          module PrintHyphenList
            module_function

            def call(title, elements, output)
              output.puts
              output.puts "#{title}:"
              if elements.empty?
                output.puts '- none'
              else
                elements.each { |el| output.puts "- #{el}" }
              end
            end
          end
        end
      end
    end
  end
end
