# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Deterministic repository drift analysis from Git diffs (`analyze` command).
- Risk tiering (`low` / `medium` / `high`), `risk_score` (0–100), and `risk_reasons`.
- `explain` command with deterministic and offline `static-ai` interpreters.
- `explain --compare` for side-by-side deterministic vs static-ai output with comparison notes.
- JSON and markdown report output for `explain`; JSON output for `analyze`.
- CI workflow artifact upload for `drift-report.json`.
- Configurable thresholds via `.repo-drift-detector.yml`.

### Changed

- Git diff execution uses argument-based `Open3.capture3` instead of shell-interpolated commands.
- Invalid `--base` refs and invalid `--format` values fail clearly with exit code 2.
