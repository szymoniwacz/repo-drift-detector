# Testing

## Framework

RSpec is the test framework for this project.

## Testing Philosophy

### Test Deterministic Behavior First

Before integrating AI, all deterministic signals must be thoroughly tested:
- Git parsing logic
- Risk calculations
- File change detection
- Threshold comparisons

### Stub Shell/Git Calls

Prefer stubbing git commands over relying on real repository state:
- Tests should run anywhere (CI, local, containers)
- Tests should be fast and isolated
- Use `allow` and `expect` to mock command output

Example:
```ruby
describe Repo::Drift::Detector::Analyzer do
  describe '#changed_files' do
    it 'parses git diff output' do
      git_output = "app/main.rb\nlib/helper.rb\n"
      allow(analyzer).to receive(:`).with("git diff --name-only main") { git_output }

      result = analyzer.changed_files

      expect(result).to eq(['app/main.rb', 'lib/helper.rb'])
    end
  end
end
```

### Test Analyzers Independently

Test analyzer methods in isolation from CLI output formatting:
- Analyzers return structured data (hashes, arrays)
- Commands handle formatting
- No need to test through the CLI

Example:
```ruby
# ✅ Good: Test the analyzer directly
describe 'risk_level calculation' do
  it 'returns :low for 0-20 total changes' do
    # ... setup ...
    expect(analyzer.risk_level).to eq(:low)
  end
end

# ❌ Avoid: Testing through CLI output formatting
it 'prints risk level to stdout' do
  # Too coupled to formatting, brittle
end
```

## Test Organization

### File Structure

Specs mirror the lib structure:
```
lib/repo/drift/detector/analyzer.rb
spec/repo/drift/detector/analyzer_spec.rb

lib/repo/drift/detector/commands/analyze.rb
spec/repo/drift/detector/commands/analyze_spec.rb
```

### Describe Blocks

Use `describe` for classes and `context` for scenarios:

```ruby
RSpec.describe Repo::Drift::Detector::Analyzer do
  describe '#changed_files' do
    context 'when files have changed' do
      it 'returns an array of file paths' do
        # ...
      end
    end

    context 'when no files have changed' do
      it 'returns an empty array' do
        # ...
      end
    end
  end
end
```

### Setup

Use `let` blocks for shared setup:

```ruby
describe Repo::Drift::Detector::Analyzer do
  let(:analyzer) { described_class.new(base: 'main') }

  let(:git_numstat_output) do
    "10\t5\tapp/main.rb\n3\t2\tlib/helper.rb\n"
  end

  describe '#changed_file_stats' do
    before do
      allow(analyzer).to receive(:`).with("git diff --numstat main") { git_numstat_output }
    end

    it 'parses output into structured stats' do
      result = analyzer.changed_file_stats
      expect(result).to be_an(Array)
      expect(result.first).to include(file: 'app/main.rb', added: 10, removed: 5)
    end
  end
end
```

## Future: Testing AI Integration

When AI is added, follow these patterns:

### Use Adapters for External Services

```ruby
class AIAnalyzer
  def initialize(base_analyzer:, ai_adapter:)
    @base_analyzer = base_analyzer
    @ai_adapter = ai_adapter
  end

  def explain_risk
    signals = @base_analyzer.high_risk_files
    @ai_adapter.analyze(signals)
  end
end
```

### Test with Fakes, Not Real APIs

```ruby
describe AIAnalyzer do
  let(:fake_ai_adapter) do
    instance_double('AIAdapter', analyze: { explanation: 'Mock response' })
  end

  let(:ai_analyzer) do
    AIAnalyzer.new(base_analyzer: base_analyzer, ai_adapter: fake_ai_adapter)
  end

  it 'sends signals to AI adapter' do
    result = ai_analyzer.explain_risk
    expect(fake_ai_adapter).to have_received(:analyze).with(anything)
    expect(result).to include(:explanation)
  end
end
```

### No Network Access in Tests

- All external calls must be stubbed or mocked
- Tests must pass in environments with no internet access
- Use VCR or similar only for integration tests, not unit tests

## Running Tests

```bash
# Run all tests
mise exec -- bundle exec rspec

# Run specific file
mise exec -- bundle exec rspec spec/repo/drift/detector/analyzer_spec.rb

# Run with verbose output
mise exec -- bundle exec rspec --format documentation

# Run only failures
mise exec -- bundle exec rspec --only-failures
```

## Coverage

Aim for high deterministic test coverage:
- Target: 90%+ for analyzer layer
- Target: 70%+ for command/CLI layer (less critical as it's mostly formatting)
- Don't test view rendering details, test data computation

## Linting

Use RuboCop to enforce style:

```bash
# Check style
mise exec -- bundle exec rubocop

# Fix style issues
mise exec -- bundle exec rubocop -a
```
