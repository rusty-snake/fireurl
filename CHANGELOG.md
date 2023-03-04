# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## 0.2.0 - 2023-03-04
### Added
- `FIREURL_BROWSER` env variable to set the browser
  > **Note**: This is a stopgap solution and will eventually be removed in the future.
- restriction for the uri

### Changed
- Refactored and Improved dist.sh
- Create fireurld socket with 0600 mode

## 0.1.0 - 2023-01-05
### Added
- basic fireurl client and server.
- dist.sh to build the release binaries.
