# Exact line findings

The current direction adds a second layer below file-level drift metrics.

File-level metrics answer:

> How large is the change surface?

Line findings answer:

> Which exact added lines deserve review attention, and why?

## Current MVP behavior

The first implementation reads `git diff --unified=0` and extracts findings from added production lines.

A finding has this shape:

```json
{
  "file": "lib/example.rb",
  "line": 42,
  "language": "Ruby",
  "content": "debugger",
  "reason": "debug output added"
}
```

## Current finding reasons

| Reason | Meaning |
|---|---|
| `temporary marker added` | A temporary marker was added. |
| `debug output added` | A debug statement was added. |
| `dynamic execution call added` | A dynamic execution pattern was added. |
| `silent error handling added` | A silent error pattern was added. |
| `sensitive-looking identifier added` | A line contains credential-like naming. |
| `broad SQL select added` | A broad SQL selection pattern was added. |
| `validation bypass added` | A validation bypass pattern was added. |
| `long production line added` | A production line over 120 characters was added. |

## What this is not yet

This is not a full static analyzer.

It does not yet understand:

- AST nodes,
- framework conventions,
- semantic coupling,
- architecture boundaries,
- domain intent.

That is intentional.

The purpose of this branch is to show the implementation direction without turning the project into a large linter too early.

## Next steps

| Step | Why |
|---|---|
| Add rule packs per language | Keep language-specific logic isolated. |
| Add config for enabled rules | Let each repository define its own review policy. |
| Add severity | Separate warning-level findings from high-risk findings. |
| Add markdown renderer | Make reports easier to paste into PRs. |
| Add GitHub Actions example | Make adoption easier. |
| Add AST adapters later | Improve accuracy for Ruby, JS/TS, Python, Go, Java, etc. |
