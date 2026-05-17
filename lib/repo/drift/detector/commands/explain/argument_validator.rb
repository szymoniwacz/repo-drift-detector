# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      module Commands
        class Explain
          class ArgumentValidator
            def initialize(argv)
              @argv = argv
            end

            def validate
              validate_interpreter_option
              validate_output_option
            end

            private

            attr_reader :argv

            def option_value(flag)
              index = argv.index(flag)
              argv[index + 1] if index
            end

            def validate_interpreter_option
              return unless argv.include?('--interpreter')

              value = option_value('--interpreter')
              unless value.is_a?(String) && !value.empty? && !value.start_with?('-')
                warn 'Invalid --interpreter: a value is required after --interpreter'
                exit 2
              end
              return if Explain::INTERPRETERS.key?(value)

              valid = Explain::INTERPRETERS.keys.join(', ')
              warn "Invalid --interpreter value '#{value}'. Valid values are: #{valid}."
              exit 2
            end

            def validate_output_option
              return unless argv.include?('--output')

              path = option_value('--output')
              return if path.is_a?(String) && !path.empty? && !path.start_with?('-')

              warn 'Invalid --output: a file path is required after --output'
              exit 2
            end
          end
        end
      end
    end
  end
end
