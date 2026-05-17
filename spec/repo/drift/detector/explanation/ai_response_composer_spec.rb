# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/explanation/ai_response_composer'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'

RSpec.describe Repo::Drift::Detector::AiResponseComposer do
  def high_risk_context
    Repo::Drift::Detector::ExplanationContext.new(
      risk_level: :high,
      risk_score: 92,
      changed_file_count: 8,
      production_file_count: 5,
      test_file_count: 0,
      documentation_file_count: 0,
      unsafe_change_ratio: 4.5,
      high_risk_file_count: 3,
      large_change_count: 2
    )
  end

  def forbidden_prompt_fragments
    [
      Repo::Drift::Detector::PromptBuilder::INTRO,
      Repo::Drift::Detector::PromptBuilder::CONSTRAINT,
      'Signal brief:',
      'Signals:',
      'Repository patterns:'
    ]
  end

  describe '#compose' do
    it 'returns deterministic output for the same input' do
      composer = described_class.new(high_risk_context)

      expect(composer.compose).to eq(composer.compose)
    end

    it 'composes interpretive text grounded in repository signals' do
      explanation = described_class.new(high_risk_context).compose

      expect(explanation).to include('Assessed repository drift risk as high with a risk score of 92')
      expect(explanation).to include('Taken together, the signals point to high repository drift risk')
      expect(explanation).to include('The unsafe change ratio of 4.5 suggests production-heavy change')
    end

    it 'omits extended signal insights when include_signal_insights is false' do
      explanation = described_class.new(high_risk_context).compose(include_signal_insights: false)

      expect(explanation).to include('Assessed repository drift risk as high')
      expect(explanation).not_to include('Taken together, the signals point to')
    end

    it 'does not leak internal prompt instructions' do
      explanation = described_class.new(high_risk_context).compose

      forbidden_prompt_fragments.each do |fragment|
        expect(explanation).not_to include(fragment)
      end
    end

    it 'does not invent file names or architecture' do
      explanation = described_class.new(high_risk_context).compose

      expect(explanation).not_to match(/\.rb/)
      expect(explanation).not_to match(/\b(microservices|kubernetes|monolith)\b/i)
    end
  end
end
