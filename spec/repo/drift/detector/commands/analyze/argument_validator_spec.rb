# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/commands/analyze'
require 'stringio'

RSpec.describe Repo::Drift::Detector::Commands::Analyze::ArgumentValidator do
  describe '#validate' do
    it 'allows a valid --fail-on value' do
      argv = ['--goal', 'g', '--base', 'main', '--fail-on', 'high']
      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'allows argv without --fail-on' do
      argv = ['--goal', 'g', '--base', 'main']
      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'allows argv without --format' do
      argv = ['--goal', 'g', '--base', 'main']
      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'allows --format json' do
      argv = ['--goal', 'g', '--base', 'main', '--format', 'json']
      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'exits 2 and warns when --format value is invalid' do
      argv = ['--goal', 'g', '--base', 'main', '--format', 'yaml']

      stderr_io = StringIO.new
      old_stderr = $stderr
      $stderr = stderr_io
      begin
        expect { described_class.new(argv).validate }.to raise_error(SystemExit) do |err|
          expect(err.status).to eq(2)
        end
      ensure
        $stderr = old_stderr
      end

      expect(stderr_io.string).to include("Invalid --format value 'yaml'")
      expect(stderr_io.string).to include('json')
    end

    it 'exits 2 and warns when --fail-on value is invalid' do
      argv = ['--goal', 'g', '--base', 'main', '--fail-on', 'critical']

      stderr_io = StringIO.new
      old_stderr = $stderr
      $stderr = stderr_io
      begin
        expect { described_class.new(argv).validate }.to raise_error(SystemExit) do |err|
          expect(err.status).to eq(2)
        end
      ensure
        $stderr = old_stderr
      end

      expect(stderr_io.string).to include("Invalid --fail-on value 'critical'")
      expect(stderr_io.string).to include('low')
    end

    it 'allows argv with a valid --output path' do
      argv = ['--goal', 'g', '--base', 'main', '--output', 'report.txt']
      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'allows argv without --output' do
      argv = ['--goal', 'g', '--base', 'main']
      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'exits 2 and warns when --output is missing a path' do
      argv = ['--goal', 'g', '--base', 'main', '--output']

      stderr_io = StringIO.new
      old_stderr = $stderr
      $stderr = stderr_io
      begin
        expect { described_class.new(argv).validate }.to raise_error(SystemExit) do |err|
          expect(err.status).to eq(2)
        end
      ensure
        $stderr = old_stderr
      end

      expect(stderr_io.string).to include('Invalid --output')
    end

    it 'exits 2 and warns when --output value is another flag' do
      argv = ['--goal', 'g', '--base', 'main', '--output', '--format']

      stderr_io = StringIO.new
      old_stderr = $stderr
      $stderr = stderr_io
      begin
        expect { described_class.new(argv).validate }.to raise_error(SystemExit) do |err|
          expect(err.status).to eq(2)
        end
      ensure
        $stderr = old_stderr
      end

      expect(stderr_io.string).to include('Invalid --output')
    end
  end
end
