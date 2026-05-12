require "repo/drift/detector/version"

module Repo
  module Drift
    module Detector
      class Error < StandardError; end

      def self.run
        puts "repo-drift-detector"
      end
    end
  end
end
