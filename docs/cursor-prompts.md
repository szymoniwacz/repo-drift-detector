# Cursor Prompts

Use these prompts to implement the roadmap in small, controlled steps.

Important rule for every prompt:

Do not implement unrelated features.
Do not rewrite the whole project.
Keep changes small.
Update docs when behavior, CLI, JSON, or architecture changes.
Run tests and RuboCop after each step.

---

## Prompt 1 — Read the project context first

```text
You are working in the repo-drift-detector repository.

Before changing code, read:
- README.md
- docs/implementation-direction.md
- docs/target-architecture.md
- docs/cli-and-ci-contract.md
- docs/line-level-findings.md
- docs/language-support.md

Summarize the current architecture, the target architecture, and the smallest safe next implementation step.

Do not change code yet.
Return a short plan with files you expect to touch.
```

---

## Prompt 2 — Add report schema version only

```text
Implement only report schema versioning.

Goal:
- Add a stable `schema_version` field to JSON output.
- Use the first version that makes sense for the current public report shape.
- Do not add line-level findings yet.
- Update README.md and docs/line-level-findings.md if needed.

Constraints:
- Keep text output behavior unchanged unless tests require minimal adjustment.
- Do not change risk scoring.
- Do not change interpreter behavior.
- Add or update specs for JSON output.
- Run the test suite and RuboCop.
```

---

## Prompt 3 — Extract diff parsing model

```text
Prepare the codebase for line-level findings by introducing a small internal diff model.

Goal:
- Add internal objects for changed files, hunks, and changed lines.
- Keep current public CLI behavior unchanged.
- Keep current JSON output unchanged except for fields already intentionally added in previous steps.
- Add specs for parsing changed line locations from a unified diff fixture.

Constraints:
- Do not add language analyzers yet.
- Do not add findings yet.
- Do not change risk scoring.
- Keep this as an internal refactor.
- Update docs/target-architecture.md if the final names differ from the documented direction.
```

---

## Prompt 4 — Add generic line-level findings

```text
Add the first minimal line-level findings implementation.

Goal:
- Add a `findings` array to JSON output when `--include-lines` is passed.
- Emit only generic deterministic findings at first.
- Every finding must include: rule_id, severity, file_path, line_start, category, message, reason.
- Do not emit vague findings without a changed line location.

Suggested first rules:
- high-risk path changed
- large changed hunk
- dependency file changed
- CI configuration changed

Constraints:
- Default output should remain stable unless `--include-lines` is used.
- Text output should stay concise.
- Add specs for CLI, JSON, and finding objects.
- Update README.md and docs/line-level-findings.md.
```

---

## Prompt 5 — Add language detector

```text
Add deterministic language detection.

Goal:
- Detect language for changed files by extension and known filenames.
- Add language field to internal changed-file data.
- Include language in line-level findings when available.
- Add fallback `unknown` or `text` for unsupported files.

Constraints:
- Do not add language-specific rules yet.
- Do not break unsupported file handling.
- Add specs for common file types: Ruby, JavaScript, TypeScript, Python, Java, Go, PHP, C#, C++, Rust, Shell, SQL, YAML, Terraform.
- Update docs/language-support.md if detection behavior differs.
```

---

## Prompt 6 — Add Ruby analyzer as first language analyzer

```text
Add the first language-specific analyzer for Ruby.

Goal:
- Keep the generic analyzer as fallback.
- Add Ruby-specific findings for command files, dependency files, and production changes without related spec changes.
- Do not attempt full Ruby AST parsing yet.
- Use deterministic text and path-based rules first.

Constraints:
- Analyzer selection must be registry-based so other languages can be added later.
- Do not hardcode Ruby behavior into the generic analyzer.
- Add specs for Ruby analyzer and analyzer registry.
- Update docs/language-support.md and docs/target-architecture.md.
```

---

## Prompt 7 — Add GitHub Actions documentation example

```text
Improve CI documentation only.

Goal:
- Add a copy-paste GitHub Actions example to README.md or docs/cli-and-ci-contract.md.
- Show how to run repo-drift-detector on pull requests.
- Show how to upload drift-report.json as an artifact.
- Show optional `--fail-on high` policy mode.

Constraints:
- Do not change application code.
- Do not change existing workflows unless explicitly requested.
- Keep the example minimal and clear.
```

---

## Prompt 8 — Add markdown report for PR comments

```text
Add markdown report output suitable for pull request comments.

Goal:
- Support markdown output for analyze reports.
- Include summary, risk reasons, and optionally line-level findings.
- Keep markdown generated from deterministic report data.

Constraints:
- Do not require AI interpretation.
- Do not duplicate rendering logic more than necessary.
- Add renderer specs.
- Update README.md and docs/cli-and-ci-contract.md.
```

---

## Prompt 9 — Add second language analyzer

```text
Add a second language analyzer after Ruby is stable.

Recommended next choice: JavaScript / TypeScript or Python.

Goal:
- Follow the analyzer registry pattern.
- Keep generic analyzer fallback.
- Add only a few useful deterministic rules.
- Do not add full syntax parsing unless there is a clear reason.

Constraints:
- Add specs for new analyzer.
- Update docs/language-support.md.
- Keep JSON schema stable.
```

---

## Prompt 10 — Before every PR

```text
Review this branch before opening a PR.

Check:
- Did the change stay within the requested scope?
- Did it touch only necessary files?
- Did it preserve existing CLI behavior unless intentionally changed?
- Did it update README or docs when behavior changed?
- Did it add specs for new behavior?
- Did RSpec pass?
- Did RuboCop pass?

Return:
- summary
- changed files grouped by responsibility
- risks
- missing docs or tests
- recommended next step
```
