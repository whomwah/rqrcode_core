# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2021-04-23

### Changed

- README updated
- Small documentation clarification [@smnscp](https://github.com/smnscp).
- Rakefile cleaned up. You can now just run `rake` which will run specs and fix linting using `standardrb`

### Breaking Changes

- Very niche but a breaking change never the less. The `to_s` method *no longer* accepts the `:true` and `:false` arguments, but prefers `:dark` and `:light`.

## [0.2.0] - 2020-12-26

### Changed

- fix `required_ruby_version` for Ruby 3 support

[unreleased]: https://github.com/whomwah/rqrcode_core/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/whomwah/rqrcode_core/compare/v0.2.0...v1.0.0
[0.2.0]: https://github.com/whomwah/rqrcode_core/compare/v0.1.2...v0.2.0
