# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/renderers/explanation_renderer'

RSpec.describe Repo::Drift::Detector::ExplanationRenderer do
  def context_from(summary)
    Repo::Drift::Detector::ExplanationContext.new(summary).to_h
  end

  def low_risk_context
    context_from(
      risk_level: :low,
      risk_score: 5,
      changed_file_count: 1,
      production_file_count: 1,
      test_file_count: 1,
      documentation_file_count: 0,
      unsafe_change_ratio: 1.0,
      high_risk_file_count: 0,
      large_change_count: 0
    )
  end

  def medium_risk_context
    context_from(
      risk_level: :medium,
      risk_score: 42,
      changed_file_count: 5,
      production_file_count: 3,
      test_file_count: 1,
      documentation_file_count: 0,
      unsafe_change_ratio: 2.0,
      high_risk_file_count: 1,
      large_change_count: 1
    )
  end

  def high_risk_context
    context_from(
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

  describe '#render' do
    it 'returns a short calm explanation for low risk' do
      explanation = described_class.new(low_risk_context).render

      expect(explanation).to include('Repository risk is low')
      expect(explanation).not_to include('Review attention should focus on:')
    end

    it 'explains visible repository risk factors for medium risk' do
      explanation = described_class.new(medium_risk_context).render

      expect(explanation).to include('Repository risk is moderate')
      expect(explanation).to include('documentation updates')
      expect(explanation).to include('1 high-risk file changed')
      expect(explanation).to include('Review attention should focus on:')
    end

    it 'explains accumulation of risk signals for high risk' do
      explanation = described_class.new(high_risk_context).render

      expect(explanation).to include('Repository risk is elevated')
      expect(explanation).to include('without corresponding tests or documentation updates')
      expect(explanation).to include('The unsafe change ratio reached: 4.5.')
      expect(explanation).to include('3 high-risk files changed')
      expect(explanation).to include('Multiple observable risk signals are present together')
    end

    it 'mentions missing tests when production changes lack test files' do
      explanation = described_class.new(high_risk_context).render

      expect(explanation).to match(/without corresponding tests or documentation updates/)
    end

    it 'mentions missing documentation when production changes lack documentation files' do
      explanation = described_class.new(medium_risk_context).render

      expect(explanation).to include('without corresponding documentation updates')
    end

    it 'describes an elevated unsafe change ratio with consistent formatting' do
      summary = high_risk_context.merge(unsafe_change_ratio: 3.0)
      explanation = described_class.new(context_from(summary)).render

      expect(explanation).to include('The unsafe change ratio reached: 3.0.')
    end

    it 'mentions high-risk files when high_risk_file_count is positive' do
      explanation = described_class.new(medium_risk_context).render

      expect(explanation).to include('high-risk file changed')
    end

    it 'remains deterministic for the same input' do
      renderer = described_class.new(medium_risk_context)
      first = renderer.render
      second = renderer.render

      expect(first).to eq(second)
    end

    it 'does not mention AI-related terms' do
      explanation = described_class.new(high_risk_context).render

      expect(explanation).not_to match(/\b(AI|LLM|OpenAI|model|prompt)\b/i)
    end

    it 'does not invent architecture details' do
      explanation = described_class.new(high_risk_context).render

      expect(explanation).not_to match(/\b(microservices|kubernetes|monolith)\b/i)
      expect(explanation).not_to match(/\bthe system (is|uses|implements)\b/i)
    end

    it 'uses values from ExplanationContext' do
      explanation = described_class.new(medium_risk_context).render

      expect(explanation).to include('1 high-risk file changed')
      expect(explanation).to include('1 file exceeds the large-change threshold')
    end

    it 'accepts an ExplanationContext instance' do
      context = Repo::Drift::Detector::ExplanationContext.new(
        risk_level: :low,
        risk_score: 0,
        changed_file_count: 0,
        production_file_count: 0,
        test_file_count: 0,
        documentation_file_count: 0,
        unsafe_change_ratio: 0.0,
        high_risk_file_count: 0,
        large_change_count: 0
      )

      explanation = described_class.new(context).render

      expect(explanation).to include('Repository risk is low')
    end
  end
end
