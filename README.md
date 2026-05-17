# repo-drift-detector

**repo-drift-detector** summarizes how much a Git branch has diverged from a base ref and assigns a simple **risk level** (low / medium / high) with **machine-readable** output. It is meant for code review and automation: you get a structured view of scope, file mix, and heuristics—not just a raw file list.

## Why not “just git diff”

The tool still uses Git to discover what changed, but it **interprets** that diff:

- Groups paths into **documentation**, **test**, and **production**-style files
- **Numstat**-style totals per file, **large-change** detection (configurable threshold)
- An **unsafe change ratio** (production vs test file counts)
- **High-risk file** hints (paths touching sensitive areas, e.g. CLI/commands/analyzer)
- A **risk tier**, **`risk_score`** (0–100), and **`risk_reasons`** from thresholds in **`.repo-drift-detector.yml`**

So the output is closer to a small drift report than `git diff --stat`.

## Architecture

```
lib/repo/drift/detector/
├── analyzer.rb              # Git diff + file categorization + risk metrics
├── risk_evaluator.rb        # risk_level, risk_score, risk_reasons from thresholds
├── config.rb                # .repo-drift-detector.yml
├── commands/
│   ├── analyze.rb           # analyze CLI
│   ├── explain.rb           # explain CLI (argv, output file, exit codes)
│   └── explain_runner.rb    # explain workflow: analysis → interpreters → render
├── explanation/
│   ├── context.rb           # compact signal hash for explanations
│   ├── comparison.rb        # side-by-side deterministic vs static-ai text
│   ├── prompt_builder.rb    # internal prompt text (not shown to users)
│   └── ai_response_composer.rb  # user-visible static-ai wording
├── interpreters/                     # Repo::Drift::Detector::Interpreters
│   ├── deterministic_interpreter.rb  # rule-based explanation
│   ├── static_ai_interpreter.rb      # offline “AI-style” explanation
│   └── ai_interpreter.rb             # OpenAI-backed explanation (network)
└── renderers/
    ├── text_renderer.rb     # analyze text report
    ├── json_renderer.rb     # JSON formatting
    ├── explanation_renderer.rb       # deterministic explanation body
    ├── explanation_markdown_renderer.rb
    ├── comparison_text_renderer.rb
    └── comparison_markdown_renderer.rb
```

| Layer | Responsibility |
|-------|----------------|
| **Commands** | Parse CLI flags, load config, write stdout/files, exit codes |
| **Analyzer** | Run git diff, categorize files, compute change stats |
| **RiskEvaluator** | Map metrics to risk level, score, and reason codes |
| **ExplanationContext** | Normalize `summary` into explanation inputs |
| **Interpreters** | Turn context into explanation **text** |
| **Renderers** | Format text for CLI: plain, JSON, or markdown |

### Interpreters

- **`deterministic`** (default): rule-based narrative from observable file-change signals (`ExplanationRenderer`). No network.
- **`static-ai`**: offline, **fully deterministic** “AI-style” prose (`AiResponseComposer`). Uses `PromptBuilder` internally to stay grounded in signals but **does not** print prompt templates or instructions. No network, no API keys, no LLM.
- **`ai`**: real OpenAI-backed explanation via `Ai::OpenAiClient` (Chat Completions). Requires **`OPENAI_API_KEY`**; optional **`OPENAI_MODEL`** (default `gpt-4o-mini`). Makes a network call; output is not deterministic. Missing or invalid configuration exits **2** with a clear stderr message.

### Compare mode

`explain --compare` runs **both** interpreters on the same signals and prints deterministic text, static-ai text, and short comparison notes. JSON uses a `comparison` object instead of top-level `explanation` / `interpreter`.

## Installation

```ruby
gem 'repo-drift-detector'
```

```bash
gem install repo-drift-detector
```

From a clone, use your Ruby toolchain (this repo uses **mise**):

```bash
mise exec -- bundle install
```

## Commands

Entry point:

```bash
mise exec -- bundle exec exe/repo-drift-detector <command> [options]
```

| Command | Purpose |
|---------|---------|
| `analyze` | Full drift report (file lists, stats, risk level, reasons, score) |
| `explain` | Explanation of repository risk from the same signals |

**`--base`** is the Git ref to compare against (e.g. `main`, `origin/main`). **`--goal`** is optional metadata copied into JSON (branch name, ticket, etc.).

Output formats: **`text`** (default), **`json`**, and for **`explain`** only **`markdown`**.

### Examples

```bash
# Analyze (text)
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --goal my-branch --base main

# Analyze (JSON)
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --goal my-branch --base main --format json

# Explain (deterministic text)
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main

# Explain (static-ai, still offline and deterministic)
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main --interpreter static-ai

# Explain (OpenAI; requires OPENAI_API_KEY)
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main --interpreter ai

# Compare both interpreters
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main --compare

# Write markdown report to a file
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main --format markdown --output report.md
```

---

## `analyze`

```bash
mise exec -- bundle exec exe/repo-drift-detector analyze [--goal <label>] --base <ref> [options]
```

Options:

- **`--format json`** — JSON report on stdout (pretty-printed)
- **`--output <path>`** — write the report to a file; stdout shows `Analysis written to <path>`
- **`--fail-on low|medium|high`** — exit **1** when risk is at or above that level (after writing `--output`, if set)

### JSON output (example)

Top-level fields include the full analysis plus a compact **`summary`** object:

```json
{
  "goal": "my-branch",
  "base": "main",
  "changed_file_count": 2,
  "risk_level": "medium",
  "risk_score": 27,
  "summary": {
    "risk_level": "medium",
    "risk_score": 27,
    "changed_file_count": 2,
    "production_file_count": 1,
    "test_file_count": 1,
    "documentation_file_count": 0,
    "unsafe_change_ratio": 0.0,
    "high_risk_file_count": 0,
    "large_change_count": 0
  }
}
```

---

## `explain`

```bash
mise exec -- bundle exec exe/repo-drift-detector explain [--goal <label>] --base <ref> [options]
```

Options:

- **`--format json`** — full analysis JSON plus **`interpreter`** and **`explanation`** (single mode)
- **`--format markdown`** — markdown sections for explanation or compare output
- **`--output <path>`** — write report to a file; stdout shows `Explanation written to <path>`
- **`--interpreter deterministic|static-ai|ai`** — default `deterministic`
- **`--compare`** — show deterministic and static-ai explanations with comparison notes (cannot combine with `--interpreter`)

Invalid `--interpreter` values exit **2**; valid values: `deterministic`, `static-ai`, `ai`.

### Single-mode JSON (example)

```json
{
  "goal": "my-branch",
  "base": "main",
  "risk_level": "high",
  "summary": { "...": "..." },
  "interpreter": "deterministic",
  "explanation": "Repository risk is elevated based on the current deterministic file-change signals.\n\n..."
}
```

### Compare mode

Text output uses `=== Deterministic explanation ===`, `=== Static AI explanation ===`, and `=== Comparison notes ===`. JSON includes:

```json
{
  "comparison": {
    "deterministic": "...",
    "static_ai": "...",
    "notes": [
      "deterministic explanation is more signal-oriented",
      "static-ai explanation is more interpretive"
    ]
  }
}
```

---

## Configuration

Optional repo-local file **`.repo-drift-detector.yml`**:

```yaml
risk:
  medium_change_threshold: 20
  high_change_threshold: 100
  unsafe_change_ratio_threshold: 3.0
```

`high_change_threshold` must be **greater than** `medium_change_threshold`. Invalid YAML or bad values make commands exit **2**.

## CI and drift artifacts

On **pull requests** and **pushes to `main`**, GitHub Actions runs RSpec, RuboCop, then:

```bash
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --base "$BASE" \
  --format json \
  --output drift-report.json
```

The workflow uploads **`drift-report.json`** as artifact **`repo-drift-report`**.

## Development

```bash
bin/setup
mise exec -- bundle exec rspec
mise exec -- bundle exec rubocop
```

Specs mirror `lib/` where practical: `spec/repo/drift/detector/commands/`, `interpreters/`, `explanation/`, `renderers/`.

## Contributing

Issues and pull requests are welcome.

## License

MIT. See [MIT License](https://opensource.org/licenses/MIT).
