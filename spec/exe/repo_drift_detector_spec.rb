# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'repo-drift-detector executable' do
  let(:exe) { File.expand_path('../../exe/repo-drift-detector', __dir__) }

  def run_cli(*args)
    Open3.capture3(RbConfig.ruby, exe, *args)
  end

  it 'shows usage when no command is given' do
    stdout, _stderr, status = run_cli

    expect(status.exitstatus).to eq(2)
    expect(stdout).to include('repo-drift-detector')
    expect(stdout).to include('analyze')
    expect(stdout).to include('explain')
    expect(stdout).to include('Usage:')
  end

  it 'shows usage for an unknown command' do
    stdout, stderr, status = run_cli('unknown')

    expect(status.exitstatus).to eq(2)
    expect(stderr).to include('Unknown command: unknown')
    expect(stdout).to include('Usage:')
  end
end
