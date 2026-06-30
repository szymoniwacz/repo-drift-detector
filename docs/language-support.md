# Language Support Strategy

The long-term goal is to support the most common programming languages without turning the project into a full static analysis platform.

`repo-drift-detector` should remain a repository drift and review-risk tool.
Language support should improve the precision of findings.
It should not replace specialized linters.

## Target language groups

| Priority | Languages | Reason |
|---|---|---|
| 1 | Ruby, JavaScript, TypeScript, Python | Common in backend, web, scripting, and AI-assisted repositories |
| 2 | Java, Kotlin, Go, PHP, C#, C++ | Common production languages with different project structures |
| 3 | Rust, Swift, Shell, SQL, Terraform, YAML | Important in infrastructure, tooling, configuration, and system work |
| fallback | Unknown / plain text | The tool should still produce useful generic findings |

## Detection strategy

Use simple deterministic detection first.

| Signal | Example |
|---|---|
| Extension | `.rb`, `.js`, `.ts`, `.py`, `.go` |
| Known filenames | `Gemfile`, `Rakefile`, `Dockerfile`, `Makefile` |
| Config files | `package.json`, `pyproject.toml`, `go.mod` |
| File header | script files with an interpreter line |

Do not introduce heavy parsing before the report schema is stable.

## Analyzer types

| Analyzer | Scope |
|---|---|
| Generic analyzer | Works on all changed text lines |
| Path analyzer | Uses file path and filename conventions |
| Language analyzer | Adds language-aware rules |
| Config analyzer | Handles dependency, CI, Docker, and infrastructure files |

## First implementation target

Start with a generic line-level analyzer plus a Ruby analyzer.

Reason:

- the project is written in Ruby
- current behavior already understands Ruby-oriented risk areas
- it gives a clean pattern for adding other languages later

## Future language analyzer contract

Each analyzer should define:

| Question | Example |
|---|---|
| Which files are supported? | Ruby files, Gemfile, Rakefile |
| Which rules are enabled? | command changes, dependency changes, missing spec changes |
| Which severity values can appear? | info, warning, error |
| What input is required? | changed lines, file path, optional project metadata |

## Rule examples by language

| Language | Useful first rules |
|---|---|
| Ruby | command changes, service object changes, gem dependency changes, missing spec changes |
| JavaScript / TypeScript | package changes, public API changes, config changes, missing test changes |
| Python | dependency changes, CLI changes, production code organization, missing test changes |
| Java / Kotlin | build file changes, public interface changes, package boundary changes |
| Go | module changes, public function changes, generated file changes |
| PHP | composer changes, framework config changes, controller/service changes |
| C# | project file changes, public API changes, dependency injection changes |
| Shell | CI script changes, deployment script changes, broad file-system operations |
| YAML | CI workflow changes, infrastructure config changes |
| SQL | schema changes, migration risk, data-shape changes |

## What not to do

Do not try to fully understand every language at once.

Avoid:

- full syntax parsing in the first version
- subjective quality judgments
- language-specific complexity metrics before basic findings are stable
- treating unsupported languages as failures

## Success criteria

Language support is successful when:

- unsupported files still get generic findings
- supported languages get more precise reasons
- adding a new language does not require changing CLI behavior
- JSON output stays stable
- CI usage stays simple
