# frozen_string_literal: true

RSpec.describe Repo::Drift::Detector::Analyzer do
  let(:analyzer) { described_class.new(base: 'main') }

  describe '#changed_files' do
    it 'parses git diff --name-only output' do
      git_output = "app/main.rb\nlib/helper.rb\nconfig/database.yml\n"
      allow(analyzer).to receive(:`).with('git diff --name-only main') { git_output }

      result = analyzer.changed_files

      expect(result).to eq(['app/main.rb', 'lib/helper.rb', 'config/database.yml'])
    end

    it 'returns empty array when no files changed' do
      allow(analyzer).to receive(:`).with('git diff --name-only main') { '' }

      result = analyzer.changed_files

      expect(result).to eq([])
    end
  end

  describe '#changed_file_stats' do
    let(:git_numstat_output) do
      "10\t5\tapp/main.rb\n3\t2\tlib/helper.rb\n25\t10\tconfig/database.yml\n"
    end

    before do
      allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
    end

    it 'parses git diff --numstat output into structured stats' do
      result = analyzer.changed_file_stats

      expect(result).to be_an(Array)
      expect(result.length).to eq(3)
    end

    it 'includes file path in each stat' do
      result = analyzer.changed_file_stats

      expect(result[0][:file]).to eq('app/main.rb')
      expect(result[1][:file]).to eq('lib/helper.rb')
      expect(result[2][:file]).to eq('config/database.yml')
    end

    it 'parses added lines as integer' do
      result = analyzer.changed_file_stats

      expect(result[0][:added]).to eq(10)
      expect(result[1][:added]).to eq(3)
      expect(result[2][:added]).to eq(25)
    end

    it 'parses removed lines as integer' do
      result = analyzer.changed_file_stats

      expect(result[0][:removed]).to eq(5)
      expect(result[1][:removed]).to eq(2)
      expect(result[2][:removed]).to eq(10)
    end

    it 'calculates total_changes as sum of added and removed' do
      result = analyzer.changed_file_stats

      expect(result[0][:total_changes]).to eq(15)
      expect(result[1][:total_changes]).to eq(5)
      expect(result[2][:total_changes]).to eq(35)
    end
  end

  describe '#large_change_files' do
    let(:git_numstat_output) do
      "10\t5\tapp/main.rb\n3\t2\tlib/helper.rb\n25\t10\tconfig/database.yml\n"
    end

    before do
      allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
    end

    it 'returns only files with total_changes above threshold' do
      result = analyzer.large_change_files(threshold: 20)

      expect(result.length).to eq(1)
      expect(result[0][:file]).to eq('config/database.yml')
      expect(result[0][:total_changes]).to eq(35)
    end

    it 'uses default threshold of 20' do
      result = analyzer.large_change_files

      expect(result.length).to eq(1)
      expect(result[0][:file]).to eq('config/database.yml')
    end

    it 'includes files equal to threshold' do
      result = analyzer.large_change_files(threshold: 15)

      expect(result.length).to eq(2)
      expect(result.map { |s| s[:file] }).to include('app/main.rb', 'config/database.yml')
    end

    it 'returns empty array when no files exceed threshold' do
      result = analyzer.large_change_files(threshold: 100)

      expect(result).to be_empty
    end
  end

  describe '#high_risk_files' do
    it 'detects files containing "cli"' do
      git_output = "app/cli.rb\nlib/helper.rb\n"
      allow(analyzer).to receive(:`).with('git diff --name-only main') { git_output }

      result = analyzer.high_risk_files

      expect(result).to include('app/cli.rb')
    end

    it 'detects files containing "commands"' do
      git_output = "lib/commands/deploy.rb\nlib/helper.rb\n"
      allow(analyzer).to receive(:`).with('git diff --name-only main') { git_output }

      result = analyzer.high_risk_files

      expect(result).to include('lib/commands/deploy.rb')
    end

    it 'detects files containing "analyzer"' do
      git_output = "lib/analyzer.rb\nlib/helper.rb\n"
      allow(analyzer).to receive(:`).with('git diff --name-only main') { git_output }

      result = analyzer.high_risk_files

      expect(result).to include('lib/analyzer.rb')
    end

    it 'detects multiple high-risk file patterns in one file' do
      git_output = "lib/cli_commands.rb\nlib/helper.rb\n"
      allow(analyzer).to receive(:`).with('git diff --name-only main') { git_output }

      result = analyzer.high_risk_files

      expect(result).to include('lib/cli_commands.rb')
    end

    it 'returns only files matching risk patterns' do
      git_output = "app/models/user.rb\napp/views/index.html\nlib/cli.rb\n"
      allow(analyzer).to receive(:`).with('git diff --name-only main') { git_output }

      result = analyzer.high_risk_files

      expect(result).to eq(['lib/cli.rb'])
      expect(result).not_to include('app/models/user.rb')
      expect(result).not_to include('app/views/index.html')
    end

    it 'returns empty array when no high-risk files detected' do
      git_output = "app/models/user.rb\napp/views/index.html\n"
      allow(analyzer).to receive(:`).with('git diff --name-only main') { git_output }

      result = analyzer.high_risk_files

      expect(result).to be_empty
    end
  end

  describe '#risk_level' do
    context 'with 0-20 total changes' do
      let(:git_numstat_output) do
        "5\t3\tapp/main.rb\n2\t1\tlib/helper.rb\n"
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :low' do
        result = analyzer.risk_level

        expect(result).to eq(:low)
      end
    end

    context 'with exactly 20 total changes' do
      let(:git_numstat_output) do
        "15\t5\tapp/main.rb\n"
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :low' do
        result = analyzer.risk_level

        expect(result).to eq(:low)
      end
    end

    context 'with 21-100 total changes' do
      let(:git_numstat_output) do
        "30\t20\tapp/main.rb\n20\t10\tlib/helper.rb\n"
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :medium' do
        result = analyzer.risk_level

        expect(result).to eq(:medium)
      end
    end

    context 'with exactly 21 total changes' do
      let(:git_numstat_output) do
        "20\t1\tapp/main.rb\n"
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :medium' do
        result = analyzer.risk_level

        expect(result).to eq(:medium)
      end
    end

    context 'with exactly 100 total changes' do
      let(:git_numstat_output) do
        "50\t50\tapp/main.rb\n"
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :medium' do
        result = analyzer.risk_level

        expect(result).to eq(:medium)
      end
    end

    context 'with over 100 total changes' do
      let(:git_numstat_output) do
        "60\t50\tapp/main.rb\n30\t25\tlib/helper.rb\n"
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :high' do
        result = analyzer.risk_level

        expect(result).to eq(:high)
      end
    end

    context 'with exactly 101 total changes' do
      let(:git_numstat_output) do
        "50\t51\tapp/main.rb\n"
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :high' do
        result = analyzer.risk_level

        expect(result).to eq(:high)
      end
    end

    context 'with no changes' do
      let(:git_numstat_output) do
        ''
      end

      before do
        allow(analyzer).to receive(:`).with('git diff --numstat main') { git_numstat_output }
      end

      it 'returns :low' do
        result = analyzer.risk_level

        expect(result).to eq(:low)
      end
    end
  end
end
