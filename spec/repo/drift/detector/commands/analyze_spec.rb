# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/commands/analyze'
require 'tmpdir'
require 'stringio'
require 'json'

RSpec.describe Repo::Drift::Detector::Commands::Analyze do
  describe '#call' do
    it 'prints goal and base' do
      argv = ['--goal', 'feature-branch', '--base', 'main']
      command = described_class.new(argv)

      output = capture_output { command.call }

      expect(output).not_to include('Analysis written to')
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

      output = capture_output { command.call }

      expect(output).to include('Change stats:')
      expect(output).to include('config.rb (+5/-2) total=7')
      expect(output).to include('Risk reasons:')
      expect(output).to match(/Risk reasons:\s*\n- none/m)
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(%w[total_changes_above_100 total_changes_above_20])

      output = capture_output { command.call }

      expect(output).to include('Large changes:')
      expect(output).to include('large.rb total=150')
      expect(output).to include('- total_changes_above_100')
      expect(output).to include('- total_changes_above_20')
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(['total_changes_above_20'])

      output = capture_output { command.call }

      expect(output).to include('Risk level: medium')
      expect(output).to include('Risk reasons:')
      expect(output).to include('- total_changes_above_20')
    end

    it 'prints multiple risk reasons on separate lines in text output' do
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
        .to receive(:risk_level).and_return(:high)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(%w[high_risk_files_detected total_changes_above_20])

      output = capture_output { command.call }

      expect(output).to include('Risk reasons:')
      expect(output).to include('- high_risk_files_detected')
      expect(output).to include('- total_changes_above_20')
    end

    it 'outputs valid JSON when format json is requested' do
      argv = ['--goal', 'feature', '--base', 'main', '--format', 'json']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_count).and_return(2)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return(['file1.rb', 'file2.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return([
          { file: 'file1.rb', added: 1, removed: 0, total_changes: 1 },
          { file: 'file2.rb', added: 2, removed: 1, total_changes: 3 }
        ])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([
          { file: 'file2.rb', added: 2, removed: 1, total_changes: 3 }
        ])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:documentation_files).and_return(['README.md'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:test_files).and_return(['spec/analyzer_spec.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:production_files).and_return(['file1.rb', 'file2.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:unsafe_change_ratio).and_return(2.0)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return(['file2.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:medium)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(%w[high_risk_files_detected total_changes_above_20])

      output = capture_output { command.call }
      json = JSON.parse(output)

      expect(json).to include(
        'goal' => 'feature',
        'base' => 'main',
        'changed_file_count' => 2,
        'changed_files' => ['file1.rb', 'file2.rb'],
        'unsafe_change_ratio' => 2.0,
        'high_risk_files' => ['file2.rb'],
        'risk_level' => 'medium',
        'risk_reasons' => %w[high_risk_files_detected total_changes_above_20]
      )
      expect(output.chomp).to eq(JSON.pretty_generate(json))
      expect(output.lines.size).to be > 1
      expect(output).not_to include('Goal:')
      expect(output).not_to include('Changed files:')
      expect(output).not_to include('High risk files:')
    end

    it 'includes risk_reasons as empty array in JSON for low risk' do
      argv = ['--goal', 'feature', '--base', 'main', '--format', 'json']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_count).and_return(0)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:documentation_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:test_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:production_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:unsafe_change_ratio).and_return(0.0)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:low)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

      output = capture_output { command.call }

      parsed = JSON.parse(output)
      expect(parsed['risk_reasons']).to eq([])
      expect(output.chomp).to eq(JSON.pretty_generate(parsed))
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

      output = capture_output { command.call }

      expect(output).to include('Changed files:')
      expect(output).to include('Large changes:')
      expect(output).to include('- none')
      expect(output).to include('High risk files:')
      expect(output).to include('Risk level: low')
      expect(output).to include('Risk reasons:')
      expect(output).to match(/Risk reasons:\s*\n- none/m)
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

      output = capture_output { command.call }

      expect(output).to start_with('Analyzing repository drift...')
    end

    it 'does not fail when no fail-on is provided' do
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

      expect { command.call }.not_to raise_error
    end

    it 'fails with status 1 for high risk when --fail-on high is provided' do
      argv = ['--goal', 'feature', '--base', 'main', '--fail-on', 'high']
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
        .to receive(:risk_level).and_return(:high)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(['unsafe_change_ratio_above_threshold'])

      expect { capture_output { command.call } }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it 'does not fail for medium risk when --fail-on high is provided' do
      argv = ['--goal', 'feature', '--base', 'main', '--fail-on', 'high']
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(['total_changes_above_20'])

      expect { command.call }.not_to raise_error
    end

    it 'fails with status 1 for medium risk when --fail-on medium is provided' do
      argv = ['--goal', 'feature', '--base', 'main', '--fail-on', 'medium']
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(['total_changes_above_20'])

      expect { capture_output { command.call } }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it 'does not fail for low risk when --fail-on medium is provided' do
      argv = ['--goal', 'feature', '--base', 'main', '--fail-on', 'medium']
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

      expect { command.call }.not_to raise_error
    end

    it 'prints an error and exits 2 for invalid --fail-on values' do
      argv = ['--goal', 'feature', '--base', 'main', '--fail-on', 'critical']
      command = described_class.new(argv)

      stdout, stderr = capture_output_and_error do
        expect { command.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(2)
        end
      end

      expect(stderr).to include("Invalid --fail-on value 'critical'")
      expect(stdout).to be_empty
    end

    it 'prints config error and exits 2 when .repo-drift-detector.yml is invalid' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, Repo::Drift::Detector::Config::FILENAME), "{not yaml")
        Dir.chdir(dir) do
          argv = ['--goal', 'feature', '--base', 'main']
          command = described_class.new(argv)

          stdout, stderr = capture_output_and_error do
            expect { command.call }.to raise_error(SystemExit) do |error|
              expect(error.status).to eq(2)
            end
          end

          expect(stderr).to match(/invalid YAML/i)
          expect(stdout).to be_empty
        end
      end
    end

    it 'still prints valid JSON when using --format json and --fail-on medium' do
      argv = ['--goal', 'feature', '--base', 'main', '--format', 'json', '--fail-on', 'medium']
      command = described_class.new(argv)

      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_count).and_return(1)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_files).and_return(['file1.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:changed_file_stats).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:large_change_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:documentation_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:test_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:production_files).and_return(['file1.rb'])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:unsafe_change_ratio).and_return(0.0)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:high_risk_files).and_return([])
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_level).and_return(:medium)
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return(['total_changes_above_20'])

      stdout, stderr = capture_output_and_error do
        expect { command.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      parsed = JSON.parse(stdout)
      expect(parsed['risk_level']).to eq('medium')
      expect(parsed['risk_reasons']).to eq(['total_changes_above_20'])
      expect(stdout.chomp).to eq(JSON.pretty_generate(parsed))
      expect(stderr).to be_empty
    end

    it 'writes text analysis to --output file' do
      Dir.mktmpdir do |dir|
        out_file = File.join(dir, 'report.txt')
        argv = ['--goal', 'feature', '--base', 'main', '--output', out_file]
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
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:risk_reasons).and_return([])

        stdout = capture_output { command.call }

        written = File.read(out_file)
        expect(written).to include('Analyzing repository drift...')
        expect(written).to include('Goal: feature')
        expect(written).to include('Base: main')
        expect(written).to include('Risk level: low')
        expect(stdout).to eq("Analysis written to #{out_file}\n")
      end
    end

    it 'writes pretty JSON to --output file' do
      Dir.mktmpdir do |dir|
        out_file = File.join(dir, 'drift-report.json')
        argv = ['--goal', 'feature', '--base', 'main', '--format', 'json', '--output', out_file]
        command = described_class.new(argv)

        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:changed_file_count).and_return(1)
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:changed_files).and_return(['file1.rb'])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:changed_file_stats).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:large_change_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:documentation_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:test_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:production_files).and_return(['file1.rb'])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:unsafe_change_ratio).and_return(0.0)
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:high_risk_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:risk_level).and_return(:low)
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:risk_reasons).and_return([])

        stdout = capture_output { command.call }

        file_body = File.read(out_file)
        parsed = JSON.parse(file_body)
        expect(parsed['goal']).to eq('feature')
        expect(parsed['base']).to eq('main')
        expect(parsed['risk_level']).to eq('low')
        expect(file_body.chomp).to eq(JSON.pretty_generate(parsed))
        expect(file_body.lines.size).to be > 1
        expect(stdout).to eq("Analysis written to #{out_file}\n")
        expect(stdout).not_to include('changed_file_count')
      end
    end

    it 'exits 2 when --output path cannot be written' do
      root = Dir.mktmpdir
      bad_path = File.join(root, 'missing', 'out.txt')
      argv = ['--goal', 'feature', '--base', 'main', '--output', bad_path]
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
      allow_any_instance_of(Repo::Drift::Detector::Analyzer)
        .to receive(:risk_reasons).and_return([])

      stdout, stderr = capture_output_and_error do
        expect { command.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(2)
        end
      end

      expect(stderr).to match(/Cannot write output/)
      expect(stdout).to be_empty
    end

    it 'exits 2 when --output is missing a path' do
      argv = ['--goal', 'feature', '--base', 'main', '--output']
      command = described_class.new(argv)

      stdout, stderr = capture_output_and_error do
        expect { command.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(2)
        end
      end

      expect(stderr).to include('Invalid --output')
      expect(stdout).to be_empty
    end

    it 'writes JSON to file then exits 1 for --fail-on when risk is high' do
      Dir.mktmpdir do |dir|
        out_file = File.join(dir, 'out.json')
        argv = [
          '--goal', 'feature', '--base', 'main',
          '--format', 'json', '--output', out_file,
          '--fail-on', 'high'
        ]
        command = described_class.new(argv)

        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:changed_file_count).and_return(0)
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:changed_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:changed_file_stats).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:large_change_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:documentation_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:test_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:production_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:unsafe_change_ratio).and_return(0.0)
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:high_risk_files).and_return([])
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:risk_level).and_return(:high)
        allow_any_instance_of(Repo::Drift::Detector::Analyzer)
          .to receive(:risk_reasons).and_return(['unsafe_change_ratio_above_threshold'])

        stdout, stderr = capture_output_and_error do
          expect { command.call }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end

        expect(JSON.parse(File.read(out_file))['risk_level']).to eq('high')
        expect(stdout).to eq("Analysis written to #{out_file}\n")
        expect(stderr).to be_empty
      end
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

  def capture_output_and_error
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end
