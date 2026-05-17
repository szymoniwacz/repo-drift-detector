# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/explanation/context'

RSpec.describe Repo::Drift::Detector::ExplanationContext do
  def low_risk_summary
    {
      risk_level: :low,
      risk_score: 5,
      changed_file_count: 1,
      production_file_count: 1,
      test_file_count: 1,
      documentation_file_count: 0,
      unsafe_change_ratio: 1.0,
      high_risk_file_count: 0,
      large_change_count: 0
    }
  end

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

  describe '#to_h' do
    it 'returns expected keys' do
      keys = described_class.new(low_risk_summary).to_h.keys

      expect(keys).to contain_exactly(
        :risk_level,
        :risk_score,
        :changed_file_count,
        :production_file_count,
        :test_file_count,
        :documentation_file_count,
        :unsafe_change_ratio,
        :high_risk_file_count,
        :large_change_count,
        :repository_patterns
      )
    end

    it 'exposes the expected signal structure' do
      context = described_class.new(low_risk_summary)

      expect(context.to_h).to include(
        risk_level: 'low',
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

    it 'includes repository_patterns' do
      context = described_class.new(low_risk_summary)

      expect(context.to_h[:repository_patterns]).to eq(
        tests_present: true,
        documentation_updated: false,
        production_only_change: false
      )
    end

    it 'accepts string keys from JSON summary data' do
      summary = low_risk_summary.transform_keys(&:to_s)
      context = described_class.new(summary)

      expect(context.to_h[:risk_level]).to eq('low')
      expect(context.to_h[:changed_file_count]).to eq(1)
    end
  end

  describe 'repository_patterns' do
    it 'computes repository_patterns correctly for mixed changes' do
      patterns = described_class.new(low_risk_summary).to_h[:repository_patterns]

      expect(patterns).to eq(
        tests_present: true,
        documentation_updated: false,
        production_only_change: false
      )
    end

    it 'sets production_only_change to true when only production files changed' do
      summary = high_risk_summary.merge(
        production_file_count: 3,
        test_file_count: 0,
        documentation_file_count: 0
      )
      patterns = described_class.new(summary).to_h[:repository_patterns]

      expect(patterns).to eq(
        tests_present: false,
        documentation_updated: false,
        production_only_change: true
      )
    end

    it 'sets production_only_change to false when test files changed' do
      patterns = described_class.new(low_risk_summary).to_h[:repository_patterns]

      expect(patterns[:tests_present]).to be(true)
      expect(patterns[:production_only_change]).to be(false)
    end

    it 'sets production_only_change to false when documentation files changed' do
      summary = low_risk_summary.merge(
        production_file_count: 2,
        test_file_count: 0,
        documentation_file_count: 1
      )
      patterns = described_class.new(summary).to_h[:repository_patterns]

      expect(patterns[:documentation_updated]).to be(true)
      expect(patterns[:production_only_change]).to be(false)
    end

    it 'returns false patterns when no categorized files changed' do
      summary = low_risk_summary.merge(
        changed_file_count: 0,
        production_file_count: 0,
        test_file_count: 0,
        documentation_file_count: 0
      )
      patterns = described_class.new(summary).to_h[:repository_patterns]

      expect(patterns).to eq(
        tests_present: false,
        documentation_updated: false,
        production_only_change: false
      )
    end
  end
end
