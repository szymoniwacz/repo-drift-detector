# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'repo/drift/detector/analyzer'

RSpec.describe Repo::Drift::Detector::Analyzer do
  describe '#changed_files' do
    it 'parses git diff --name-only output' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_call_original
      allow(analyzer).to receive(:`).with('git diff --name-only main').and_return("file1.rb\nfile2.rb\nfile3.rb")

      expect(analyzer.changed_files).to eq(['file1.rb', 'file2.rb', 'file3.rb'])
    end

    it 'handles single file' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_call_original
      allow(analyzer).to receive(:`).with('git diff --name-only main').and_return('single_file.rb')

      expect(analyzer.changed_files).to eq(['single_file.rb'])
    end
  end

  describe '#changed_file_count' do
    it 'returns the count of changed files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['file1.rb', 'file2.rb', 'file3.rb'])

      expect(analyzer.changed_file_count).to eq(3)
    end

    it 'returns 0 when no files changed' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([])

      expect(analyzer.changed_file_count).to eq(0)
    end

    it 'returns 1 for a single changed file' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['single.rb'])

      expect(analyzer.changed_file_count).to eq(1)
    end
  end

  describe '#documentation_files' do
    it 'detects README.md' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['README.md', 'lib/helper.rb'])

      doc_files = analyzer.documentation_files
      expect(doc_files).to include('README.md')
      expect(doc_files).not_to include('lib/helper.rb')
    end

    it 'detects files in docs/ directory' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['docs/guide.md', 'docs/setup.txt', 'lib/code.rb'])

      doc_files = analyzer.documentation_files
      expect(doc_files).to include('docs/guide.md', 'docs/setup.txt')
      expect(doc_files).not_to include('lib/code.rb')
    end

    it 'detects files ending with .md' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['CONTRIBUTING.md', 'CHANGELOG.md', 'lib/code.rb'])

      doc_files = analyzer.documentation_files
      expect(doc_files).to include('CONTRIBUTING.md', 'CHANGELOG.md')
      expect(doc_files).not_to include('lib/code.rb')
    end

    it 'returns empty array when there are no doc files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['lib/code.rb', 'spec/code_spec.rb'])

      doc_files = analyzer.documentation_files
      expect(doc_files).to be_empty
    end

    it 'handles multiple doc files mixed with code files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([
                                                              'README.md',
                                                              'docs/install.md',
                                                              'lib/main.rb',
                                                              'CHANGELOG.md',
                                                              'lib/helper.rb'
                                                            ])

      doc_files = analyzer.documentation_files
      expect(doc_files.count).to eq(3)
      expect(doc_files).to include('README.md', 'docs/install.md', 'CHANGELOG.md')
    end

    it 'returns empty array when no files changed' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([])

      doc_files = analyzer.documentation_files
      expect(doc_files).to be_empty
    end

    it 'does not match .md in middle of filename' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['src/readme_helper.rb'])

      doc_files = analyzer.documentation_files
      expect(doc_files).to be_empty
    end

    it 'detects nested docs directories' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['docs/api/endpoints.md', 'docs/guides/setup.md'])

      doc_files = analyzer.documentation_files
      expect(doc_files).to include('docs/api/endpoints.md', 'docs/guides/setup.md')
    end
  end

  describe '#test_files' do
    it 'detects files starting with spec/' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['spec/code_spec.rb', 'lib/code.rb'])

      test_files = analyzer.test_files
      expect(test_files).to include('spec/code_spec.rb')
      expect(test_files).not_to include('lib/code.rb')
    end

    it 'detects files containing /spec/' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['lib/spec/helper_spec.rb', 'lib/code.rb'])

      test_files = analyzer.test_files
      expect(test_files).to include('lib/spec/helper_spec.rb')
      expect(test_files).not_to include('lib/code.rb')
    end

    it 'detects files starting with test/' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['test/code_test.rb', 'lib/code.rb'])

      test_files = analyzer.test_files
      expect(test_files).to include('test/code_test.rb')
      expect(test_files).not_to include('lib/code.rb')
    end

    it 'detects files ending with _spec.rb' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['helper_spec.rb', 'lib/code.rb'])

      test_files = analyzer.test_files
      expect(test_files).to include('helper_spec.rb')
      expect(test_files).not_to include('lib/code.rb')
    end

    it 'returns empty array when there are no test files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['lib/code.rb', 'lib/helper.rb'])

      test_files = analyzer.test_files
      expect(test_files).to be_empty
    end

    it 'handles multiple test files mixed with code files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([
                                                              'spec/code_spec.rb',
                                                              'lib/main.rb',
                                                              'test/helper_test.rb',
                                                              'lib/helper.rb',
                                                              'helper_spec.rb'
                                                            ])

      test_files = analyzer.test_files
      expect(test_files.count).to eq(3)
      expect(test_files).to include('spec/code_spec.rb', 'test/helper_test.rb', 'helper_spec.rb')
    end

    it 'returns empty array when no files changed' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([])

      test_files = analyzer.test_files
      expect(test_files).to be_empty
    end

    it 'detects deeply nested spec files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['lib/api/spec/endpoint_spec.rb'])

      test_files = analyzer.test_files
      expect(test_files).to include('lib/api/spec/endpoint_spec.rb')
    end

    it 'does not match _spec.rb in middle of filename' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['lib/spec_helper_code.rb'])

      test_files = analyzer.test_files
      expect(test_files).to be_empty
    end
  end

  describe '#production_files' do
    it 'includes code files and excludes test files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['lib/code.rb', 'spec/code_spec.rb'])
      allow(analyzer).to receive(:documentation_files).and_return([])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb'])

      prod_files = analyzer.production_files
      expect(prod_files).to include('lib/code.rb')
      expect(prod_files).not_to include('spec/code_spec.rb')
    end

    it 'includes code files and excludes documentation files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['lib/code.rb', 'README.md'])
      allow(analyzer).to receive(:documentation_files).and_return(['README.md'])
      allow(analyzer).to receive(:test_files).and_return([])

      prod_files = analyzer.production_files
      expect(prod_files).to include('lib/code.rb')
      expect(prod_files).not_to include('README.md')
    end

    it 'excludes both test and documentation files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([
                                                              'lib/code.rb',
                                                              'spec/code_spec.rb',
                                                              'README.md'
                                                            ])
      allow(analyzer).to receive(:documentation_files).and_return(['README.md'])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb'])

      prod_files = analyzer.production_files
      expect(prod_files.count).to eq(1)
      expect(prod_files).to include('lib/code.rb')
    end

    it 'returns empty array when all files are test or doc' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['spec/code_spec.rb', 'README.md'])
      allow(analyzer).to receive(:documentation_files).and_return(['README.md'])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb'])

      prod_files = analyzer.production_files
      expect(prod_files).to be_empty
    end

    it 'returns empty array when no files changed' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([])
      allow(analyzer).to receive(:documentation_files).and_return([])
      allow(analyzer).to receive(:test_files).and_return([])

      prod_files = analyzer.production_files
      expect(prod_files).to be_empty
    end

    it 'handles multiple production files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([
                                                              'lib/main.rb',
                                                              'lib/helper.rb',
                                                              'lib/utils.rb',
                                                              'spec/code_spec.rb',
                                                              'README.md'
                                                            ])
      allow(analyzer).to receive(:documentation_files).and_return(['README.md'])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb'])

      prod_files = analyzer.production_files
      expect(prod_files.count).to eq(3)
      expect(prod_files).to include('lib/main.rb', 'lib/helper.rb', 'lib/utils.rb')
    end
  end

  describe '#unsafe_change_ratio' do
    it 'returns 0.0 when there are no production files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:production_files).and_return([])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb'])

      expect(analyzer.unsafe_change_ratio).to eq(0.0)
    end

    it 'returns prod_count when there are no test files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:production_files).and_return(['lib/code.rb', 'lib/helper.rb'])
      allow(analyzer).to receive(:test_files).and_return([])

      expect(analyzer.unsafe_change_ratio).to eq(2.0)
    end

    it 'returns ratio when both production and test files exist' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:production_files).and_return(['lib/code.rb'])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb', 'spec/helper_spec.rb'])

      expect(analyzer.unsafe_change_ratio).to eq(0.5)
    end

    it 'handles equal production and test file counts' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:production_files).and_return(['lib/code.rb', 'lib/helper.rb'])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb', 'spec/helper_spec.rb'])

      expect(analyzer.unsafe_change_ratio).to eq(1.0)
    end

    it 'handles more production files than test files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:production_files).and_return([
                                                                 'lib/code.rb',
                                                                 'lib/helper.rb',
                                                                 'lib/utils.rb'
                                                               ])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb'])

      expect(analyzer.unsafe_change_ratio).to eq(3.0)
    end

    it 'returns ratio as float' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:production_files).and_return(['lib/code.rb', 'lib/helper.rb', 'lib/utils.rb'])
      allow(analyzer).to receive(:test_files).and_return(['spec/code_spec.rb', 'spec/helper_spec.rb'])

      ratio = analyzer.unsafe_change_ratio
      expect(ratio).to be_a(Float)
      expect(ratio).to eq(1.5)
    end

    it 'returns 0.0 when both production and test files are empty' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:production_files).and_return([])
      allow(analyzer).to receive(:test_files).and_return([])

      expect(analyzer.unsafe_change_ratio).to eq(0.0)
    end
  end

  describe '#changed_file_stats' do
    it 'parses git diff --numstat output' do
      output = "10\t5\tfile1.rb\n20\t10\tfile2.rb"
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_call_original
      allow(analyzer).to receive(:`).with('git diff --numstat main').and_return(output)

      stats = analyzer.changed_file_stats
      expect(stats.count).to eq(2)
      expect(stats[0]).to eq({
                               file: 'file1.rb',
                               added: 10,
                               removed: 5,
                               total_changes: 15
                             })
      expect(stats[1]).to eq({
                               file: 'file2.rb',
                               added: 20,
                               removed: 10,
                               total_changes: 30
                             })
    end

    it 'converts added and removed values to integers' do
      output = "100\t50\tconfig.yml"
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_call_original
      allow(analyzer).to receive(:`).with('git diff --numstat main').and_return(output)

      stats = analyzer.changed_file_stats
      expect(stats[0][:added]).to be_an(Integer)
      expect(stats[0][:removed]).to be_an(Integer)
      expect(stats[0][:added]).to eq(100)
      expect(stats[0][:removed]).to eq(50)
    end

    it 'calculates total_changes correctly' do
      output = "7\t3\tfile.rb"
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_call_original
      allow(analyzer).to receive(:`).with('git diff --numstat main').and_return(output)

      stats = analyzer.changed_file_stats
      expect(stats[0][:total_changes]).to eq(10)
    end

    it 'returns empty array when output is empty' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_call_original
      allow(analyzer).to receive(:`).with('git diff --numstat main').and_return('')

      stats = analyzer.changed_file_stats
      expect(stats).to eq([])
    end

    it 'handles zero additions and removals' do
      output = "0\t0\tbinary_file.bin"
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_call_original
      allow(analyzer).to receive(:`).with('git diff --numstat main').and_return(output)

      stats = analyzer.changed_file_stats
      expect(stats[0][:total_changes]).to eq(0)
    end
  end

  describe '#large_change_files' do
    it 'returns only files with total_changes >= threshold' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'small.rb', added: 10, removed: 5,
                                                                     total_changes: 15 },
                                                                   { file: 'large.rb', added: 50, removed: 30,
                                                                     total_changes: 80 },
                                                                   { file: 'medium.rb', added: 15, removed: 10,
                                                                     total_changes: 25 }
                                                                 ])

      large = analyzer.large_change_files(threshold: 20)
      expect(large.count).to eq(2)
      expect(large.map { |f| f[:file] }).to include('large.rb', 'medium.rb')
    end

    it 'respects custom threshold' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file1.rb', added: 10, removed: 5,
                                                                     total_changes: 15 },
                                                                   { file: 'file2.rb', added: 25, removed: 15,
                                                                     total_changes: 40 },
                                                                   { file: 'file3.rb', added: 50, removed: 50,
                                                                     total_changes: 100 }
                                                                 ])

      large = analyzer.large_change_files(threshold: 50)
      expect(large.count).to eq(1)
      expect(large[0][:file]).to eq('file3.rb')
    end

    it 'uses default threshold of 20' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file1.rb', added: 15, removed: 5,
                                                                     total_changes: 20 },
                                                                   { file: 'file2.rb', added: 25, removed: 10,
                                                                     total_changes: 35 }
                                                                 ])

      large = analyzer.large_change_files
      expect(large.count).to eq(2)
    end

    it 'returns empty array when no file matches' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file1.rb', added: 5, removed: 2,
                                                                     total_changes: 7 },
                                                                   { file: 'file2.rb', added: 8, removed: 3,
                                                                     total_changes: 11 }
                                                                 ])

      large = analyzer.large_change_files(threshold: 50)
      expect(large).to be_empty
    end

    it 'includes files at exact threshold boundary' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file1.rb', added: 10, removed: 10,
                                                                     total_changes: 20 },
                                                                   { file: 'file2.rb', added: 20, removed: 0,
                                                                     total_changes: 20 }
                                                                 ])

      large = analyzer.large_change_files(threshold: 20)
      expect(large.count).to eq(2)
    end
  end

  describe '#high_risk_files' do
    it 'detects files containing "cli"' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['cli_helper.rb', 'regular_file.rb'])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to include('cli_helper.rb')
    end

    it 'detects files containing "commands"' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['commands/analyze.rb', 'lib/helper.rb'])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to include('commands/analyze.rb')
    end

    it 'detects files containing "analyzer"' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['analyzer.rb', 'spec/helper_spec.rb'])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to include('analyzer.rb')
      expect(high_risk).not_to include('spec/helper_spec.rb')
    end

    it 'ignores unrelated files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['README.md', 'config.yaml', 'spec/helper_spec.rb'])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to be_empty
    end

    it 'handles multiple high-risk files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['cli.rb', 'commands/base.rb', 'analyzer.rb',
                                                             'spec/other_spec.rb'])

      high_risk = analyzer.high_risk_files
      expect(high_risk.count).to eq(3)
      expect(high_risk).to include('cli.rb', 'commands/base.rb', 'analyzer.rb')
    end

    it 'returns empty array when there are no changed files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to be_empty
    end

    it 'does not count test files as high risk' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([
        'lib/repo/drift/detector/analyzer.rb',
        'lib/repo/drift/detector/commands/analyze.rb',
        'spec/repo/drift/detector/analyzer_spec.rb'
      ])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to include('lib/repo/drift/detector/analyzer.rb',
                                   'lib/repo/drift/detector/commands/analyze.rb')
      expect(high_risk).not_to include('spec/repo/drift/detector/analyzer_spec.rb')
    end

    it 'does not count documentation files as high risk' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return([
        'docs/analyzer_guide.md',
        'lib/repo/drift/detector/commands/analyze.rb'
      ])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to include('lib/repo/drift/detector/commands/analyze.rb')
      expect(high_risk).not_to include('docs/analyzer_guide.md')
    end

    it 'returns empty array when there are no high-risk files' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_files).and_return(['README.md', 'LICENSE.txt', 'Gemfile'])

      high_risk = analyzer.high_risk_files
      expect(high_risk).to be_empty
    end
  end

  describe '#risk_level' do
    it 'returns :low for 0 changes' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 0, removed: 0,
                                                                     total_changes: 0 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:low)
    end

    it 'returns :low for 20 total changes with no other risk factors' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 10, removed: 10,
                                                                     total_changes: 20 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:low)
    end

    it 'returns :medium for 21 total changes' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 15, removed: 6,
                                                                     total_changes: 21 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:medium)
    end

    it 'returns :medium for 100 total changes' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file1.rb', added: 60, removed: 40,
                                                                     total_changes: 100 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:medium)
    end

    it 'returns :high for 101 total changes' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file1.rb', added: 60, removed: 50,
                                                                     total_changes: 110 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:high)
    end

    it 'returns :high for large number of changes' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'large_file.rb', added: 500, removed: 500,
                                                                     total_changes: 1000 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:high)
    end

    it 'returns :low when no changes' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:low)
    end

    it 'returns :high when unsafe_change_ratio >= 3.0' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 5, removed: 5,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(3.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:high)
    end

    it 'returns :high when unsafe_change_ratio > 3.0' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 5, removed: 5,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(5.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:high)
    end

    it 'returns :medium when unsafe_change_ratio < 3.0 and changes > 20' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 15, removed: 6,
                                                                     total_changes: 21 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(1.5)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:medium)
    end

    it 'returns :medium when high_risk_files exist' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'lib/analyzer.rb', added: 5, removed: 5,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return(['lib/analyzer.rb'])

      expect(analyzer.risk_level).to eq(:medium)
    end

    it 'returns :low when changes <= 20 and no high risk files and ratio < 3.0' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 8, removed: 2,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.5)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_level).to eq(:low)
    end
  end

  describe '#risk_reasons' do
    it 'returns empty array for low risk' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 10, removed: 10,
                                                                     total_changes: 20 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq([])
    end

    it 'returns medium reasons for total_changes_above_20 only' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 15, removed: 6,
                                                                     total_changes: 21 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(1.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq(['total_changes_above_20'])
    end

    it 'returns medium reasons for high_risk_files_detected only' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'lib/analyzer.rb', added: 5, removed: 5,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return(['lib/analyzer.rb'])

      expect(analyzer.risk_reasons).to eq(['high_risk_files_detected'])
    end

    it 'returns high reasons including total_changes_above_100' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file1.rb', added: 60, removed: 50,
                                                                     total_changes: 110 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq(
        %w[total_changes_above_100 total_changes_above_20]
      )
    end

    it 'returns high reasons for unsafe_change_ratio_above_threshold' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 5, removed: 5,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(3.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq(['unsafe_change_ratio_above_threshold'])
    end

    it 'lists multiple reasons when several conditions match' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'lib/commands/foo.rb', added: 80, removed: 80,
                                                                     total_changes: 160 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(4.0)
      allow(analyzer).to receive(:high_risk_files).and_return(['lib/commands/foo.rb'])

      expect(analyzer.risk_reasons).to eq(
        %w[
          total_changes_above_100
          unsafe_change_ratio_above_threshold
          total_changes_above_20
          high_risk_files_detected
        ]
      )
    end

    it 'does not include total_changes_above_20 at exactly 20 changes boundary' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 20, removed: 0,
                                                                     total_changes: 20 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq([])
    end

    it 'includes total_changes_above_20 just above 20 changes boundary' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 21, removed: 0,
                                                                     total_changes: 21 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq(['total_changes_above_20'])
    end

    it 'does not include total_changes_above_100 at exactly 100 total changes boundary' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 100, removed: 0,
                                                                     total_changes: 100 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq(['total_changes_above_20'])
    end

    it 'includes total_changes_above_100 just above 100 total changes boundary' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 101, removed: 0,
                                                                     total_changes: 101 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq(
        %w[total_changes_above_100 total_changes_above_20]
      )
    end

    it 'does not include unsafe_change_ratio reason below threshold boundary' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 5, removed: 5,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(2.999)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq([])
    end

    it 'includes unsafe_change_ratio reason at threshold boundary' do
      analyzer = described_class.new(base: 'main')
      allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                   { file: 'file.rb', added: 5, removed: 5,
                                                                     total_changes: 10 }
                                                                 ])
      allow(analyzer).to receive(:unsafe_change_ratio).and_return(3.0)
      allow(analyzer).to receive(:high_risk_files).and_return([])

      expect(analyzer.risk_reasons).to eq(['unsafe_change_ratio_above_threshold'])
    end

    it 'uses thresholds from a loaded config file' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, Repo::Drift::Detector::Config::FILENAME), <<~YAML)
          risk:
            medium_change_threshold: 15
            high_change_threshold: 90
            unsafe_change_ratio_threshold: 3.0
        YAML
        config = Repo::Drift::Detector::Config.load(cwd: dir)
        analyzer = described_class.new(base: 'main', config: config)
        allow(analyzer).to receive(:changed_file_stats).and_return([
                                                                     { file: 'file.rb', added: 16, removed: 0,
                                                                       total_changes: 16 }
                                                                   ])
        allow(analyzer).to receive(:unsafe_change_ratio).and_return(0.0)
        allow(analyzer).to receive(:high_risk_files).and_return([])

        expect(analyzer.risk_reasons).to eq(['total_changes_above_15'])
      end
    end
  end
end
