# Project direction for AI-assisted changes

Use this file as working context before changing the repository.

## Product identity

`repo-drift-detector` is a deterministic repository drift and review-risk analysis tool.

It should help engineers understand repository impact before or during review.

It is not a generic linter.
It is not an AI chatbot.
It is not an LLM-first code review tool.

## Implementation priorities

1. Keep deterministic signals as the source of truth.
2. Keep JSON output stable and automation-friendly.
3. Keep CLI usage simple.
4. Add exact file and line findings gradually.
5. Add language-specific logic through isolated rule packs.
6. Keep optional AI explanations downstream from deterministic data.

## Required documentation updates

Every meaningful feature must update at least one of:

- `README.md`,
- `docs/ARCHITECTURE.md`,
- `docs/LINE_FINDINGS.md`,
- `.ai/conventions/project-direction.md`.

Documentation is part of the implementation.

## CLI rule

Prefer extending existing commands before adding new commands.

`analyze` should remain the main machine-readable command.
`explain` should remain the human interpretation command.

## Output rule

When adding new data, expose it in JSON first.
Human text output can follow.

## Language rule

Do not mix language-specific heuristics directly into `Analyzer`.
Use dedicated classes or rule packs.

## AI rule

AI may explain findings.
AI must not be the only source of findings.
