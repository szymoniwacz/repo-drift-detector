# Line-Level Findings Contract

The current project reports repository-level drift signals.

A future version should also answer:

- which exact changed lines deserve attention
- which deterministic rule flagged them
- why they were flagged
- how severe the finding is

This document defines the target shape.

## Goal

Line-level findings should make the report actionable.

Instead of only saying that a change has high risk, the tool should point to specific locations.

## Finding fields

| Field | Required | Meaning |
|---|---:|---|
| `rule_id` | yes | Stable deterministic rule identifier |
| `severity` | yes | `info`, `warning`, or `error` |
| `file_path` | yes | Repository-relative path |
| `line_start` | yes | First changed line related to finding |
| `line_end` | no | Last changed line related to finding |
| `language` | no | Detected language |
| `category` | yes | Broad category, e.g. `risk`, `structure`, `tests`, `docs` |
| `message` | yes | Short explanation |
| `reason` | yes | Longer reason for reviewer |
| `evidence` | no | Small structured context used by the rule |

## Example JSON

```json
{
  "findings": [
    {
      "rule_id": "ruby_command_changed_without_test",
      "severity": "warning",
      "file_path": "lib/repo/drift/detector/commands/analyze.rb",
      "line_start": 42,
      "line_end": 48,
      "language": "ruby",
      "category": "tests",
      "message": "Command behavior changed without nearby test changes.",
      "reason": "CLI behavior affects automation and should be covered by command specs.",
      "evidence": {
        "matched_file_category": "command",
        "related_test_changed": false
      }
    }
  ]
}
```

## Rule identifiers

Rule identifiers should be stable and descriptive.

Good examples:

| Rule ID | Meaning |
|---|---|
| `high_risk_path_changed` | A sensitive project area changed |
| `large_changed_hunk` | A large changed region was detected |
| `production_changed_without_tests` | Production code changed without test changes |
| `dependency_file_changed` | Dependency file changed |
| `ci_config_changed` | CI configuration changed |
| `public_interface_changed` | Public interface-like code changed |

## Severity semantics

| Severity | Meaning |
|---|---|
| `info` | Worth noticing, not necessarily risky |
| `warning` | Should receive review attention |
| `error` | Strong policy signal; may be used with CI threshold later |

Severity is not a correctness verdict.
It is a review-attention signal.

## Text output direction

Text output should stay short.

Suggested format:

```text
Findings:
- warning ruby_command_changed_without_test lib/.../analyze.rb:42-48
  Command behavior changed without nearby test changes.
```

## Markdown output direction

Markdown output should be suitable for PR comments.

Suggested format:

| Severity | Rule | Location | Reason |
|---|---|---|---|
| warning | `ruby_command_changed_without_test` | `lib/.../analyze.rb:42-48` | Command behavior changed without nearby test changes. |

## Implementation rule

A rule should not emit a finding unless it can point to a file and at least one changed line.

Repository-level metrics should stay in `summary`.
Line-level facts should go into `findings`.

## Avoid

Do not emit vague findings like:

- `architecture may be bad`
- `code looks complex`
- `AI generated suspicious code`

Every finding needs:

- deterministic input
- stable rule identifier
- precise location
- clear reason
