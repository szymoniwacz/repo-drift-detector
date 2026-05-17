# frozen_string_literal: true

require 'repo/drift/detector/ai/configuration_error'
require 'repo/drift/detector/analyzer'
require 'repo/drift/detector/config'
require_relative 'explain/argument_validator'
require_relative 'explain_runner'

module Repo
  module Drift
    module Detector
      module Commands
        class Explain
          def initialize(argv)
            @argv = argv
          end

          def call
            ArgumentValidator.new(argv).validate
            load_config!

            deliver_output(runner.render)
          rescue Ai::ConfigurationError => e
            warn e.message
            exit 2
          end

          private

          attr_reader :argv

          def runner
            @runner ||= Commands::ExplainRunner.new(
              analyzer: analyzer,
              goal: goal,
              base: base,
              compare: compare?,
              format: option_value('--format'),
              interpreter: option_value('--interpreter')
            )
          end

          def goal
            option_value('--goal')
          end

          def base
            option_value('--base')
          end

          def analyzer
            @analyzer ||= Analyzer.new(base: base, config: load_config!)
          end

          def load_config!
            @load_config ||= Config.load
          rescue ConfigError => e
            warn e.message
            exit 2
          end

          def option_value(name)
            index = argv.index(name)
            argv[index + 1] if index
          end

          def compare?
            argv.include?('--compare')
          end

          def output_path
            option_value('--output')
          end

          def deliver_output(content)
            path = output_path
            if path
              write_output_file(content, path)
              puts "Explanation written to #{path}"
            else
              puts content
            end
          end

          def write_output_file(content, path)
            File.write(path, content)
          rescue SystemCallError => e
            warn "Cannot write output to #{path}: #{e.message}"
            exit 2
          end
        end
      end
    end
  end
end
