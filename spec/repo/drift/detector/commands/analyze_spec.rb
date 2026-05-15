# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/commands/analyze'
require 'stringio'

RSpec.describe Repo::Drift::Detector::Commands::Analyze do
  describe '#call' do
    it 'prints goal and base' do
      argv = ['--goal', 'feature-branch', '--base', 'main']
      command = described_class.new(argv)

      output = capture_output { command.call }

      expect(output).to include('Goal: feature-branch')
      expect(output).to include('Base: main')
    end

    it 'prints changed files' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return(['file1.rb', 'file2.rb'])

      output = capture_output { command.call }

      expect(output).to include('Changed files:')
      expect(output).to include('- file1.rb')
      expect(output).to include('- file2.rb')
    end

    it 'prints change stats' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      stats = [
        { file: 'config.rb', added: 5, removed: 2, total_changes: 7 }
      ]
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return(stats)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:low)

      output = capture_output { command.call }

      expect(output).to include('Change stats:')
      expect(output).to include('config.rb (+5/-2) total=7')
    end

    it 'prints large changes' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      large_files = [
        { file: 'large.rb', added: 100, removed: 50, total_changes: 150 }
      ]
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return(large_files)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return(large_files)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:high)

      output = capture_output { command.call }

      expect(output).to include('Large changes:')
      expect(output).to include('large.rb total=150')
    end

    it 'prints high risk files' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return(['analyzer.rb', 'helper.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return(['analyzer.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:low)

      output = capture_output { command.call }

      expect(output).to include('High risk files:')
      expect(output).to include('- analyzer.rb')
    end

    it 'prints risk level' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:medium)

      output = capture_output { command.call }

      expect(output).to include('Risk level: medium')
    end

    it 'handles no changed files cleanly' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:low)

      output = capture_output { command.call }

      expect(output).to include('Changed files:')
      expect(output).to include('Large changes:')
      expect(output).to include('- none')
      expect(output).to include('High risk files:')
      expect(output).to include('Risk level: low')
    end

    it 'prints analyzer message at start' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:low)

      output = capture_output { command.call }

      expect(output).to start_with('Analyzing repository drift...')
    end
  end

  private

  def capture_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
