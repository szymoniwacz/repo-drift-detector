# frozen_string_literal: true

require "repo/drift/detector/analyzer"

module Repo
  module Drift
    module Detector
      module Commands
        class Analyze
          def initialize(argv)
            @argv = argv
          end

          def call
            puts "Analyzing repository drift..."
            puts "Goal: #{goal}"
            puts "Base: #{base}"

            print_changed_files
            print_change_stats
          end

          private

          attr_reader :argv

          def goal
            option_value("--goal")
          end

          def base
            option_value("--base")
          end

          def analyzer
            @analyzer ||= Analyzer.new(base: base)
          end

          def option_value(name)
            index = argv.index(name)
            argv[index + 1] if index
          end

          def print_changed_files
            puts
            puts "Changed files:"
            analyzer.changed_files.each { |file| puts "- #{file}" }
          end

          def print_change_stats
            puts
            puts "Change stats:"
            analyzer.changed_file_stats.each do |stat|
              puts "- #{stat[:file]} (+#{stat[:added]}/-#{stat[:removed]}) total=#{stat[:total_changes]}"
            end
          end
        end
      end
    end
  end
end
