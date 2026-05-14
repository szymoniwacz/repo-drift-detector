# frozen_string_literal: true

require 'repo/drift/detector/version'
require 'repo/drift/detector/analyzer'

module Repo
  module Drift
    module Detector
      class Error < StandardError; end

      def self.run
        puts 'repo-drift-detector'
      end
    end
  end
end
