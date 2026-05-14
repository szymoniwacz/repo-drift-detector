# Project Structure

## Overview
`repo-drift-detector` is a Ruby gem designed as AI engineering reliability tooling. It detects repository drift, architectural risk, and maintainability signals in AI-assisted code changes. It is NOT a generic git diff wrapper.

## Key Directories

### `exe/repo-drift-detector`
CLI entrypoint. Responsible for:
- Parsing command-line arguments
- Invoking appropriate command classes
- Handling user interaction and output formatting

### `lib/repo/drift/detector/`
Core library structure:
- `analyzer.rb` - Deterministic analysis engine
- `commands/` - Command orchestration layer
- `version.rb` - Gem versioning

### `lib/repo/drift/detector/commands/`
Command orchestration classes. Each command:
- Parses CLI arguments
- Creates appropriate analyzer instances
- Formats and renders output
- NOT responsible for core analysis logic

### `lib/repo/drift/detector/analyzer.rb`
Core deterministic analyzer. Responsible for:
- Parsing git output (diffs, stats)
- Computing risk signals
- Returning structured data about changes
- NO output formatting (that's the command's job)
- NO direct AI calls (prepared for future integration)

## Layering

```
CLI (exe/) -> Commands (lib/commands/) -> Analyzer (lib/analyzer/)
              ↓ receives structured data ↓
              ↓ formats for output ↓
```

- **CLI**: Entry point, argument parsing
- **Commands**: Orchestration, output formatting, user interaction
- **Analyzer**: Pure deterministic logic, git parsing, risk calculation

## Future AI Integration

AI should be added ONLY after deterministic signals are stable. The planned flow is:

```
git diff → deterministic analyzer → structured risk summary → AI interpretation
```

Key principles:
- AI layer interprets signals, does not replace them
- API calls live behind adapter interfaces
- AI output explains risks, does not mutate code
- Tests must not require network access
- Low-level analyzer methods must remain free of AI calls

## Architecture Principles

1. **Separation of Concerns**: Git parsing, analysis, and output formatting are distinct layers
2. **Testability**: Deterministic behavior is tested before AI integration
3. **Determinism**: Analyzer methods depend only on git data and configuration
4. **No Hidden State**: Avoid global state in analyzers
5. **Small Methods**: Prefer composition over complex logic
6. **Interface-Based Integration**: Future adapters allow testing without external services
