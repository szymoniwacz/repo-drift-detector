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
| `explain` | Short deterministic explanation of repository risk from the same signals |

**`--base`** is the Git ref to compare against (e.g. `main`, `origin/main`). **`--goal`** is optional metadata copied into JSON (branch name, ticket, etc.). CI in this repo usually passes only **`--base`**.

Supported output formats: **`text`** (default) and **`json`**. There is no `--format markdown`; use JSON and render elsewhere if you need Markdown.

---

## `analyze`

```bash
mise exec -- bundle exec exe/repo-drift-detector analyze [--goal <label>] --base <ref> [options]
```

Options:

- **`--format json`** — JSON report on stdout (pretty-printed)
- **`--output <path>`** — write the report to a file; stdout shows `Analysis written to <path>`
- **`--fail-on low|medium|high`** — exit **1** when risk is at or above that level (after writing `--output`, if set)

Examples:

```bash
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --goal my-branch --base main

mise exec -- bundle exec exe/repo-drift-detector analyze \
  --goal my-branch --base main --format json --output drift-report.json
```

### Text output (example)

```text
Analyzing repository drift...
Goal: my-branch
Base: main

Changed file count: 2
...
Risk level: medium
Risk score: 27

Risk reasons:
- total_changes_above_20
```

### JSON output (example)

Top-level fields include the full analysis plus a compact **`summary`** object for automation and downstream explanation:

```json
{
  "goal": "my-branch",
  "base": "main",
  "changed_file_count": 2,
  "changed_files": ["lib/widget.rb", "spec/widget_spec.rb"],
  "change_stats": [
    {"file": "lib/widget.rb", "added": 12, "removed": 3, "total_changes": 15}
  ],
  "large_changes": [],
  "documentation_files": [],
  "test_files": ["spec/widget_spec.rb"],
  "production_files": ["lib/widget.rb"],
  "unsafe_change_ratio": 0.0,
  "high_risk_files": [],
  "risk_level": "medium",
  "risk_reasons": ["total_changes_above_20"],
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

Exact values depend on your repo and config.

---

## `explain`

```bash
mise exec -- bundle exec exe/repo-drift-detector explain [--goal <label>] --base <ref> [options]
```

Produces a concise **explanation** from the same analyzer signals as `analyze`. Default output is plain text (the explanation only). JSON includes the full analysis payload, an **`explanation`** string, and which interpreter ran.

Options:

- **`--format json`** — same fields as `analyze` JSON, plus **`interpreter`** and **`explanation`**
- **`--output <path>`** — write report to a file; stdout shows `Explanation written to <path>`
- **`--interpreter deterministic`** (default) — rule-based narrative via `ExplanationRenderer`
- **`--interpreter static-ai`** — offline “AI-style” text built from `PromptBuilder` signal briefs (**not** a real LLM)

### Interpreters

| Value | What it is |
|-------|------------|
| `deterministic` (default) | Rule-based explanation from observable signals only |
| `static-ai` | Deterministic placeholder that formats signals like an AI brief; no network, no API keys |
| `ai` | **Invalid** today — reserved for a future real provider integration |

Invalid `--interpreter` values exit **2** with a message listing valid options: `deterministic`, `static-ai`.

Examples:

```bash
# Default deterministic explanation on stdout
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main

# JSON with interpreter metadata
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main --format json

# Offline static-ai style (still deterministic, no network)
mise exec -- bundle exec exe/repo-drift-detector explain \
  --goal my-branch --base main --interpreter static-ai
```

### `explain` JSON (example)

```json
{
  "goal": "my-branch",
  "base": "main",
  "risk_level": "high",
  "risk_score": 92,
  "summary": { "...": "..." },
  "interpreter": "deterministic",
  "explanation": "Repository risk is elevated based on the current deterministic file-change signals.\n\n..."
}
```

With **`--interpreter static-ai`**, `"interpreter": "static-ai"` and the explanation includes a structured **Signal brief:** section (bullet lists of counts and patterns)—still plain text, not Markdown export.

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

## Contributing

Issues and pull requests are welcome.

## License

MIT. See [MIT License](https://opensource.org/licenses/MIT).
