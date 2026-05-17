# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/commands/explain'
require 'repo/drift/detector/interpreters/deterministic_interpreter'
require 'repo/drift/detector/interpreters/static_ai_interpreter'
require 'tmpdir'
require 'stringio'
require 'json'

RSpec.describe Repo::Drift::Detector::Commands::Explain do
  describe '#call' do
    before { stub_analyzer_for_explain }

    it 'prints deterministic explanation text' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      output = capture_output { command.call }

      expect(output).to include('Repository risk is elevated')
      expect(output).not_to match(/\b(AI|LLM|OpenAI|model|prompt)\b/i)
    end

    it 'outputs JSON with explanation when format json is requested' do
      argv = ['--goal', 'feature', '--base', 'main', '--format', 'json']
      command = described_class.new(argv)

      output = capture_output { command.call }
      json = JSON.parse(output)

      expect(json).to include(
        'goal' => 'feature',
        'base' => 'main',
        'interpreter' => 'deterministic'
      )
      expect(json).to have_key('summary')
      expect(json).to have_key('explanation')
      expect(json['explanation']).to include('Repository risk is elevated')
    end

    it 'includes explanation in --output JSON report' do
      Dir.mktmpdir do |dir|
        out_file = File.join(dir, 'explain-report.json')
        argv = ['--goal', 'feature', '--base', 'main', '--format', 'json', '--output', out_file]
        command = described_class.new(argv)

        stdout = capture_output { command.call }
        parsed = JSON.parse(File.read(out_file))

        expect(parsed['explanation']).to be_a(String)
        expect(parsed['explanation']).not_to be_empty
        expect(stdout).to eq("Explanation written to #{out_file}\n")
      end
    end

    it 'supports --goal in the report payload' do
      argv = ['--goal', 'my-feature', '--base', 'main', '--format', 'json']
      command = described_class.new(argv)

      output = capture_output { command.call }

      expect(JSON.parse(output)['goal']).to eq('my-feature')
    end

    it 'supports --base in the report payload' do
      argv = ['--goal', 'feature', '--base', 'origin/main', '--format', 'json']
      command = described_class.new(argv)

      output = capture_output { command.call }

      expect(JSON.parse(output)['base']).to eq('origin/main')
    end

    it 'default explanation matches DeterministicInterpreter for the same signals' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)
      context = Repo::Drift::Detector::ExplanationContext.new(stubbed_summary_payload)

      output = capture_output { command.call }.chomp
      expected = Repo::Drift::Detector::DeterministicInterpreter.new.interpret(context)

      expect(output).to eq(expected)
    end

    it 'remains deterministic for the same input' do
      argv = ['--goal', 'feature', '--base', 'main']
      command = described_class.new(argv)

      first = capture_output { command.call }
      second = capture_output { described_class.new(argv).call }

      expect(first).to eq(second)
    end

    it 'uses StaticAiInterpreter when --interpreter static-ai is provided' do
      argv = ['--goal', 'feature', '--base', 'main', '--interpreter', 'static-ai']
      command = described_class.new(argv)

      output = capture_output { command.call }

      expect(output).to include('Assessed repository drift risk as high')
      expect(output).to include('Taken together, the signals point to')
      expect(output).not_to include('Signal brief:')
      expect(output).not_to include('Explain repository risk based on these deterministic signals')
      expect(output).not_to include('Repository risk is elevated')
    end

    it 'includes interpreter in JSON output for static-ai interpreter' do
      argv = ['--goal', 'feature', '--base', 'main', '--format', 'json', '--interpreter', 'static-ai']
      command = described_class.new(argv)

      output = capture_output { command.call }
      json = JSON.parse(output)

      expect(json['interpreter']).to eq('static-ai')
      expect(json['explanation']).to include('Assessed repository drift risk as high')
      expect(json['explanation']).not_to include('Signal brief:')
    end

    it 'includes interpreter in --output JSON report for static-ai interpreter' do
      Dir.mktmpdir do |dir|
        out_file = File.join(dir, 'explain-static-ai.json')
        argv = [
          '--goal', 'feature', '--base', 'main',
          '--format', 'json', '--interpreter', 'static-ai', '--output', out_file
        ]
        command = described_class.new(argv)

        capture_output { command.call }

        expect(JSON.parse(File.read(out_file))['interpreter']).to eq('static-ai')
      end
    end

    it 'exits 2 for invalid --interpreter values' do
      argv = ['--goal', 'feature', '--base', 'main', '--interpreter', 'openai']
      command = described_class.new(argv)

      stdout, stderr = capture_output_and_error do
        expect { command.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(2)
        end
      end

      expect(stderr).to include("Invalid --interpreter value 'openai'")
      expect(stderr).to include('deterministic, static-ai')
      expect(stdout).to be_empty
    end

    it 'preserves existing JSON fields alongside explanation' do
      argv = ['--goal', 'feature', '--base', 'main', '--format', 'json']
      command = described_class.new(argv)

      output = capture_output { command.call }
      json = JSON.parse(output)

      expect(json).to include(
        'changed_file_count' => 2,
        'risk_level' => 'high',
        'summary' => a_hash_including('risk_score' => 92)
      )
    end

    describe 'compare mode' do
      let(:compare_argv) { ['--goal', 'feature', '--base', 'main', '--compare'] }

      it 'prints both explanations and comparison notes in text output' do
        command = described_class.new(compare_argv)

        output = capture_output { command.call }

        expect(output).to include('=== Deterministic explanation ===')
        expect(output).to include('Repository risk is elevated')
        expect(output).to include('=== Static AI explanation ===')
        expect(output).to include('Assessed repository drift risk as high')
        expect(output).to include('=== Comparison notes ===')
        expect(output).to include('- deterministic explanation is more signal-oriented')
        expect(output).to include('- static-ai explanation is more interpretive')
      end

      it 'includes comparison in JSON output' do
        command = described_class.new(compare_argv + ['--format', 'json'])

        json = JSON.parse(capture_output { command.call })

        expect(json['comparison']).to include(
          'deterministic' => a_string_including('Repository risk is elevated'),
          'static_ai' => a_string_including('Assessed repository drift risk as high'),
          'notes' => [
            'deterministic explanation is more signal-oriented',
            'static-ai explanation is more interpretive'
          ]
        )
        expect(json).not_to have_key('explanation')
        expect(json).not_to have_key('interpreter')
        expect(json['changed_file_count']).to eq(2)
      end

      it 'renders comparison in markdown output' do
        command = described_class.new(compare_argv + ['--format', 'markdown'])

        output = capture_output { command.call }

        expect(output).to include('## Deterministic Explanation')
        expect(output).to include('## Static AI Explanation')
        expect(output).to include('## Comparison Notes')
        expect(output).to include('- deterministic explanation is more signal-oriented')
      end

      it 'remains deterministic for the same input' do
        first = capture_output { described_class.new(compare_argv).call }
        second = capture_output { described_class.new(compare_argv).call }

        expect(first).to eq(second)
      end

      it 'does not expose internal prompt instructions in static-ai comparison output' do
        command = described_class.new(compare_argv)

        output = capture_output { command.call }

        expect(output).not_to include('Signal brief:')
        expect(output).not_to include('Do not invent architecture')
        expect(output).not_to include('Explain repository risk based on these deterministic signals')
      end

      it 'exits 2 when --compare is combined with --interpreter' do
        argv = ['--goal', 'feature', '--base', 'main', '--compare', '--interpreter', 'static-ai']
        command = described_class.new(argv)

        _stdout, stderr = capture_output_and_error do
          expect { command.call }.to raise_error(SystemExit) { |error| expect(error.status).to eq(2) }
        end

        expect(stderr).to include('--interpreter cannot be used with --compare')
      end
    end

    describe 'markdown format' do
      it 'renders a single deterministic explanation as markdown' do
        argv = ['--goal', 'feature', '--base', 'main', '--format', 'markdown']
        command = described_class.new(argv)

        output = capture_output { command.call }

        expect(output).to start_with("## Explanation\n\n")
        expect(output).to include('Repository risk is elevated')
      end

      it 'renders static-ai explanation as markdown without prompt leakage' do
        argv = ['--goal', 'feature', '--base', 'main', '--format', 'markdown', '--interpreter', 'static-ai']
        command = described_class.new(argv)

        output = capture_output { command.call }

        expect(output).to start_with("## Static AI Explanation\n\n")
        expect(output).to include('Assessed repository drift risk as high')
        expect(output).not_to include('Signal brief:')
        expect(output).not_to include('Do not invent architecture')
      end
    end
  end

  private

  def stubbed_summary_payload
    {
      risk_level: :high,
      risk_score: 92,
      changed_file_count: 2,
      production_file_count: 2,
      test_file_count: 0,
      documentation_file_count: 0,
      unsafe_change_ratio: 4.5,
      high_risk_file_count: 1,
      large_change_count: 1
    }
  end

  def stub_analyzer_for_explain
    large_change = { file: 'file2.rb', added: 2, removed: 1, total_changes: 3 }
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:changed_file_count).and_return(2)
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:changed_files).and_return(%w[file1.rb file2.rb])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:changed_file_stats).and_return([])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:large_change_files).and_return([large_change])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:documentation_files).and_return([])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:test_files).and_return([])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:production_files).and_return(%w[file1.rb file2.rb])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:unsafe_change_ratio).and_return(4.5)
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:high_risk_files).and_return(%w[file2.rb])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:risk_level).and_return(:high)
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:risk_reasons).and_return(['unsafe_change_ratio_above_threshold'])
    allow_any_instance_of(Repo::Drift::Detector::Analyzer)
      .to receive(:risk_score).and_return(92)
  end

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
