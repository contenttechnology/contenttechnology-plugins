# Changelog

## [Unreleased]

### Changed
- Validate skill: subagents now write detailed reports to `pipeline/validation/{pitch-id}/` files and return only a single summary line to the parent context, significantly reducing context window usage

## [1.0.2] - 2026-02-10

### Added
- Version number displayed in /init banner and intro
- ASCII banner added to README

### Changed
- Release script now updates version in banner files alongside plugin.json

## [1.0.1] - 2026-02-10

### Added
- Release script for managing versioned releases with git tags
- Parallel file scaffolding in /init using subagent tasks

### Changed
- Restructured as multi-plugin repository
- Replaced preset industry questions with mission-driven onboarding in /init
- Removed namespace literals from skill references
- Removed SUMMARY.md creation from /init flow

## [1.0.0] - 2026-02-09

### Added
- Initial release with full editorial pipeline
- 14 skills: init, research, angle, validate, editorial, produce, quality, run, review, rush, add-beat, add-author, add-campaign
- Voice models for Steve and Sarah with style modifiers
- Brand voice guidelines and editorial ethics framework
- Knowledge base with signal indexing
- Configurable research modes (scan, investigate, deep-dive)
- Editorial calendar template
- Multi-stage quality gates
