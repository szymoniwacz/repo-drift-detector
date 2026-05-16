# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/risk_evaluator'
require 'repo/drift/detector/config'

RSpec.describe Repo::Drift::Detector::RiskEvaluator do
  let(:signals_class) do
    Struct.new(:changed_file_stats, :unsafe_change_ratio, :high_risk_files, :large_change_files)
  end

  def signals(stats:, ratio: 0.0, high_risk: [], large_changes: [])
    signals_class.new(stats, ratio, high_risk, large_changes)
  end

  let(:default_config) { Repo::Drift::Detector::Config.new(config_path: nil) }

  describe '#risk_level and #risk_reasons' do
    it 'returns low risk and no reasons when no thresholds are crossed' do
      ev = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }]),
        default_config
      )

      expect(ev.risk_level).to eq(:low)
      expect(ev.risk_reasons).to eq([])
    end

    it 'returns medium risk when total changes exceed 20' do
      ev = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 21, removed: 0, total_changes: 21 }]),
        default_config
      )

      expect(ev.risk_level).to eq(:medium)
      expect(ev.risk_reasons).to eq(['total_changes_above_20'])
    end

    it 'returns high risk when total changes exceed 100' do
      ev = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 101, removed: 0, total_changes: 101 }]),
        default_config
      )

      expect(ev.risk_level).to eq(:high)
      expect(ev.risk_reasons).to eq(%w[total_changes_above_100 total_changes_above_20])
    end

    it 'returns high risk when unsafe_change_ratio is at threshold' do
      ev = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }], ratio: 3.0),
        default_config
      )

      expect(ev.risk_level).to eq(:high)
      expect(ev.risk_reasons).to eq(['unsafe_change_ratio_above_threshold'])
    end

    it 'returns medium risk when high-risk files are present without other triggers' do
      ev = described_class.new(
        signals(
          stats: [{ file: 'lib/analyzer.rb', added: 1, removed: 0, total_changes: 1 }],
          high_risk: ['lib/analyzer.rb']
        ),
        default_config
      )

      expect(ev.risk_level).to eq(:medium)
      expect(ev.risk_reasons).to eq(['high_risk_files_detected'])
    end

    it 'uses custom medium threshold for reasons and tier' do
      cfg = instance_double(
        Repo::Drift::Detector::Config,
        medium_change_threshold: 15,
        high_change_threshold: 100,
        unsafe_change_ratio_threshold: 3.0
      )

      ev = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 16, removed: 0, total_changes: 16 }]),
        cfg
      )

      expect(ev.risk_level).to eq(:medium)
      expect(ev.risk_reasons).to eq(['total_changes_above_15'])
    end

    it 'uses custom unsafe ratio threshold' do
      cfg = instance_double(
        Repo::Drift::Detector::Config,
        medium_change_threshold: 20,
        high_change_threshold: 100,
        unsafe_change_ratio_threshold: 2.5
      )

      ev = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }], ratio: 2.5),
        cfg
      )

      expect(ev.risk_level).to eq(:high)
      expect(ev.risk_reasons).to eq(['unsafe_change_ratio_above_threshold'])
    end
  end

  describe '#risk_score' do
    it 'returns 0 when there are no changes or risk signals' do
      ev = described_class.new(signals(stats: []), default_config)

      expect(ev.risk_score).to eq(0)
    end

    it 'increases as total changed lines grow' do
      low = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 10, removed: 0, total_changes: 10 }]),
        default_config
      )
      high = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 50, removed: 0, total_changes: 50 }]),
        default_config
      )

      expect(low.risk_score).to be < high.risk_score
    end

    it 'increases as unsafe_change_ratio grows' do
      low = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }], ratio: 0.5),
        default_config
      )
      high = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }], ratio: 2.5),
        default_config
      )

      expect(low.risk_score).to be < high.risk_score
    end

    it 'increases as high_risk_files count grows' do
      low = described_class.new(
        signals(stats: [{ file: 'a.rb', added: 1, removed: 0, total_changes: 1 }], high_risk: ['a.rb']),
        default_config
      )
      high = described_class.new(
        signals(
          stats: [{ file: 'a.rb', added: 1, removed: 0, total_changes: 1 }],
          high_risk: %w[a.rb b.rb c.rb]
        ),
        default_config
      )

      expect(low.risk_score).to be < high.risk_score
    end

    it 'increases as large_changes count grows' do
      stat = { file: 'f.rb', added: 25, removed: 0, total_changes: 25 }
      low = described_class.new(
        signals(stats: [stat], large_changes: [stat]),
        default_config
      )
      high = described_class.new(
        signals(
          stats: [stat, stat, stat],
          large_changes: [stat, stat, stat]
        ),
        default_config
      )

      expect(low.risk_score).to be < high.risk_score
    end

    it 'caps the score at 100' do
      stats = [{ file: 'f.rb', added: 500, removed: 500, total_changes: 1000 }]
      large = stats
      ev = described_class.new(
        signals(
          stats: stats,
          ratio: 5.0,
          high_risk: %w[a.rb b.rb c.rb d.rb e.rb],
          large_changes: [large, large, large, large]
        ),
        default_config
      )

      expect(ev.risk_score).to eq(100)
    end

    it 'assigns lower scores to low-risk signals than medium-risk signals' do
      low = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }]),
        default_config
      )
      medium = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 25, removed: 0, total_changes: 25 }]),
        default_config
      )

      expect(low.risk_score).to be < medium.risk_score
    end

    it 'assigns lower scores to medium-risk signals than high-risk signals' do
      medium = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 25, removed: 0, total_changes: 25 }]),
        default_config
      )
      high = described_class.new(
        signals(stats: [{ file: 'f.rb', added: 150, removed: 0, total_changes: 150 }], ratio: 3.0),
        default_config
      )

      expect(medium.risk_score).to be < high.risk_score
    end
  end
end
