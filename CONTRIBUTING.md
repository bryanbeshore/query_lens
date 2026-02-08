# Contributing to QueryLens

Thanks for your interest in contributing! Here's how to get started.

## Process

1. **Fork** the repo and clone your fork
2. **Create a branch** for your change (`git checkout -b my-feature`)
3. **Install dependencies**: `bundle install`
4. **Make your changes** and add tests if applicable
5. **Run the test suite**: `bundle exec rake test` — all tests must pass
6. **Commit** with a clear message explaining what and why
7. **Push** to your fork and open a **Pull Request** against `main`

## What to expect

- PRs are typically reviewed within a few days
- CI must pass before merge (tests run on Ruby 3.1, 3.2, and 3.3)
- Small, focused PRs are easier to review and more likely to land quickly
- If your change is large or introduces a new feature, consider opening an issue first to discuss the approach

## Reporting bugs

Open a GitHub issue with:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Ruby/Rails versions

## Security vulnerabilities

Please do **not** open a public issue for security vulnerabilities. See [SECURITY.md](SECURITY.md) for responsible disclosure instructions.
