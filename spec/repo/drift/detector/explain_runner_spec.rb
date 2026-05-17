# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/explain_runner'
require 'repo/drift/detector/interpreters/deterministic_interpreter'
require 'repo/drift/detector/interpreters/static_ai_interpreter'
require 'json'

RSpec.describe Repo::Drift::Detector::ExplainRunner do
  before { stub_analyzer_for_runner }

  describe '#render' do
    it 'returns deterministic explanation text for the default interpreter' do
      output = build_runner.render

      expect(output).to include('Repository risk is elevated')
      expect(output).not_to match(/\b(AI|LLM|OpenAI|model|prompt)\b/i)
    end

    it 'uses StaticAiInterpreter when interpreter is static-ai' do
      output = build_runner(interpreter: 'static-ai').render

      expect(output).to include('Assessed repository drift risk as high')
      expect(output).to include('Taken together, the signals point to')
      expect(output).not_to include('Signal brief:')
      expect(output).not_to include('Repository risk is elevated')
    end

    it 'renders JSON when format is json' do
      json = JSON.parse(build_runner(format: 'json').render)

      expect(json).to include(
        'goal' => 'feature',
        'base' => 'main',
        'interpreter' => 'deterministic'
      )
      expect(json['explanation']).to include('Repository risk is elevated')
    end

    it 'renders markdown when format is markdown' do
      output = build_runner(format: 'markdown').render

      expect(output).to start_with("## Explanation\n\n")
      expect(output).to include('Repository risk is elevated')
    end

    it 'remains deterministic for the same input' do
      runner = build_runner

      expect(runner.render).to eq(build_runner.render)
    end

    context 'with compare enabled' do
      it 'returns both explanations and comparison notes in text output' do
        output = build_runner(compare: true).render

        expect(output).to include('=== Deterministic explanation ===')
        expect(output).to include('Repository risk is elevated')
        expect(output).to include('=== Static AI explanation ===')
        expect(output).to include('Assessed repository drift risk as high')
        expect(output).to include('=== Comparison notes ===')
        expect(output).to include('- deterministic explanation is more signal-oriented')
      end

      it 'renders comparison JSON when format is json' do
        json = JSON.parse(build_runner(compare: true, format: 'json').render)

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
      end

      it 'renders comparison markdown when format is markdown' do
        output = build_runner(compare: true, format: 'markdown').render

        expect(output).to include('## Deterministic Explanation')
        expect(output).to include('## Static AI Explanation')
        expect(output).to include('## Comparison Notes')
      end

      it 'does not expose internal prompt instructions in static-ai comparison output' do
        output = build_runner(compare: true).render

        expect(output).not_to include('Signal brief:')
        expect(output).not_to include('Do not invent architecture')
      end
    end
  end

  describe '#report_payload' do
    it 'includes interpreter and explanation for single mode' do
      payload = build_runner(format: 'json').report_payload

      expect(payload).to include(
        interpreter: 'deterministic',
        goal: 'feature',
        base: 'main'
      )
      expect(payload[:explanation]).to include('Repository risk is elevated')
    end

    it 'includes comparison data for compare mode' do
      payload = build_runner(compare: true).report_payload

      expect(payload[:comparison]).to include(
        :deterministic,
        :static_ai,
        :notes
      )
      expect(payload).not_to have_key(:explanation)
      expect(payload).not_to have_key(:interpreter)
    end

    it 'embeds report_payload fields in JSON render output for single mode' do
      runner = build_runner(format: 'json')
      rendered = JSON.parse(runner.render)
      payload = runner.report_payload

      expect(rendered['explanation']).to eq(payload[:explanation])
      expect(rendered['interpreter']).to eq(payload[:interpreter])
      expect(rendered['changed_file_count']).to eq(payload[:changed_file_count])
    end
  end

  private

  def build_runner(compare: false, format: nil, interpreter: nil)
    described_class.new(
      analyzer: Repo::Drift::Detector::Analyzer.new(base: 'main'),
      goal: 'feature',
      base: 'main',
      compare: compare,
      format: format,
      interpreter: interpreter
    )
  end

  def stub_analyzer_for_runner
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
end
