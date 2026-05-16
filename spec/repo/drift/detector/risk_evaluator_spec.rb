# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/risk_evaluator'
require 'repo/drift/detector/config'

RSpec.describe Repo::Drift::Detector::RiskEvaluator do
  let(:signals_class) do
    Struct.new(:changed_file_stats, :unsafe_change_ratio, :high_risk_files)
  end

  let(:default_config) { Repo::Drift::Detector::Config.new(config_path: nil) }

  describe '#risk_level and #risk_reasons' do
    it 'returns low risk and no reasons when no thresholds are crossed' do
      signals = signals_class.new(
        [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }],
        0.0,
        []
      )
      ev = described_class.new(signals, default_config)

      expect(ev.risk_level).to eq(:low)
      expect(ev.risk_reasons).to eq([])
    end

    it 'returns medium risk when total changes exceed 20' do
      signals = signals_class.new(
        [{ file: 'f.rb', added: 21, removed: 0, total_changes: 21 }],
        0.0,
        []
      )
      ev = described_class.new(signals, default_config)

      expect(ev.risk_level).to eq(:medium)
      expect(ev.risk_reasons).to eq(['total_changes_above_20'])
    end

    it 'returns high risk when total changes exceed 100' do
      stats = [{ file: 'f.rb', added: 101, removed: 0, total_changes: 101 }]
      signals = signals_class.new(stats, 0.0, [])
      ev = described_class.new(signals, default_config)

      expect(ev.risk_level).to eq(:high)
      expect(ev.risk_reasons).to eq(%w[total_changes_above_100 total_changes_above_20])
    end

    it 'returns high risk when unsafe_change_ratio is at threshold' do
      signals = signals_class.new(
        [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }],
        3.0,
        []
      )
      ev = described_class.new(signals, default_config)

      expect(ev.risk_level).to eq(:high)
      expect(ev.risk_reasons).to eq(['unsafe_change_ratio_above_threshold'])
    end

    it 'returns medium risk when high-risk files are present without other triggers' do
      signals = signals_class.new(
        [{ file: 'lib/analyzer.rb', added: 1, removed: 0, total_changes: 1 }],
        0.0,
        ['lib/analyzer.rb']
      )
      ev = described_class.new(signals, default_config)

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

      signals = signals_class.new(
        [{ file: 'f.rb', added: 16, removed: 0, total_changes: 16 }],
        0.0,
        []
      )
      ev = described_class.new(signals, cfg)

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

      signals = signals_class.new(
        [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }],
        2.5,
        []
      )
      allow(signals).to receive(:large_change_files).and_return([])
      ev = described_class.new(signals, cfg)

      expect(ev.risk_level).to eq(:high)
      expect(ev.risk_reasons).to eq(['unsafe_change_ratio_above_threshold'])
    end

    it 'returns 0 risk score when no changes are present' do
      signals = signals_class.new([], 0.0, [])
      allow(signals).to receive(:large_change_files).and_return([])
      ev = described_class.new(signals, default_config)

      expect(ev.risk_score).to eq(0)
    end

    it 'increases risk score as total changes grow' do
      signals = signals_class.new(
        [{ file: 'f.rb', added: 60, removed: 30, total_changes: 90 }],
        0.0,
        []
      )
      allow(signals).to receive(:large_change_files).and_return([])
      ev = described_class.new(signals, default_config)

      expect(ev.risk_score).to be > 0
      expect(ev.risk_score).to eq(36)
    end

    it 'increases risk score as unsafe change ratio grows' do
      signals = signals_class.new(
        [{ file: 'f.rb', added: 1, removed: 1, total_changes: 2 }],
        1.5,
        []
      )
      allow(signals).to receive(:large_change_files).and_return([])
      ev = described_class.new(signals, default_config)

      expect(ev.risk_score).to eq(12)
    end

    it 'increases risk score for high-risk files' do
      signals = signals_class.new(
        [{ file: 'f.rb', added: 1, removed: 0, total_changes: 1 }],
        0.0,
        ['lib/analyzer.rb', 'lib/commands/foo.rb']
      )
      allow(signals).to receive(:large_change_files).and_return([])
      ev = described_class.new(signals, default_config)

      expect(ev.risk_score).to eq(20)
    end

    it 'increases risk score for large changes count' do
      signals = signals_class.new(
        [{ file: 'f.rb', added: 20, removed: 5, total_changes: 25 }],
        0.0,
        []
      )
      allow(signals).to receive(:large_change_files).and_return([{ file: 'f.rb', added: 20, removed: 5, total_changes: 25 }])
      ev = described_class.new(signals, default_config)

      expect(ev.risk_score).to eq(18)
    end

    it 'caps risk score at 100' do
      signals = signals_class.new(
        [
          { file: 'f1.rb', added: 1000, removed: 1000, total_changes: 2000 },
          { file: 'f2.rb', added: 1000, removed: 1000, total_changes: 2000 }
        ],
        10.0,
        ['lib/analyzer.rb', 'lib/commands/foo.rb', 'lib/commands/bar.rb']
      )
      allow(signals).to receive(:large_change_files).and_return([
        { file: 'f1.rb', added: 1000, removed: 1000, total_changes: 2000 },
        { file: 'f2.rb', added: 1000, removed: 1000, total_changes: 2000 }
      ])
      ev = described_class.new(signals, default_config)

      expect(ev.risk_score).to eq(100)
    end
  end
end
