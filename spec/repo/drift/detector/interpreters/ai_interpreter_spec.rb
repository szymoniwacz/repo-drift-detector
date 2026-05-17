# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'repo/drift/detector/ai/configuration_error'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'
require 'repo/drift/detector/interpreters/ai_interpreter'

RSpec.describe Repo::Drift::Detector::Interpreters::AiInterpreter do
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

  def fake_client
    @fake_client ||= instance_double(Repo::Drift::Detector::Ai::OpenAiClient)
  end

  describe '#interpret' do
    it 'delegates a prompt built from PromptBuilder to the client' do
      allow(fake_client).to receive(:complete) do |prompt|
        expect(prompt).to include(Repo::Drift::Detector::PromptBuilder::INTRO)
        expect(prompt).to include('- Risk level: high')
        expect(prompt).to include('Write a concise explanation in an engineering tone.')
        expect(prompt).to include('Do not invent architecture')
        'AI explanation'
      end

      described_class.new(client: fake_client).interpret(high_risk_context)

      expect(fake_client).to have_received(:complete)
    end

    it 'returns the client response' do
      allow(fake_client).to receive(:complete).and_return('Elevated repository drift risk from OpenAI.')

      explanation = described_class.new(client: fake_client).interpret(high_risk_context)

      expect(explanation).to eq('Elevated repository drift risk from OpenAI.')
    end

    it 'does not call the real OpenAI client when a client is injected' do
      allow(fake_client).to receive(:complete).and_return('stubbed')
      allow(Repo::Drift::Detector::Ai::OpenAiClient).to receive(:new).and_raise('unexpected network client')

      described_class.new(client: fake_client).interpret(high_risk_context)
    end

    it 'requires OPENAI_API_KEY when using the real client' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('OPENAI_MODEL', anything).and_return('gpt-4o-mini')

      expect do
        described_class.new.interpret(high_risk_context)
      end.to raise_error(Repo::Drift::Detector::Ai::ConfigurationError, /OPENAI_API_KEY/)
    end

    it 'does not use Net::HTTP when a client is injected' do
      allow(fake_client).to receive(:complete).and_return('stubbed')

      expect(Net::HTTP).not_to receive(:start)

      described_class.new(client: fake_client).interpret(high_risk_context)
    end
  end
end
