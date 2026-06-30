# frozen_string_literal: true

require_relative 'language_registry'

module Repo
  module Drift
    module Detector
      class LineFindingExtractor
        REVIEW_PATTERNS = [
          [/\b(TODO|FIXME|HACK)\b/i, 'temporary marker added'],
          [/\b(binding\.pry|debugger|console\.log|puts\s+)\b/, 'debug output added'],
          [/\b(eval|exec|system)\s*\(/, 'dynamic execution call added'],
          [/\brescue\s+nil\b/, 'silent error handling added'],
          [/\b(password|secret|token|api_key)\b/i, 'sensitive-looking identifier added'],
          [/\bSELECT\s+\*/i, 'broad SQL select added'],
          [/\bskip(_|\s)?validation|validate:\s*false\b/i, 'validation bypass added']
        ].freeze

        def initialize(diff:, production_files:)
          @diff = diff.to_s
          @production_files = production_files
        end

        def call
          findings = []
          current_file = nil
          new_line_number = nil

          diff.each_line do |raw_line|
            line = raw_line.chomp

            if line.start_with?('diff --git ')
              current_file = parse_diff_file(line)
              new_line_number = nil
              next
            end

            if line.start_with?('+++ b/')
              current_file = line.delete_prefix('+++ b/')
              next
            end

            if line.start_with?('@@')
              new_line_number = parse_hunk_start(line)
              next
            end

            next unless current_file && new_line_number

            if line.start_with?('+') && !line.start_with?('+++')
              source_line = line.delete_prefix('+')
              finding = finding_for(current_file, new_line_number, source_line)
              findings << finding if finding
              new_line_number += 1
              next
            end

            new_line_number += 1 unless line.start_with?('-')
          end

          findings
        end

        private

        attr_reader :diff, :production_files

        def parse_diff_file(line)
          line.split.last.to_s.delete_prefix('b/')
        end

        def parse_hunk_start(line)
          match = line.match(/\+(\d+)/)
          match[1].to_i if match
        end

        def finding_for(file, line_number, source_line)
          stripped = source_line.strip
          return if stripped.empty?
          return unless production_files.include?(file)

          reason = reason_for(stripped)
          return unless reason

          {
            file: file,
            line: line_number,
            language: LanguageRegistry.detect(file),
            content: stripped,
            reason: reason
          }
        end

        def reason_for(source_line)
          pattern = REVIEW_PATTERNS.find { |regex, _reason| source_line.match?(regex) }
          return pattern[1] if pattern

          'long production line added' if source_line.length > 120
        end
      end
    end
  end
end
