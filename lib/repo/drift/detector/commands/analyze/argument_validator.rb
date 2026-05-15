# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      module Commands
        class Analyze
          # Validates analyze CLI flags and their values before loading config or running analysis.
          class ArgumentValidator
            def initialize(argv)
              @argv = argv
            end

            def validate
              validate_fail_on_option
            end

            private

            attr_reader :argv

            def option_value(flag)
              index = argv.index(flag)
              argv[index + 1] if index
            end

            def validate_fail_on_option
              value = option_value('--fail-on')
              return if value.nil?
              return if Analyze::FAIL_ON_LEVELS.key?(value)

              warn "Invalid --fail-on value '#{value}'. Valid values are: #{Analyze::FAIL_ON_LEVELS.keys.join(', ')}."
              exit 2
            end
          end
        end
      end
    end
  end
end
