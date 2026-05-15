# repo-drift-detector

**repo-drift-detector** summarizes how much a Git branch has diverged from a base ref and assigns a simple **risk level** (low / medium / high) with **machine-readable** output. It is meant for code review and automation: you get a structured view of scope, file mix, and heuristics—not just a raw file list.

## Why not “just git diff”

The tool still uses Git to discover what changed, but it **interprets** that diff:

- Groups paths into **documentation**, **test**, and **production**-style files  
- **Numstat**-style totals per file, **large-change** detection (configurable threshold)  
- An **unsafe change ratio** (production vs test file counts)  
- **High-risk file** hints (paths touching sensitive areas, e.g. CLI/commands/analyzer)  
- A **risk tier** and **`risk_reasons`** derived from thresholds in **`.repo-drift-detector.yml`**

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

## Usage

Entry point:

```bash
mise exec -- bundle exec exe/repo-drift-detector analyze [--goal <label>] --base <ref> [options]
```

**`--base`** is the Git ref to compare against (e.g. `main`, `origin/main`). **`--goal`** is optional; when set, it is copied into the report (e.g. branch or ticket). CI in this repo omits **`--goal`** and only passes **`--base`**.

Default output is **text** to stdout. Add **`--format json`** for JSON. Add **`--output path`** to write the report to a file; stdout then shows `Analysis written to path`.

Examples:

```bash
# Text report on stdout
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --goal my-branch --base main

# JSON on stdout
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --goal my-branch --base main --format json

# JSON file + confirmation line on stdout
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --goal my-branch --base main --format json --output drift-report.json
```

### Text output (example)

Illustrative shape of the default report:

```text
Analyzing repository drift...
Goal: my-branch
Base: main

Changed file count: 2

Changed files:
- lib/widget.rb
- spec/widget_spec.rb

Change stats:
- lib/widget.rb (+12/-3) total=15
- spec/widget_spec.rb (+40/-0) total=40

Large changes:
- spec/widget_spec.rb total=40

Documentation files:
- none

Test files:
- spec/widget_spec.rb

Production files:
- lib/widget.rb

Unsafe change ratio: 0.0

High risk files:
- none

Risk level: medium

Risk reasons:
- total_changes_above_20
```

### JSON output (example)

Pretty-printed JSON includes the same metrics in one object (keys are strings). Illustrative fragment:

```json
{
  "goal": "my-branch",
  "base": "main",
  "changed_file_count": 2,
  "changed_files": ["lib/widget.rb", "spec/widget_spec.rb"],
  "change_stats": [
    {"file": "lib/widget.rb", "added": 12, "removed": 3, "total_changes": 15}
  ],
  "large_changes": [
    {"file": "spec/widget_spec.rb", "added": 40, "removed": 0, "total_changes": 40}
  ],
  "documentation_files": [],
  "test_files": ["spec/widget_spec.rb"],
  "production_files": ["lib/widget.rb"],
  "unsafe_change_ratio": 0.0,
  "high_risk_files": [],
  "risk_level": "medium",
  "risk_reasons": ["total_changes_above_20"]
}
```

Exact arrays and numbers depend on your repo and config.

### `--fail-on`

Optional **`--fail-on low|medium|high`** exits with status **1** when the reported risk is at or above that level (after writing **`--output`**, if set). Use this in scripts or CI when you want the process to fail on drift severity.

**GitHub Actions** in this repository runs **`analyze`** in **reporting** mode: JSON is written to **`drift-report.json`** and uploaded as an artifact; the workflow does **not** pass **`--fail-on`**, so CI does not block merges on risk level today.

### Configuration (thresholds)

Optional repo-local file **`.repo-drift-detector.yml`**:

```yaml
risk:
  medium_change_threshold: 20    # default: 20
  high_change_threshold: 100     # default: 100
  unsafe_change_ratio_threshold: 3.0  # default: 3.0
```

`high_change_threshold` must be **greater than** `medium_change_threshold`. Invalid YAML or bad values make `analyze` exit **2**.

## CI and drift artifacts

On **pull requests** and **pushes to `main`**, GitHub Actions runs RSpec, RuboCop, then:

```bash
mise exec -- bundle exec exe/repo-drift-detector analyze \
  --base "$BASE" \
  --format json \
  --output drift-report.json
```

`$BASE` is `origin/main` on PRs and `HEAD~1` on pushes to `main` (with full history: `fetch-depth: 0`).

The workflow uploads **`drift-report.json`** as artifact **`repo-drift-report`** (`actions/upload-artifact`, `if: always()` so a failed step later can still attach the file when that applies).

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
