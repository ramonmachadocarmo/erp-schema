# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Breaking changes to a
field already adopted by a consumer are called out explicitly — three independently
deployed ecosystems (Go, TypeScript, Dart) read this file to know if a bump is safe.

## [0.1.0] - Unreleased

### Added
- `common/Address` — extracted from the identical `OrderAddress` (sales-service) /
  `Address` (config-service) structs.
- `purchasing/Quote` (+ nested `QuoteLine`, `QuoteStatus`) — pilot entity for the whole
  pipeline; matches purchasing-service's `domain.Quote` wire shape as of this version.
