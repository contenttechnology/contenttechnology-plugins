# Changelog

## [Unreleased]

## [1.0.7] - 2026-02-10

### Added
- `/revoice` skill — re-produce an existing draft with a different author's voice. Writes fresh from the original production brief (not a transformation), runs the full 7-criteria quality gate, and tracks lineage between variants via `revoice_of`, `original_brief`, and shared `pitch_id` metadata

## [1.0.6] - 2026-02-10

## [1.0.6] - 2026-02-10

### Added
- Editorial feedback loop via `pipeline/editorial-feedback.md` — editorial skill writes carry-forward notes (production notes, angle guidance, research guidance, held pitch triggers) that research, angle, and produce skills read and act on in subsequent cycles
- Entries have open/addressed lifecycle with 14-day auto-pruning of addressed entries
- Run skill propagates feedback instructions to all stage subagents
- README updated with feedback loop documentation, pipeline diagram, and project structure

### Changed
- Validate skill: subagents now write detailed reports to `pipeline/validation/{pitch-id}/` files and return only a single summary line to the parent context, significantly reducing context window usage
- Validate skill: pitches now processed sequentially (full validate-synthesise-update cycle per pitch) instead of launching all agents across all pitches at once
- Validate skill: counter-evidence summary line now includes refined thesis and kill reason, eliminating need to read detail files during synthesis
- Quality skill: drafts that pass are renamed from `draft-` to `for-review-` prefix when moved to `pipeline/040_review/`

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
