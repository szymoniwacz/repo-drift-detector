# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/commands/explain_runner'
require 'json'

RSpec.describe Repo::Drift::Detector::Commands::ExplainRunner do
  before { stub_high_risk_analyzer }

  describe '#render' do
    it 'returns JSON with interpreter and explanation for single mode' do
      json = JSON.parse(build_runner(format: 'json').render)

      expect(json).to include('interpreter' => 'deterministic', 'goal' => 'feature', 'base' => 'main')
      expect(json['explanation']).to include('Repository risk is elevated')
    end

    it 'returns markdown for single mode' do
      output = build_runner(format: 'markdown').render

      expect(output).to start_with("## Explanation\n\n")
      expect(output).to include('Repository risk is elevated')
    end

    it 'returns static-ai text when interpreter is static-ai' do
      output = build_runner(interpreter: 'static-ai').render

      expect(output).to include('Assessed repository drift risk as high')
      expect(output).not_to include('Repository risk is elevated')
    end

    context 'with compare enabled' do
      it 'returns side-by-side text with comparison notes' do
        output = build_runner(compare: true).render

        expect(output).to include('=== Deterministic explanation ===', '=== Static AI explanation ===')
        expect(output).to include('=== Comparison notes ===')
        expect(output).to include('- deterministic explanation is more signal-oriented')
      end

      it 'returns comparison JSON without top-level explanation or interpreter keys' do
        json = JSON.parse(build_runner(compare: true, format: 'json').render)

        expect(json['comparison']['notes']).to include('static-ai explanation is more interpretive')
        expect(json).not_to have_key('explanation')
        expect(json).not_to have_key('interpreter')
      end

      it 'returns comparison markdown sections' do
        output = build_runner(compare: true, format: 'markdown').render

        expect(output).to include('## Deterministic Explanation', '## Static AI Explanation', '## Comparison Notes')
      end
    end
  end

  describe '#report_payload' do
    it 'includes comparison data in compare mode' do
      payload = build_runner(compare: true).report_payload

      expect(payload[:comparison]).to include(:deterministic, :static_ai, :notes)
      expect(payload).not_to have_key(:explanation)
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
end
