# CLI and CI Contract

This document defines the target CLI and CI behavior.

## Target local usage

The tool should support analysis against a selected base ref.

| Example | Meaning |
|---|---|
| `repo-drift-detector analyze --base main` | Compare current state against local `main` |
| `repo-drift-detector analyze --base origin/main` | Compare current state against remote tracking branch |
| `repo-drift-detector analyze --base abc1234` | Compare current state against exact commit |
| `repo-drift-detector analyze --base main --head HEAD` | Compare explicit base and head |
| `repo-drift-detector analyze --repo /path/to/repo --base main` | Analyze another local repository |

## Target CLI options

| Option | Required | Meaning |
|---|---:|---|
| `--base <ref>` | yes | Commit, branch, or tag used as comparison point |
| `--head <ref>` | no | Ref to analyze; default: current state |
| `--repo <path>` | no | Repository path; default: current directory |
| `--goal <label>` | no | Human label copied into output |
| `--format text|json|markdown` | no | Output format |
| `--output <path>` | no | Write report to file |
| `--fail-on low|medium|high` | no | Return non-zero when risk crosses threshold |
| `--include-lines` | no | Include line-level findings |
| `--schema-version` | no | Print report schema version |

## Exit codes

| Code | Meaning |
|---:|---|
| 0 | Completed successfully |
| 1 | Completed, but configured risk threshold was crossed |
| 2 | Usage, config, repository, or ref validation problem |
| 3 | Unexpected internal problem |

## GitHub Actions direction

The project should include simple CI examples.

A recommended workflow should:

1. checkout repository history deeply enough to compare refs
2. install Ruby dependencies
3. run tests and RuboCop
4. run `repo-drift-detector analyze` with `--base origin/main`
5. write `drift-report.json`
6. upload the report as an artifact
7. optionally use `--fail-on high`

## CI output modes

| Mode | Purpose |
|---|---|
| Text | quick human reading in logs |
| JSON | automation and artifact storage |
| Markdown | future PR comment summary |

GitHub Actions integration must not require AI interpretation.
It should work with deterministic analysis only.

## Future PR summary

A later version may generate a markdown file suitable for posting as a pull request comment.

The markdown summary should be derived from deterministic report data.
