# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'
require 'repo/drift/detector/interpreters/deterministic_interpreter'
require 'repo/drift/detector/interpreters/static_ai_interpreter'

RSpec.describe Repo::Drift::Detector::Interpreters::StaticAiInterpreter do
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
    it 'returns deterministic output for the same input' do
      interpreter = described_class.new

      expect(interpreter.interpret(high_risk_context)).to eq(interpreter.interpret(high_risk_context))
    end

    it 'differs from DeterministicInterpreter output' do
      static_output = described_class.new.interpret(high_risk_context)
      deterministic_output = Repo::Drift::Detector::Interpreters::DeterministicInterpreter.new.interpret(high_risk_context)

      expect(static_output).not_to eq(deterministic_output)
      expect(static_output).to include('Assessed repository drift risk as high')
    end

    it 'builds an internal prompt without exposing it in the response' do
      builder = instance_double(Repo::Drift::Detector::PromptBuilder, build: 'INTERNAL PROMPT TEXT')
      allow(Repo::Drift::Detector::PromptBuilder).to receive(:new).and_return(builder)

      explanation = described_class.new.interpret(high_risk_context)

      expect(builder).to have_received(:build)
      expect(explanation).not_to include('INTERNAL PROMPT TEXT')
      expect(explanation).not_to include(Repo::Drift::Detector::PromptBuilder::INTRO)
    end

    it 'omits extended signal insights when signal_brief is false' do
      explanation = described_class.new.interpret(high_risk_context, signal_brief: false)

      expect(explanation).to include('Assessed repository drift risk as high')
      expect(explanation).not_to include('Taken together, the signals point to')
    end

    it 'does not call network APIs' do
      expect(Net::HTTP).not_to receive(:start)

      described_class.new.interpret(high_risk_context)
    end
  end
end
