# Documentation Index

This folder contains implementation-direction documentation for future development.

The current repository already has a README for installation, commands, current architecture, configuration, and CI usage.
These docs describe the next implementation direction.

## Documents

| Document | Purpose |
|---|---|
| `implementation-direction.md` | Product direction, non-goals, target capabilities, implementation order |
| `target-architecture.md` | Target architecture, boundaries, future internal components |
| `cli-and-ci-contract.md` | Target local CLI behavior and GitHub Actions integration contract |
| `line-level-findings.md` | Future line-level findings schema and reporting rules |
| `language-support.md` | Multi-language support strategy and analyzer expansion plan |
| `cursor-prompts.md` | Step-by-step prompts for Cursor implementation work |

## How to use these docs

Before implementing a new feature:

1. Read `implementation-direction.md`.
2. Read the document matching the feature area.
3. Keep the change small.
4. Update docs together with behavior changes.
5. Add specs before treating the feature as complete.

## Implementation guardrails

| Guardrail | Reason |
|---|---|
| Deterministic core first | The tool must stay useful without network calls |
| Stable JSON contracts | CI and automation depend on predictable output |
| Line-level findings as data | Renderers and future integrations need structured facts |
| Generic fallback for languages | Unsupported languages should still be analyzable |
| Docs updated with behavior | Future AI-assisted changes need explicit context |

## Recommended next implementation step

The safest next implementation step is report schema versioning.

After that:

1. internal diff model
2. generic line-level findings behind `--include-lines`
3. language detection
4. first Ruby analyzer
5. GitHub Actions documentation example

Do not start by adding more AI behavior.
The deterministic report contract should come first.
