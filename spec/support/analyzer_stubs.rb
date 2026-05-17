# frozen_string_literal: true

module AnalyzerStubs
  def stub_high_risk_analyzer
    large_change = { file: 'file2.rb', added: 2, removed: 1, total_changes: 3 }
    analyzer = Repo::Drift::Detector::Analyzer
    allow_any_instance_of(analyzer).to receive(:changed_file_count).and_return(2)
    allow_any_instance_of(analyzer).to receive(:changed_files).and_return(%w[file1.rb file2.rb])
    allow_any_instance_of(analyzer).to receive(:changed_file_stats).and_return([])
    allow_any_instance_of(analyzer).to receive(:large_change_files).and_return([large_change])
    allow_any_instance_of(analyzer).to receive(:documentation_files).and_return([])
    allow_any_instance_of(analyzer).to receive(:test_files).and_return([])
    allow_any_instance_of(analyzer).to receive(:production_files).and_return(%w[file1.rb file2.rb])
    allow_any_instance_of(analyzer).to receive(:unsafe_change_ratio).and_return(4.5)
    allow_any_instance_of(analyzer).to receive(:high_risk_files).and_return(%w[file2.rb])
    allow_any_instance_of(analyzer).to receive(:risk_level).and_return(:high)
    allow_any_instance_of(analyzer).to receive(:risk_reasons).and_return(['unsafe_change_ratio_above_threshold'])
    allow_any_instance_of(analyzer).to receive(:risk_score).and_return(92)
  end
end
