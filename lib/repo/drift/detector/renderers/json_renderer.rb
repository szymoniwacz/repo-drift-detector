# frozen_string_literal: true

require 'json'

module Repo
  module Drift
    module Detector
      module Renderers
        class JsonRenderer
          def render(summary)
            puts JSON.generate(summary)
          end
        end
      end
    end
  end
end
