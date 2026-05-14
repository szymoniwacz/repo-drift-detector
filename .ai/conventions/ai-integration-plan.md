# AI Integration Plan

## Current State

The project currently contains **deterministic analysis only**:
- Git parsing (diffs, file stats)
- Risk level calculations (based on change volume)
- High-risk file detection (pattern matching)
- No external API calls
- No network dependencies
- No AI models

## Why Not Yet?

Before AI integration:
1. **Deterministic signals must be stable** - All analysis logic is predictable and testable
2. **Deterministic signals must be well-tested** - See `testing.md` for test patterns
3. **Architecture must support adapters** - External services must be behind interfaces
4. **Team must understand baseline** - AI enhancement only makes sense when baseline is clear

## Planned AI Layer Flow

```
User runs CLI
  ↓
Git diff → parsed files and stats (deterministic)
  ↓
Analyzer computes risk signals (deterministic)
  ↓
Command formats deterministic output (deterministic)
  ↓
[Future: AI interpretation layer] (non-deterministic)
  ├─ Sends risk signals to AI service
  ├─ Receives explanation and recommendations
  └─ Formats AI insights for output
  ↓
User sees: deterministic signals + AI explanation
```

## What AI Should Do

### Goals
- **Explain** why code is risky (not just flag it)
- **Recommend** architectural improvements (not mutate code)
- **Learn** from repository patterns and conventions
- **Assist** engineers in understanding drift

### What AI Should NOT Do
- **Mutate code** - AI output should be explanatory, not executable
- **Replace deterministic signals** - AI interprets them, doesn't replace them
- **Require network** - Tests and core logic work offline
- **Live in low-level analyzers** - Keep analyzers deterministic and testable

## Implementation Strategy

### Phase 1: Foundation (Current)
✅ Deterministic analyzer layer
✅ CLI command orchestration
✅ RSpec test suite
✅ Documentation and conventions

### Phase 2: Adapter Interface (Future)
- Create `Repo::Drift::Detector::AIAdapter` interface
- Define contract: accepts risk signals, returns interpretation
- Implement fake/mock adapter for testing
- Add configuration for AI service selection

Example structure:
```ruby
module Repo
  module Drift
    module Detector
      module AI
        # Interface
        class Adapter
          def interpret_risks(signals)
            raise NotImplementedError
          end
        end

        # Implementations
        class FakeAdapter < Adapter
          # For testing
        end

        class OpenAIAdapter < Adapter
          # Future: Real OpenAI integration
        end
      end
    end
  end
end
```

### Phase 3: Command Integration (Future)
- Update `Commands::Analyze` to optionally accept `--with-ai` flag
- Instantiate appropriate adapter based on configuration
- Pass deterministic signals to adapter
- Format and display AI interpretation

Example:
```ruby
def call
  print_deterministic_signals  # Always run

  if use_ai?
    ai_interpretation = ai_adapter.interpret_risks(signals)
    print_ai_interpretation(ai_interpretation)
  end
end
```

### Phase 4: Testing AI Behavior (Future)
- All AI tests use fake adapters, NO real API calls
- Test that signals flow correctly to adapter
- Test output formatting of AI responses
- Mock external services completely

```ruby
describe 'AI integration' do
  let(:fake_ai) { instance_double('AIAdapter') }

  it 'sends signals to AI adapter' do
    # No real API call
    allow(fake_ai).to receive(:interpret_risks) { { explanation: 'Test' } }
    # ... test expectations ...
  end
end
```

## Decision Points for Future

When implementing AI integration, make these decisions:

1. **Which AI service?** (OpenAI, Anthropic, local model, etc.)
2. **Configuration method?** (env vars, config file, flags)
3. **Output format?** (JSON, text, markdown)
4. **Caching strategy?** (cache AI responses? invalidation policy?)
5. **Error handling?** (fail gracefully if AI service unavailable?)
6. **Cost management?** (rate limiting, token budgets)

## Non-Goals

These are explicitly OUT OF SCOPE for future phases:

- ❌ Mutating code based on AI suggestions
- ❌ Automatic fixing or refactoring
- ❌ Direct integration with code editors
- ❌ Real-time continuous monitoring
- ❌ Training custom models
- ❌ Multi-turn conversations
- ❌ User authentication/billing
- ❌ Chatbot interface

## Architecture Principles to Maintain

1. **Determinism First**: All non-AI analysis is deterministic and testable
2. **Adapter Pattern**: External services are behind interfaces
3. **No Network in Tests**: Unit tests have zero network calls
4. **Layering**: CLI → Commands → Deterministic Analyzer → (Future: AI Adapter)
5. **Small Methods**: Keep everything readable and composable
6. **Clear Separation**: AI output must be clearly labeled as "AI interpretation"

## Rollout Considerations

When AI is ready to integrate:

1. **Feature Flag**: Add `--with-ai` flag to keep it optional
2. **Gradual Adoption**: Let users opt-in before requiring it
3. **Documentation**: Update README with AI configuration
4. **Examples**: Show sample AI output and format
5. **Testing**: Comprehensive test coverage with mocked services
6. **Monitoring**: Track API costs and response quality

## Questions to Revisit

- How should deterministic signals and AI interpretation be weighted?
- Should AI suggestions be cached or always fresh?
- How to handle AI service unavailability gracefully?
- What logging/telemetry is needed for AI behavior?
- How to collect feedback on AI quality?
