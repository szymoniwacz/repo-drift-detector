# Implementation Direction

This document defines the intended direction for `repo-drift-detector`.

It is intentionally documentation-first. The goal is to give AI coding tools enough context to implement future changes consistently without changing the code before the direction is clear.

## Product direction

`repo-drift-detector` should evolve from a deterministic repository drift summary into a repository review intelligence tool.

The core value should stay the same:

- expose repository risk before review starts
- make large or risky change surfaces visible
- help reviewers understand where attention is needed
- support AI-assisted development without making an LLM the source of truth

The project should remain useful without any network call.

AI interpretation may exist later, but deterministic analysis must stay the foundation.

## Non-goals

The project should not become:

- a generic lint runner
- a replacement for code review
- a style-only formatter
- a generic AI code review wrapper
- a tool that requires an LLM to produce useful output

## Target capabilities

| Capability | Direction |
|---|---|
| Documentation | Keep architecture, CLI, report schema, and AI implementation context current |
| Language support | Add pluggable language analyzers for popular programming languages |
| Local analysis | Analyze a local repository or branch against a selected base commit/ref |
| CI integration | Make GitHub Actions usage simple and copy-paste friendly |
| Line-level findings | Report exact changed lines, reasons, severity, and rule identifiers |
| Machine output | Keep JSON stable enough for CI, automation, and later UI/reporting |

## Design principle

The tool should separate two questions:

1. What changed?
2. Why might this change deserve review attention?

Git can answer the first question.
`repo-drift-detector` should answer the second one.

## Implementation order

Do not implement everything at once.

Recommended sequence:

1. Documentation and contracts
2. CLI option design
3. Report schema design
4. Internal abstractions for changed lines and findings
5. First language analyzer extracted from current Ruby-focused behavior
6. Generic text analyzer fallback
7. GitHub Actions examples
8. Line-level findings output
9. Additional language analyzers
10. Optional AI explanation layer improvements

## Stable concepts

These concepts should stay stable across future changes:

| Concept | Meaning |
|---|---|
| `base` | Git ref or commit used as the comparison point |
| `goal` | Optional human label copied into output |
| `summary` | Compact machine-readable risk summary |
| `risk_level` | Low / medium / high review attention signal |
| `risk_score` | Numeric risk score, not a correctness verdict |
| `risk_reasons` | Deterministic reason codes explaining the score |
| `findings` | Future line-level review attention records |

## Documentation rule

Every future feature should update documentation in the same PR.

At minimum, update one of:

- `README.md`
- `docs/implementation-direction.md`
- `docs/target-architecture.md`
- `docs/cli-and-ci-contract.md`
- `docs/line-level-findings.md`
- `docs/language-support.md`
- `docs/cursor-prompts.md`

If a change modifies output JSON, update the report schema examples before or together with the code.
