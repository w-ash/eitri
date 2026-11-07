# Changelog

Format is [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/). Versions match the
backlog series in [docs/backlog/](docs/backlog/README.md). Batch mode: entries accumulate under
`[Unreleased]` and roll into a version section at release.

## [Unreleased]

### Changed

- `tools/openscad` no longer passes `--hardwarnings` and lets OpenSCAD's "Node didn't fit into
  cache" warning through, so plates of millions of facets, such as a 48-piece plate,
  build and pass `just check`. Every other warning still fails the run.
