# Repo::Drift::Detector

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/repo/drift/detector`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'repo-drift-detector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install repo-drift-detector

## Usage

TODO: Write usage instructions here

## CI usage

Locally (aligns with GitHub Actions):

```bash
mise exec -- bundle install
mise exec -- bundle exec rspec
mise exec -- bundle exec rubocop
mise exec -- bundle exec exe/repo-drift-detector analyze --base origin/main --format json --output drift-report.json
```

The **CI** workflow runs on pull requests and on pushes to `main`: it sets up Ruby with mise, runs RSpec and RuboCop, then runs `analyze` with **`--format json`** and **`--output drift-report.json`** so the run produces a machine-readable report (risk level, `risk_reasons`, and change metrics). The job does not gate merges on drift severity today; the report is for visibility.

### Drift report artifact

Each workflow run uploads **`drift-report.json`** as a GitHub Actions artifact named **`repo-drift-report`**. The file is JSON you can parse programmatically (metrics, risk tier, reasons). That format is a good fit for later tooling—for example dashboards, custom policies, or AI-assisted summaries—without changing how the CLI works today.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/repo-drift-detector.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
