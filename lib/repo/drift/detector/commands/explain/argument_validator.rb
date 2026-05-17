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
              validate_format_option
              validate_compare_option
              validate_interpreter_option
              validate_output_option
            end

            private

            attr_reader :argv

            def option_value(flag)
              index = argv.index(flag)
              argv[index + 1] if index
            end

            def validate_format_option
              value = option_value('--format')
              return if value.nil?
              return if %w[json markdown].include?(value)

              warn "Invalid --format value '#{value}'. Valid values are: json, markdown."
              exit 2
            end

            def validate_compare_option
              return unless argv.include?('--compare')
              return unless argv.include?('--interpreter')

              warn 'Invalid options: --interpreter cannot be used with --compare.'
              exit 2
            end

            def validate_interpreter_option
              return unless argv.include?('--interpreter')
              return if argv.include?('--compare')

              value = option_value('--interpreter')
              exit_with_interpreter_usage_error if interpreter_value_missing?(value)
              return if ExplainRunner::INTERPRETERS.key?(value)

              exit_with_invalid_interpreter(value)
            end

            def interpreter_value_missing?(value)
              !value.is_a?(String) || value.empty? || value.start_with?('-')
            end

            def exit_with_interpreter_usage_error
              warn 'Invalid --interpreter: a value is required after --interpreter'
              exit 2
            end

            def exit_with_invalid_interpreter(value)
              valid = ExplainRunner::INTERPRETERS.keys.join(', ')
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
