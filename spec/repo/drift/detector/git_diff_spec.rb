# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/git_diff'

RSpec.describe Repo::Drift::Detector::GitDiff do
  def success_status
    instance_double(Process::Status, success?: true)
  end

  def failure_status
    instance_double(Process::Status, success?: false)
  end

  describe '#changed_file_names' do
    it 'runs git with separate arguments (no shell interpolation)' do
      expect(Open3).to receive(:capture3)
        .with('git', 'diff', '--name-only', 'main')
        .and_return(["file.rb\n", '', success_status])

      expect(described_class.new(base: 'main').changed_file_names).to eq("file.rb\n")
    end

    it 'passes the base ref as a single argument even when it contains shell metacharacters' do
      malicious_base = 'main; rm -rf /'

      expect(Open3).to receive(:capture3)
        .with('git', 'diff', '--name-only', malicious_base)
        .and_return(['', "fatal: bad revision\n", failure_status])

      expect do
        described_class.new(base: malicious_base).changed_file_names
      end.to raise_error(Repo::Drift::Detector::GitDiffError, /Git diff against 'main; rm -rf \/' failed/)
    end

    it 'raises GitDiffError when git fails' do
      expect(Open3).to receive(:capture3)
        .with('git', 'diff', '--name-only', 'definitely-not-a-real-ref')
        .and_return(['', "fatal: bad revision 'definitely-not-a-real-ref'\n", failure_status])

      expect do
        described_class.new(base: 'definitely-not-a-real-ref').changed_file_names
      end.to raise_error(
        Repo::Drift::Detector::GitDiffError,
        /Git diff against 'definitely-not-a-real-ref' failed: fatal: bad revision/
      )
    end
  end

  describe '#numstat_lines' do
    it 'runs git diff --numstat with separate arguments' do
      output = "10\t5\tfile.rb\n"

      expect(Open3).to receive(:capture3)
        .with('git', 'diff', '--numstat', 'main')
        .and_return([output, '', success_status])

      expect(described_class.new(base: 'main').numstat_lines).to eq(output)
    end
  end
end
