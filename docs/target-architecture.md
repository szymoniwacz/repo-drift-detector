# Target Architecture

This document describes the target architecture direction.

It is not a code change plan for one large refactor. It is a map for future small implementation steps.

## Architectural goal

The application should keep a deterministic core.

The core should produce stable facts:

- changed files
- changed line ranges
- file categories
- detected languages
- rule findings
- risk summary
- JSON output

Interpretation layers may explain those facts, but they should not create new facts.

## Target pipeline

```text
CLI
  -> repository input
  -> diff provider
  -> diff parser
  -> language detector
  -> analyzer registry
  -> rule engine
  -> risk evaluator
  -> report builder
  -> renderer
```

## Target responsibilities

| Component | Responsibility |
|---|---|
| CLI | Parse options, validate input, choose output format, handle exit codes |
| Repository input | Resolve repository path, base ref, head ref, and working tree mode |
| Diff provider | Read Git diff data |
| Diff parser | Convert diff text into files, hunks, and changed lines |
| Language detector | Detect language by extension, filename, shebang, or fallback rules |
| Analyzer registry | Select language-specific and generic analyzers |
| Rule engine | Run deterministic rules and emit findings |
| Risk evaluator | Convert metrics and findings into risk score and reasons |
| Report builder | Build stable report objects |
| Renderer | Render text, JSON, markdown, or CI-friendly output |

## Important boundaries

| Boundary | Rule |
|---|---|
| CLI vs analysis | CLI should not contain analysis logic |
| Git data vs rules | Diff reading should not decide risk |
| Language detection vs findings | Detection should not emit review findings |
| Rules vs rendering | Rules should emit data, not formatted text |
| Deterministic core vs AI | AI may explain facts, not become the source of facts |

## Suggested package direction

```text
lib/repo/drift/detector/
  commands/
  git/
  languages/
  rules/
  findings/
  reports/
  renderers/
```

Exact names may change.
The separation should remain.

## Future finding object

Line-level findings should be represented as structured data.

Suggested fields:

| Field | Meaning |
|---|---|
| `rule_id` | Stable rule identifier |
| `severity` | `info`, `warning`, or `error` |
| `message` | Short user-facing message |
| `reason` | Explanation of why the line was flagged |
| `file_path` | Path relative to repository root |
| `line_start` | First changed line related to the finding |
| `line_end` | Last changed line related to the finding |
| `language` | Detected language or `unknown` |
| `category` | Finding category, e.g. `risk`, `structure`, `documentation` |

Internally, findings should be data objects, not formatted strings.

## Schema versioning

Add a report schema version before line-level output becomes public.

Example fields:

```json
{
  "schema_version": "0.2",
  "base": "main",
  "head": "HEAD",
  "summary": {},
  "files": [],
  "findings": []
}
```

Once `findings` are emitted, keep their fields stable.

## Extension strategy

Language support should be modular.

Each analyzer should define:

- supported file patterns
- supported rules
- fallback behavior
- emitted finding categories

A missing language-specific analyzer should not fail the analysis.
The generic analyzer should handle unsupported files.
