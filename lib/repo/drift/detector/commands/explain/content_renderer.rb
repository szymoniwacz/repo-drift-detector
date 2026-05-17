# frozen_string_literal: true

require 'repo/drift/detector/renderers/comparison_markdown_renderer'
require 'repo/drift/detector/renderers/comparison_text_renderer'
require 'repo/drift/detector/renderers/explanation_markdown_renderer'
require 'repo/drift/detector/renderers/json_renderer'

module Repo
  module Drift
    module Detector
      module Commands
        class Explain
          class ContentRenderer
            def initialize(command)
              @command = command
            end

            def render
              return render_comparison if send_to_command(:compare?)
              return Renderers::JsonRenderer.new.render(send_to_command(:report_payload)) if send_to_command(:json?)
              return render_single_markdown if send_to_command(:markdown?)

              send_to_command(:explanation_text)
            end

            private

            attr_reader :command

            def render_comparison
              data = send_to_command(:comparison_data)
              return Renderers::JsonRenderer.new.render(send_to_command(:report_payload)) if send_to_command(:json?)
              return Renderers::ComparisonMarkdownRenderer.new.render(data) if send_to_command(:markdown?)

              Renderers::ComparisonTextRenderer.new.render(data)
            end

            def render_single_markdown
              Renderers::ExplanationMarkdownRenderer.new.render(
                interpreter_name: send_to_command(:interpreter_name),
                explanation: send_to_command(:explanation_text)
              )
            end

            def send_to_command(method)
              command.send(method)
            end
          end
        end
      end
    end
  end
end
