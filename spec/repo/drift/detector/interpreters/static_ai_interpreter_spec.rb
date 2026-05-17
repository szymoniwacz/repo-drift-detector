# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'repo/drift/detector/ai_response_composer'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'
require 'repo/drift/detector/interpreters/deterministic_interpreter'
require 'repo/drift/detector/interpreters/static_ai_interpreter'

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

  def forbidden_prompt_fragments
    [
      Repo::Drift::Detector::PromptBuilder::INTRO,
      Repo::Drift::Detector::PromptBuilder::CONSTRAINT,
      'Signal brief:',
      'Signals:',
      'Repository patterns:',
      '- Risk level:',
      '- Production-only change:'
    ]
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
      expect(explanation).to include('The diff touches 8 file(s)')
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
      expect(static_output).to include('Assessed repository drift risk as high')
      expect(deterministic_output).to include('Repository risk is elevated')
    end

    it 'does not invent file names or architecture' do
      explanation = described_class.new.interpret(high_risk_context)

      expect(explanation).not_to match(/\.rb/)
      expect(explanation).not_to match(/\b(microservices|kubernetes|monolith)\b/i)
      expect(explanation).not_to match(/\bthe system (is|uses|implements)\b/i)
    end

    it 'delegates response composition to AiResponseComposer' do
      composer = instance_double(
        Repo::Drift::Detector::AiResponseComposer,
        compose: Repo::Drift::Detector::AiResponseComposer.new(high_risk_context).compose
      )
      allow(Repo::Drift::Detector::AiResponseComposer).to receive(:new).and_return(composer)

      explanation = described_class.new.interpret(high_risk_context)

      expect(Repo::Drift::Detector::AiResponseComposer).to have_received(:new).with(a_hash_including(risk_level: 'high'))
      expect(composer).to have_received(:compose).with(include_signal_insights: true)
      expect(explanation).to include('Assessed repository drift risk as high')
    end

    it 'matches AiResponseComposer output for wording stability' do
      expected = Repo::Drift::Detector::AiResponseComposer.new(high_risk_context).compose

      expect(described_class.new.interpret(high_risk_context)).to eq(expected)
    end

    it 'uses PromptBuilder internally without exposing its output' do
      builder = instance_double(Repo::Drift::Detector::PromptBuilder, build: 'INTERNAL PROMPT TEXT')
      allow(Repo::Drift::Detector::PromptBuilder).to receive(:new).and_return(builder)

      explanation = described_class.new.interpret(high_risk_context)

      expect(builder).to have_received(:build)
      expect(explanation).not_to include('INTERNAL PROMPT TEXT')
    end

    it 'passes signal_brief to AiResponseComposer as include_signal_insights' do
      composer = instance_double(Repo::Drift::Detector::AiResponseComposer, compose: 'short explanation')
      allow(Repo::Drift::Detector::AiResponseComposer).to receive(:new).and_return(composer)
      allow(Repo::Drift::Detector::PromptBuilder).to receive(:new).and_return(
        instance_double(Repo::Drift::Detector::PromptBuilder, build: 'internal')
      )

      described_class.new.interpret(high_risk_context, signal_brief: false)

      expect(composer).to have_received(:compose).with(include_signal_insights: false)
    end
  end
end
