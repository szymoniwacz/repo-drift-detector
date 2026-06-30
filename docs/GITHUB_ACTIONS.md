# GitHub Actions integration

This tool should be easy to add to a repository as a review artifact generator.

## Minimal workflow step

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0

- uses: ruby/setup-ruby@v1
  with:
    bundler-cache: true

- name: repo-drift-detector analyze
  run: |
    if [ "${{ github.event_name }}" = "pull_request" ]; then
      BASE="origin/${{ github.base_ref }}"
      git fetch origin "${{ github.base_ref }}"
    else
      BASE="$(git rev-parse HEAD~1)"
    fi

    bundle exec repo-drift-detector analyze \
      --base "$BASE" \
      --format json \
      --output drift-report.json

- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: repo-drift-report
    path: drift-report.json
```

## Why `fetch-depth: 0`

The tool compares the current working tree against a selected Git ref.

GitHub Actions shallow checkouts often do not contain enough history for reliable diffing.

## Recommended usage

| Use case | `--base` value |
|---|---|
| Pull request | `origin/${{ github.base_ref }}` |
| Push to main | `HEAD~1` |
| Local feature branch | `main` or `origin/main` |
| Local experiment | specific commit SHA |
| Release comparison | release tag |

## CI output policy

Start with artifact generation only.

Later, add `--fail-on medium` or `--fail-on high` when the team trusts the thresholds.
