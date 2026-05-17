# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/renderers/output_renderer'
require 'json'

RSpec.describe Repo::Drift::Detector::Renderers::OutputRenderer do
  def comparison_data
    {
      deterministic: 'Repository risk is elevated.',
      static_ai: 'Assessed repository drift risk as high.',
      notes: [
        'deterministic explanation is more signal-oriented',
        'static-ai explanation is more interpretive'
      ]
    }
  end

  def report_payload(explanation: 'Repository risk is elevated.', compare: false)
    payload = { goal: 'feature', base: 'main', changed_file_count: 2, risk_level: :high }
    return payload.merge(comparison: comparison_data) if compare

    payload.merge(interpreter: 'deterministic', explanation: explanation)
  end

  def build_renderer(format: nil, compare: false, **overrides)
    explanation = overrides.fetch(:explanation, 'Repository risk is elevated.')
    sources = overrides.fetch(:sources) do
      {
        report_payload: overrides.fetch(:report_payload, -> { report_payload(explanation: explanation, compare: compare) }),
        comparison: overrides.fetch(:comparison, -> { comparison_data }),
        explanation: overrides.fetch(:explanation_source, -> { explanation })
      }
    end

    described_class.new(
      format: format,
      compare: compare,
      interpreter_name: overrides.fetch(:interpreter_name, 'deterministic'),
      sources: sources
    )
  end

  describe '#render' do
    it 'returns plain explanation text by default' do
      output = build_renderer.render

      expect(output).to eq('Repository risk is elevated.')
    end

    it 'renders JSON for single mode when format is json' do
      json = JSON.parse(build_renderer(format: 'json').render)

      expect(json).to include(
        'goal' => 'feature',
        'interpreter' => 'deterministic',
        'explanation' => 'Repository risk is elevated.'
      )
    end

    it 'renders markdown for single mode when format is markdown' do
      output = build_renderer(format: 'markdown').render

      expect(output).to start_with("## Explanation\n\n")
      expect(output).to include('Repository risk is elevated.')
    end

    it 'renders static-ai markdown title when interpreter is static-ai' do
      output = build_renderer(
        format: 'markdown',
        interpreter_name: 'static-ai',
        explanation: 'Assessed repository drift risk as high.',
        explanation_source: -> { 'Assessed repository drift risk as high.' }
      ).render

      expect(output).to start_with("## Static AI Explanation\n\n")
    end

    context 'with compare enabled' do
      it 'renders comparison text output' do
        output = build_renderer(compare: true).render

        expect(output).to include('=== Deterministic explanation ===')
        expect(output).to include('Repository risk is elevated.')
        expect(output).to include('=== Static AI explanation ===')
        expect(output).to include('=== Comparison notes ===')
        expect(output).to include('- deterministic explanation is more signal-oriented')
      end

      it 'renders comparison JSON when format is json' do
        json = JSON.parse(build_renderer(compare: true, format: 'json').render)

        expect(json['comparison']).to include(
          'deterministic' => 'Repository risk is elevated.',
          'static_ai' => 'Assessed repository drift risk as high.'
        )
        expect(json).not_to have_key('explanation')
      end

      it 'renders comparison markdown when format is markdown' do
        output = build_renderer(compare: true, format: 'markdown').render

        expect(output).to include('## Deterministic Explanation')
        expect(output).to include('## Static AI Explanation')
        expect(output).to include('## Comparison Notes')
      end
    end

    it 'remains deterministic for the same input' do
      renderer = build_renderer(compare: true)

      expect(renderer.render).to eq(build_renderer(compare: true).render)
    end

    it 'does not call report_payload when rendering compare text' do
      output = build_renderer(
        compare: true,
        sources: {
          report_payload: proc { raise 'report_payload should not be called' },
          comparison: proc { comparison_data },
          explanation: proc { 'Repository risk is elevated.' }
        }
      ).render

      expect(output).to include('=== Comparison notes ===')
    end

    it 'does not call comparison when rendering single text' do
      output = build_renderer(
        sources: {
          report_payload: proc { report_payload },
          comparison: proc { raise 'comparison should not be called' },
          explanation: proc { 'Repository risk is elevated.' }
        }
      ).render

      expect(output).to eq('Repository risk is elevated.')
    end
  end
end
