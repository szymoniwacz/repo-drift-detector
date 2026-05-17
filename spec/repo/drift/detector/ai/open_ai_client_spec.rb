# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/ai/configuration_error'
require 'repo/drift/detector/ai/open_ai_client'

RSpec.describe Repo::Drift::Detector::Ai::OpenAiClient do
  describe '#complete' do
    it 'raises ConfigurationError when OPENAI_API_KEY is missing' do
      client = described_class.new(api_key: nil)

      expect { client.complete('prompt') }.to raise_error(
        Repo::Drift::Detector::Ai::ConfigurationError,
        /OPENAI_API_KEY is not set/
      )
    end

    it 'raises ConfigurationError when OPENAI_API_KEY is blank' do
      client = described_class.new(api_key: '   ')

      expect { client.complete('prompt') }.to raise_error(
        Repo::Drift::Detector::Ai::ConfigurationError,
        /OPENAI_API_KEY is not set/
      )
    end

    it 'returns explanation text from a successful API response' do
      payload_json = {
        choices: [{ message: { content: "  Elevated repository drift risk.\n" } }]
      }.to_json
      response = Net::HTTPOK.new('1.1', '200', 'OK')
      allow(response).to receive(:body).and_return(payload_json)
      http = instance_double(Net::HTTP, request: response)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      explanation = described_class.new(api_key: 'test-key').complete('Explain repository risk.')

      expect(explanation).to eq('Elevated repository drift risk.')
    end

    it 'raises ConfigurationError when the API response is not successful' do
      response = Net::HTTPBadRequest.new('1.1', '400', 'Bad Request')
      allow(response).to receive(:body).and_return('{"error":"bad request"}')
      http = instance_double(Net::HTTP, request: response)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      expect do
        described_class.new(api_key: 'test-key').complete('prompt')
      end.to raise_error(Repo::Drift::Detector::Ai::ConfigurationError, /OpenAI request failed/)
    end
  end
end
