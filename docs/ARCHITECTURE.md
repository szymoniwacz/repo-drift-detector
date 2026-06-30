# Architecture direction

`repo-drift-detector` should remain a deterministic repository analysis tool first.

The long-term direction is not a generic AI code review bot. The useful direction is a hybrid system:

1. deterministic repository signals,
2. exact file and line findings,
3. language-aware analyzers,
4. CI-friendly JSON artifacts,
5. optional explanation layers.

## Core modules

| Module | Responsibility |
|---|---|
| `GitDiff` | Read changed files, numstat, and unified diff from a selected base ref. |
| `Analyzer` | Coordinate metrics, risk evaluation, and exact line findings. |
| `LanguageRegistry` | Map changed files to programming languages. |
| `LineFindingExtractor` | Convert unified diff hunks into exact file/line findings with reasons. |
| `RiskEvaluator` | Keep risk thresholds and risk scoring separate from parsing. |
| `Renderers` | Present the same analysis as text, JSON, or markdown. |

## Language strategy

The first version should not try to fully parse every language.

Recommended sequence:

1. extension-based language detection,
2. shared cross-language findings,
3. language-specific rule packs,
4. optional AST-based analyzers for selected languages,
5. optional LLM explanation layer that explains deterministic findings, not replaces them.

## Base ref strategy

`--base` is the selected starting point for the analysis.

It can be:

- `main`,
- `origin/main`,
- `HEAD~1`,
- a specific commit SHA,
- a release tag,
- any local branch or ref available in the repository.

This supports local checks against any selected version of the code.

## Output strategy

Text output is for humans.
JSON output is for automation.

The JSON payload should include:

- repository-level metrics,
- changed files,
- file stats,
- exact line findings,
- line finding count,
- risk level,
- risk score,
- reason codes.

## CI strategy

GitHub Actions should run the tool with full git history available:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0

- run: |
    mise exec -- bundle exec exe/repo-drift-detector analyze \
      --base origin/main \
      --format json \
      --output drift-report.json
```

Then upload `drift-report.json` as an artifact.
