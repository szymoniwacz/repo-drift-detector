# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/explanation/context'
require 'repo/drift/detector/explanation/prompt_builder'

RSpec.describe Repo::Drift::Detector::PromptBuilder do
  def low_risk_context
    Repo::Drift::Detector::ExplanationContext.new(
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

  describe '#build' do
    it 'includes the deterministic introduction' do
      prompt = described_class.new(low_risk_context).build

      expect(prompt).to start_with(
        'Explain repository risk based on these deterministic signals from a repository drift analysis.'
      )
    end

    it 'includes risk_level and risk_score' do
      prompt = described_class.new(low_risk_context).build

      expect(prompt).to include('- Risk level: low')
      expect(prompt).to include('- Risk score: 5')
    end

    it 'includes repository pattern values' do
      prompt = described_class.new(low_risk_context).build

      expect(prompt).to include('Repository patterns:')
      expect(prompt).to include('- Tests present: true')
      expect(prompt).to include('- Documentation updated: false')
      expect(prompt).to include('- Production-only change: false')
    end

    it 'says not to invent architecture' do
      prompt = described_class.new(low_risk_context).build

      expect(prompt).to include('Do not invent architecture, intent, or risks beyond the signals below.')
    end

    it 'accepts an ExplanationContext hash via ExplanationContext#to_h' do
      context_hash = low_risk_context.to_h
      prompt = described_class.new(context_hash).build

      expect(prompt).to include('- Risk level: low')
      expect(prompt).to include('- Tests present: true')
    end

    it 'is deterministic for the same input' do
      first = described_class.new(low_risk_context).build
      second = described_class.new(low_risk_context).build

      expect(first).to eq(second)
    end

    it 'describes a low-risk example' do
      prompt = described_class.new(low_risk_context).build

      expect(prompt).to include('- Risk level: low')
      expect(prompt).to include('- High risk file count: 0')
      expect(prompt).to include('- Large change count: 0')
    end

    it 'describes a high-risk example' do
      prompt = described_class.new(high_risk_context).build

      expect(prompt).to include('- Risk level: high')
      expect(prompt).to include('- Risk score: 92')
      expect(prompt).to include('- High risk file count: 3')
      expect(prompt).to include('- Large change count: 2')
      expect(prompt).to include('- Tests present: false')
      expect(prompt).to include('- Production-only change: true')
    end
  end
end
