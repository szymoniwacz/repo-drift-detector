# frozen_string_literal: true

require 'repo/drift/detector/renderers/comparison_markdown_renderer'
require 'repo/drift/detector/renderers/comparison_text_renderer'
require 'repo/drift/detector/renderers/explanation_markdown_renderer'
require 'repo/drift/detector/renderers/json_renderer'

module Repo
  module Drift
    module Detector
      module Renderers
        class OutputRenderer
          def initialize(format:, compare:, interpreter_name:, sources:)
            @format = format
            @compare = compare
            @interpreter_name = interpreter_name
            @report_payload = sources.fetch(:report_payload)
            @comparison = sources.fetch(:comparison)
            @explanation = sources.fetch(:explanation)
          end

          def render
            return render_compare_output if compare?

            render_single_output
          end

          private

          attr_reader :format, :compare, :interpreter_name, :report_payload, :comparison, :explanation

          def compare?
            compare
          end

          def json?
            format == 'json'
          end

          def markdown?
            format == 'markdown'
          end

          def render_compare_output
            return json_renderer.render(resolve(report_payload)) if json?
            return ComparisonMarkdownRenderer.new.render(resolve(comparison)) if markdown?

            ComparisonTextRenderer.new.render(resolve(comparison))
          end

          def render_single_output
            return json_renderer.render(resolve(report_payload)) if json?
            if markdown?
              return ExplanationMarkdownRenderer.new.render(
                interpreter_name: interpreter_name,
                explanation: resolve(explanation)
              )
            end

            resolve(explanation)
          end

          def resolve(source)
            source.respond_to?(:call) ? source.call : source
          end

          def json_renderer
            @json_renderer ||= JsonRenderer.new
          end
        end
      end
    end
  end
end
