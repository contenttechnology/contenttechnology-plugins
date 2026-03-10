# Changelog

## [Unreleased]

## [1.1.7] - 2026-03-10

### Added
- `/review --approve <file>...`, `/review --reject <file>...`, and `/review --archive <file>...` — selective batch flags that apply actions to specific draft files instead of the entire review queue

## [1.1.6] - 2026-03-10

### Added
- `/review` now supports an "Archive" decision — shelves drafts and packages to `pipeline/archived/` without rejecting them, for content that isn't ready to publish but shouldn't be killed
- `/review --archive-all` batch flag — bulk archive all items in `040_review/`
- `pipeline/archived/` directory added to `/init` scaffold — tracked with `.gitkeep`
- Archive reason presets: "Not timely", "Needs more research", "Holding for strategy", "Low priority" (plus custom via Other)
- `/run` pipeline status now includes archived count

## [1.1.5] - 2026-03-04

### Added
- `/review --approve-all` and `/review --reject-all` batch mode flags — bulk approve or reject all items in `040_review/` without interactive prompts

## [1.1.4] - 2026-03-04

### Fixed
- `/review` skill now validates every `AskUserQuestion` response is non-empty before proceeding — prevents race condition where prompts could be auto-dismissed, causing the model to make editorial decisions on behalf of the human reviewer

## [1.1.3] - 2026-03-03

### Changed
- `/run` skill is now model-invocable — removed `disable-model-invocation` flag so the pipeline can be triggered programmatically by the model

## [1.1.2] - 2026-03-02

### Fixed
- Added explicit "do NOT rename" instructions with full `mv` command examples to `/quality`, `/revoice`, and `/run` — agents were still inferring the old `for-review-` rename behaviour

## [1.1.1] - 2026-02-28

### Changed
- Standardised pipeline filename and ID conventions — article drafts now use `draft-article-{date}-{NNN}` and package drafts use `draft-package-{date}-{NNN}`, with filenames and frontmatter IDs always in sync
- Removed the `draft-` → `for-review-` and `pkg-` → `for-review-pkg-` filename renames in `/quality` and `/revoice` — files now keep their name as they move through the pipeline, with the directory indicating the stage
- `/review` approve and kill paths now strip the `draft-` prefix (e.g., `draft-article-2026-02-10-001` becomes `article-2026-02-10-001`) and update the frontmatter ID to match, marking the human decision as a lifecycle transition
- Fixed type detection overlap in `/review` and `/quality` — articles detected by `draft-article-` prefix, packages by `draft-package-` prefix, eliminating ambiguity from the previous `for-review-` pattern

## [1.1.0] - 2026-02-24

### Added
- Content package support — authors can now produce multi-format social content packages (LinkedIn posts, tweets, X threads, reusable lines) alongside traditional articles
- Per-author `config.md` at `voice-models/authors/{name}/config.md` — controls `output_modes` (article, package, or both), `default_package_tier`, and `primary_platform`
- `/add-author` now asks about output mode preferences and writes `config.md` during author creation
- `/editorial` detects author output modes and writes package briefs with `package_tier`, `primary_platform`, and `related_brief_id` frontmatter — dual-output angles produce both an article brief and a package brief
- `/produce` detects brief type from frontmatter (`content_type` → article, `package_tier` → package) and dispatches format-specific production subagents with embedded writing rules per format
- `/quality` adds package-level checks (thesis coherence, format independence, no copy-paste, reusable line quality) and per-format quality assessment with format-appropriate interpretation of the 7 criteria
- `/review` adds package-specific decision options: approve all, approve selectively (pick formats), revise specific formats, kill package — with per-format publication timing on approve
- Package draft files use `pkg-` prefix and `max_revisions: 1` (one revision cycle; primary format failure kills the package)
- Three package tiers: light (LinkedIn post + tweets + reusable lines), full (LinkedIn long post + X thread + tweets + reusable lines + LinkedIn comment), thread-only (X thread + LinkedIn long post + tweet extractions + reusable lines)
- Package mix settings in `config.md`: default tier, max thread-only per week, max full packages per week
- `/init` generates `config.md` for example authors (Steve, Sarah) with article-only defaults

### Changed
- `/run` editorial stage now loads author configs to determine output modes and writes dual briefs for authors with `[article, package]`
- `/run` produce and quality stages handle both article drafts and content packages, with separate reporting per type
- `/run` summary distinguishes articles and packages at every stage

## [1.0.20] - 2026-02-24

### Fixed
- Research subagents now correctly use the Skill tool to invoke `steel-browser` and `agent-browser` when sources specify a `tool` property, instead of ignoring the hint and defaulting to WebFetch

## [1.0.19] - 2026-02-23

### Added
- Optional `tool` property on beat sources — set to `agent-browser` or `steel-browser` to use that tool as the primary access method for a source, with WebFetch/WebSearch as fallback. Sources without a `tool` property use WebFetch/WebSearch by default with browser fallback.

## [1.0.18] - 2026-02-23

### Removed
- `/add-campaign` skill and all campaign references — campaigns removed from angle, editorial, run, rush, revoice, init, and README
- Step budget concept removed from research, run, and init — research depth is controlled solely by research mode and per-source search budgets

## [1.0.17] - 2026-02-22

### Added
- Browser fallback for inaccessible sources — `/research`, `/validate`, and `/rush` subagents now attempt to fetch pages via a browser automation CLI (`agent-browser` or `bb`) when WebFetch fails (403, timeout, JavaScript-rendered pages), gracefully skipping if no browser tool is installed

## [1.0.16] - 2026-02-19

### Changed
- Removed slashes from skill names in next steps

## [1.0.15] - 2026-02-19

### Added
- `/init --copy-to-codex` option — copies all skills to the local Codex skills directory by running `install-codex-skills.sh` and exits immediately without scaffolding a project

## [1.0.14] - 2026-02-17

### Fixed
- `/init` no longer uses AskUserQuestion for free-text inputs (publication name, mission, beat description) — questions are now output as plain text so users type their answer directly instead of seeing a confusing "Enter name below" option

### Changed
- `/quality` summary now includes a review documents table linking each draft to its verdict and review/rejection file path

## [1.0.13] - 2026-02-13

### Fixed
- Added search budgets to `/validate`, `/research`, `/rush`, and `/run` subagent prompts to prevent indefinite hanging — subagents now have hard caps on WebSearch attempts (2-5 per source) and must report "nothing found" and move on rather than retrying endlessly
- Research subagents now skip inaccessible sources (403, 404, timeout) immediately instead of retrying with alternative URLs

### Changed
- `/validate` subagents reverted to using `WebFetch` as primary research tool — WebFetch timeout fix expected upstream

## [1.0.12] - 2026-02-13

### Changed
- `/validate` subagents now favour `WebSearch` over `WebFetch` to prevent hangs on slow or unresponsive URLs — `WebFetch` is still available as optional enrichment but subagents are instructed to move on if a fetch stalls

## [1.0.11] - 2026-02-13

### Fixed
- `/angle` summary table: pitch title and description no longer render with empty cells — restructured from multi-row pseudo-colspan layout to a single-row-per-pitch table with proper columns

## [1.0.10] - 2026-02-10
- README install instructions updated to use plugin marketplace
- README license corrected to MIT

## [1.0.9] - 2026-02-10

### Added
- `FORMATTING.md` — global formatting conventions file generated during `/init` with sensible defaults for readability, SEO, and AI engine discoverability (AEO)
- `/produce` and `/run` load and pass formatting conventions to production subagents
- `/quality` checks formatting compliance as part of the Readability criterion
- `PUBLICATION.md` template now references `FORMATTING.md`

## [1.0.8] - 2026-02-10

### Changed
- Pipeline folders numbered by stage order: `010_pitches`, `020_approved`, `030_drafts`, `040_review`, `050_published` — `rejected` and `validation` remain unnumbered (cross-cutting concerns)

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
- Quality skill: drafts that pass are renamed from `draft-` to `for-review-` prefix when moved to `pipeline/review/`

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
