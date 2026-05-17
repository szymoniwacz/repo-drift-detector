# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/interpreters/deterministic_interpreter'
require 'repo/drift/detector/renderers/explanation_renderer'

RSpec.describe Repo::Drift::Detector::Interpreters::DeterministicInterpreter do
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

  describe '#interpret' do
    it 'returns the same output as ExplanationRenderer' do
      context = high_risk_context
      renderer_output = Repo::Drift::Detector::ExplanationRenderer.new(context).render
      interpreter_output = described_class.new.interpret(context)

      expect(interpreter_output).to eq(renderer_output)
    end

    it 'remains deterministic for the same input' do
      interpreter = described_class.new
      context = high_risk_context

      first = interpreter.interpret(context)
      second = interpreter.interpret(context)

      expect(first).to eq(second)
    end

    it 'does not mention AI-related terms' do
      explanation = described_class.new.interpret(high_risk_context)

      expect(explanation).not_to match(/\b(AI|LLM|OpenAI|model|prompt)\b/i)
    end
  end
end
