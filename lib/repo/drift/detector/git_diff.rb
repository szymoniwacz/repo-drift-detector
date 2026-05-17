# frozen_string_literal: true

require 'open3'

require_relative 'git_diff_error'

module Repo
  module Drift
    module Detector
      class GitDiff
        def initialize(base:)
          @base = base
        end

        def changed_file_names
          run_git(%w[git diff --name-only])
        end

        def numstat_lines
          run_git(%w[git diff --numstat])
        end

        private

        attr_reader :base

        def run_git(command)
          stdout, stderr, status = Open3.capture3(*command, base)
          return stdout if status.success?

          raise GitDiffError, failure_message(stderr, stdout)
        end

        def failure_message(stderr, stdout)
          detail = stderr.to_s.strip
          detail = stdout.to_s.strip if detail.empty?
          detail = 'git command failed' if detail.empty?

          "Git diff against '#{base}' failed: #{detail}"
        end
      end
    end
  end
end
