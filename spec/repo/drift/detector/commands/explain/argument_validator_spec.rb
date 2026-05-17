# frozen_string_literal: true

require 'spec_helper'
require 'repo/drift/detector/commands/explain'
require 'stringio'

RSpec.describe Repo::Drift::Detector::Commands::Explain::ArgumentValidator do
  describe '#validate' do
    it 'allows a valid --interpreter value' do
      argv = ['--goal', 'g', '--base', 'main', '--interpreter', 'static-ai']

      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'allows argv without --interpreter' do
      argv = ['--goal', 'g', '--base', 'main']

      expect { described_class.new(argv).validate }.not_to raise_error
    end

    it 'exits 2 and warns when --interpreter value is invalid' do
      argv = ['--goal', 'g', '--base', 'main', '--interpreter', 'ai']

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

      expect(stderr_io.string).to include("Invalid --interpreter value 'ai'")
      expect(stderr_io.string).to include('static-ai')
    end

    it 'exits 2 when --compare is combined with --interpreter' do
      argv = ['--goal', 'g', '--base', 'main', '--compare', '--interpreter', 'deterministic']

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

      expect(stderr_io.string).to include('--interpreter cannot be used with --compare')
    end

    it 'exits 2 and warns when --interpreter is missing a value' do
      argv = ['--goal', 'g', '--base', 'main', '--interpreter']

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

      expect(stderr_io.string).to include('Invalid --interpreter')
    end
  end
end
