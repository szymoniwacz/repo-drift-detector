# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'repo/drift/detector/static_ai_interpreter'
require 'repo/drift/detector/deterministic_interpreter'
require 'repo/drift/detector/explanation_context'

RSpec.describe Repo::Drift::Detector::StaticAiInterpreter do
  def high_risk_summary
    {
      risk_level: :high,
      risk_score: 92,
      changed_file_count: 8,
      production_file_count: 5,
      test_file_count: 0,
      documentation_file_count: 0,
      unsafe_change_ratio: 4.5,
      high_risk_file_count: 3,
      large_change_count: 2
    }
  end

  def high_risk_context
    Repo::Drift::Detector::ExplanationContext.new(high_risk_summary)
  end

  describe '#interpret' do
    it 'returns deterministic output for the same input' do
      interpreter = described_class.new
      context = high_risk_context

      first = interpreter.interpret(context)
      second = interpreter.interpret(context)

      expect(first).to eq(second)
    end

    it 'uses context values in the assessment' do
      explanation = described_class.new.interpret(high_risk_context)

      expect(explanation).to include('Assessed repository drift risk as high with a risk score of 92')
      expect(explanation).to include('across 8 changed file(s)')
    end

    it 'accepts an ExplanationContext hash' do
      explanation = described_class.new.interpret(high_risk_context.to_h)

      expect(explanation).to include('risk score of 92')
      expect(explanation).to include('Signal brief:')
    end

    it 'does not call network APIs' do
      expect(Net::HTTP).not_to receive(:start)

      described_class.new.interpret(high_risk_context)
    end

    it 'does not require API keys' do
      explanation = described_class.new.interpret(high_risk_context)

      expect(explanation).not_to match(/api[_ -]?key/i)
      expect(explanation).not_to match(/sk-[a-zA-Z0-9]{8,}/)
    end

    it 'differs from DeterministicInterpreter output' do
      context = high_risk_context
      static_output = described_class.new.interpret(context)
      deterministic_output = Repo::Drift::Detector::DeterministicInterpreter.new.interpret(context)

      expect(static_output).not_to eq(deterministic_output)
      expect(static_output).to include('Signal brief:')
      expect(deterministic_output).to include('Repository risk is elevated')
    end

    it 'does not invent file names or architecture' do
      explanation = described_class.new.interpret(high_risk_context)

      expect(explanation).not_to match(/\.rb/)
      expect(explanation).not_to match(/\b(microservices|kubernetes|monolith)\b/i)
      expect(explanation).not_to match(/\bthe system (is|uses|implements)\b/i)
    end

    it 'includes PromptBuilder signal output' do
      explanation = described_class.new.interpret(high_risk_context)

      expect(explanation).to include('Explain repository risk based on these deterministic signals')
      expect(explanation).to include('- Risk level: high')
      expect(explanation).to include('- Production-only change: true')
    end
  end
end
