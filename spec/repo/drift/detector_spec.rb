# frozen_string_literal: true

RSpec.describe Repo::Drift::Detector do
  it 'has a version number' do
    expect(Repo::Drift::Detector::VERSION).not_to be_nil
  end
end
