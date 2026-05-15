# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/config'
require 'tmpdir'

RSpec.describe Repo::Drift::Detector::Config do
  describe '.load' do
    it 'uses defaults when the config file is missing' do
      Dir.mktmpdir do |dir|
        cfg = described_class.load(cwd: dir)
        expect(cfg.medium_change_threshold).to eq(20)
        expect(cfg.high_change_threshold).to eq(100)
        expect(cfg.unsafe_change_ratio_threshold).to eq(3.0)
      end
    end

    it 'loads thresholds from .repo-drift-detector.yml' do
      Dir.mktmpdir do |dir|
        File.write(
          File.join(dir, described_class::FILENAME),
          File.read(File.expand_path('../../../fixtures/repo-drift-detector/thresholds.yml', __dir__))
        )
        cfg = described_class.load(cwd: dir)
        expect(cfg.medium_change_threshold).to eq(15)
        expect(cfg.high_change_threshold).to eq(90)
        expect(cfg.unsafe_change_ratio_threshold).to eq(2.5)
      end
    end

    it 'raises ConfigError on invalid YAML' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, described_class::FILENAME)
        File.write(path, "{not valid\n")
        expect { described_class.load(cwd: dir) }.to raise_error(
          Repo::Drift::Detector::ConfigError, /invalid YAML/
        )
      end
    end

    it 'raises when risk is not a mapping' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, described_class::FILENAME)
        File.write(path, "risk: not_a_hash\n")
        expect { described_class.load(cwd: dir) }.to raise_error(
          Repo::Drift::Detector::ConfigError, /risk must be a mapping/
        )
      end
    end

    it 'raises non-positive integer thresholds' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, described_class::FILENAME)
        File.write(path, <<~YAML)
          risk:
            medium_change_threshold: 0
        YAML
        expect { described_class.load(cwd: dir) }.to raise_error(
          Repo::Drift::Detector::ConfigError, /medium_change_threshold must be a positive integer/
        )
      end
    end

    it 'raises when high is not greater than medium' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, described_class::FILENAME)
        File.write(path, <<~YAML)
          risk:
            medium_change_threshold: 50
            high_change_threshold: 50
        YAML
        expect { described_class.load(cwd: dir) }.to raise_error(
          Repo::Drift::Detector::ConfigError, /high_change_threshold must be greater than medium_change_threshold/
        )
      end
    end
  end

  describe 'defaults via new(config_path: nil)' do
    it 'matches documented default thresholds' do
      cfg = described_class.new(config_path: nil)
      expect(cfg.medium_change_threshold).to eq(20)
      expect(cfg.high_change_threshold).to eq(100)
      expect(cfg.unsafe_change_ratio_threshold).to eq(3.0)
    end
  end
end
