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
  end
end
