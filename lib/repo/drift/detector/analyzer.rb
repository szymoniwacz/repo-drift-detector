# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class Analyzer
        def initialize(base:)
          @base = base
        end

        def changed_files
          `git diff --name-only #{@base}`.split("\n")
        end

        def changed_file_stats
          `git diff --numstat #{@base}`.split("\n").map do |line|
            added, removed, file = line.split("\t")

            {
              file: file,
              added: added.to_i,
              removed: removed.to_i,
              total_changes: added.to_i + removed.to_i
            }
          end
        end
      end
    end
  end
end
