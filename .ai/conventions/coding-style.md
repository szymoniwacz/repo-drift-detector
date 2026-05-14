# Coding Style

## Ruby Code Principles

### Small, Explicit, Readable
- Methods should have a single responsibility
- Prefer clarity over cleverness
- Extract complex logic into named helper methods
- Names should reveal intent

### Method Length
- Prefer methods under 15 lines
- Break long methods into smaller, named pieces
- Each method should fit on a screen without scrolling

### Naming
- Use descriptive names for variables and methods
- Avoid abbreviations except for common conventions (e.g., `attr_reader`)
- Method names should describe what they do or return

Example of good style:
```ruby
def large_change_files(threshold: 20)
  changed_file_stats.select do |stat|
    stat[:total_changes] >= threshold
  end
end
```

## Command Classes

Command classes orchestrate work and handle output:
- Responsible for: parsing arguments, formatting output, user interaction
- NOT responsible for: complex analysis logic
- Use dependency injection (pass analyzer as collaborator)
- Keep orchestration simple and readable

Example:
```ruby
class Analyze
  def initialize(argv)
    @argv = argv
  end

  def call
    print_changed_files
    print_risk_level
  end

  private

  def analyzer
    @analyzer ||= Analyzer.new(base: base)
  end

  def print_changed_files
    puts 'Changed files:'
    analyzer.changed_files.each { |file| puts "- #{file}" }
  end
end
```

## Analyzer Classes

Analyzer classes compute deterministic signals:
- Responsible for: data parsing, risk calculations, returning structured data
- NOT responsible for: output formatting, AI calls, user interaction
- Return hashes or simple structures (no view objects)
- Avoid side effects

Example:
```ruby
class Analyzer
  def initialize(base:)
    @base = base
  end

  def changed_file_stats
    `git diff --numstat #{@base}`.split("\n").map do |line|
      added, removed, file = line.split("\t")
      {
        file: file,
        added: added.to_i,
        removed: removed.to_i,
        total_changes: added.to_i + removed.to_i
      }
    end
  end
end
```

## Anti-Patterns to Avoid

### Hidden Global State
❌ Bad:
```ruby
class Analyzer
  def self.base=(value)
    @@base = value
  end

  def changed_files
    `git diff --name-only #{@@base}`.split("\n")
  end
end
```

✅ Good:
```ruby
class Analyzer
  def initialize(base:)
    @base = base
  end

  def changed_files
    `git diff --name-only #{@base}`.split("\n")
  end
end
```

### Large Methods
❌ Bad:
```ruby
def analyze
  # 50+ lines of logic
end
```

✅ Good:
```ruby
def analyze
  stats = calculate_stats
  risk = assess_risk(stats)
  format_output(risk)
end

private

def calculate_stats
  # 10 lines
end

def assess_risk(stats)
  # 10 lines
end
```

### Direct AI Calls in Low-Level Methods
❌ Bad (prepared for future refactor):
```ruby
class Analyzer
  def high_risk_files
    # NO: Don't call OpenAI here
    response = OpenAI.analyze(changed_files)
    response.high_risk_files
  end
end
```

✅ Good:
```ruby
class Analyzer
  def high_risk_files
    changed_files.select do |file|
      file.include?('cli') || file.include?('commands')
    end
  end
end

# Future: AI layer wraps or extends this
class AIAnalyzer
  def initialize(base_analyzer:, ai_client:)
    @base_analyzer = base_analyzer
    @ai_client = ai_client
  end

  def enhanced_risk_files
    base_files = @base_analyzer.high_risk_files
    @ai_client.analyze(base_files)
  end
end
```

## Testing Style

See `testing.md` for RSpec conventions and test structure.

## Code Organization

- One class per file (unless very small related classes)
- File paths match namespace hierarchy
- Require statements at top of file
- `# frozen_string_literal: true` at top of every Ruby file
- Use private methods for internal implementation details
