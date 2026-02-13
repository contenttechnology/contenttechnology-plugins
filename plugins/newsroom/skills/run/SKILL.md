---
name: run
description: Execute the full autonomous editorial pipeline — research through quality gate — with no human interaction. Outputs a list of articles for review or 'nothing to do'.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep
---

<objective>
Execute the complete Newsroom editorial pipeline autonomously, from research through quality gate, with zero human interaction. This skill is designed for scheduled/cron execution. It processes all pending work at every stage — both new work generated in this run and leftovers from previous runs. The final output is either "nothing to do" or a list of articles now in `pipeline/040_review/` awaiting human review.

The pipeline stages execute sequentially: Research → Angle → Validate → Editorial → Produce → Quality. Each stage is dispatched as a Task subagent. Between stages, the orchestrator checks the filesystem for pending work. If a stage has no work, it is skipped (not aborted — later stages may have pending work from prior runs).
</objective>

<process>

## Step 1: Load Configuration and Pipeline State

Read configuration files:
1. **`PUBLICATION.md`** — Editorial mission and quality criteria
2. **`config.md`** — Research mode, step budgets, quality thresholds, content mix targets
3. **`knowledge-base/index.json`** — Current signal count, processed URLs, processed files

If `config.md` is missing, use defaults: scan mode, 80-step budget, max 2 revisions.
If `knowledge-base/index.json` is missing or invalid, note it — research stage will create a fresh one.

Scan the full pipeline to count pending work at each stage:

1. Use Glob for `knowledge-base/sources/*.md` — count unprocessed local files (compare filenames against `processed_files` in index.json)
2. Use Glob for `beats/*.md` — read each, count active beats due for this cycle
3. Use Glob for `pipeline/010_pitches/*.md` — read each, count `status: pending` and `status: validated`
4. Use Glob for `pipeline/020_approved/*.md` — read each, count `status: ready`
5. Use Glob for `pipeline/030_drafts/*.md` — read each, count `status: draft` or `status: revision`
6. Use Glob for `pipeline/040_review/*.md` — count existing articles (for final report baseline)
7. Read `pipeline/editorial-feedback.md` if it exists — count open entries by type for the run report

Store all counts. You will use these for early-exit logic, stage skipping, and the final run report.

## Step 2: Early Exit Check

If ALL of the following are zero:
- Unprocessed local source files
- Active beats due for this cycle
- Pending pitches (`status: pending`)
- Validated pitches (`status: validated`)
- Ready briefs (`status: ready`)
- Drafts awaiting quality (`status: draft` or `status: revision`)

Then there is nothing to do. Output:

```
# Newsroom Run: Nothing to Do — {date}

No new work at any pipeline stage.

Pipeline status:
- Articles in review: {count from pipeline/040_review/}
- Published: {count from pipeline/050_published/}

{If articles in review:} Action required: {count} articles awaiting human review in pipeline/040_review/.
{If none:} All clear — no work pending anywhere in the pipeline.
```

Write this to `metrics/run-{YYYY-MM-DD-HHmm}.md`, commit it, and exit.

## Step 3: Execute Research Stage

**Check**: Are there unprocessed local source files OR active beats due?

If neither, skip to Step 4.

If work exists, dispatch a Task subagent (subagent_type: "general-purpose", model: "sonnet"):

```
You are the Research Stage agent of an autonomous editorial pipeline run. Execute the full research cycle with zero human interaction.

## Configuration
{Paste config.md contents — research mode, step budget}

## Knowledge Base State
{Paste knowledge-base/index.json contents — next_signal_id, processed_urls, processed_files}

## Your Task

### 1. Process Active Beats
Read each of these beat config files and dispatch a research subagent (Task, model: "sonnet") per beat:

{List active beat file paths}

For each beat, the research subagent should:
- Check each source URL against the processed_urls list — skip already-processed content
- Use WebSearch and WebFetch to scan sources for new content
- Report findings as structured signal blocks

**Per-beat subagent prompt template:**

You are a research agent for the "{beat_name}" beat.

## Your Beat
{Beat config content}

## Already Processed URLs (skip these)
{Relevant processed URLs for this beat}

## Research Mode: {mode}
- scan: 2-3 steps per source
- investigate: 10-15 steps per source
- deep-dive: 20-30 steps per source

## Task
Check each source for new content. For each new piece found, report:

---SIGNAL---
beat: {beat_slug}
source_tier: {tier}
angle_potential: {1-5}
confidence: {high|medium|low}
source_url: {url}
source_name: {name}
source_type: {type}
tags: [{tags}]
summary: |
  {2-4 sentence summary}
key_data_points:
  - {point}
suggested_angles:
  - {angle}
related_topics:
  - {topic}
---END_SIGNAL---

If no new content: report ---NO_NEW--- with source_url and reason.

## Inaccessible Sources
If a source returns 403, 404, timeout, or is otherwise inaccessible — report ---NO_NEW--- with the reason and move on immediately. Do NOT retry with alternative URLs. One attempt per source.

## Search Budget
At most 2-3 WebSearch attempts per source. If searches return nothing relevant, report ---NO_NEW--- and move on.

### 2. Process Local Source Files
Scan `knowledge-base/sources/` for markdown files not in processed_files. For each unprocessed file:
- Read content, parse any YAML frontmatter (beat, source_tier, title)
- Default source_tier to 1 (human-submitted = gold tier)
- Generate a signal report

### 3. Save All Outputs
- Write signal reports to `knowledge-base/signals/{signal-id}.md` with full YAML frontmatter (id, date, beat, source_tier, angle_potential, confidence, sources, related_signals, tags) and body (Summary, Key Data Points, Suggested Angles)
- Signal IDs: `sig-{YYYY-MM-DD}-{NNN}` starting from next_signal_id
- Update `knowledge-base/index.json` with: updated last_updated, next_signal_id, processed_urls, processed_files, signals metadata
- Write cycle summary to `metrics/cycle-{YYYY-MM-DD-HHmm}.md`

### 4. Check Editorial Feedback
Read `pipeline/editorial-feedback.md` if it exists. Any open entries targeting `research` should influence your beat prioritisation and search queries. If your research addresses an open entry, mark it as addressed (change status to `addressed`, add `addressed_by: research`, `addressed_date: {today}`, `resolution: {brief description}`, move from "Active Entries" to "Addressed Entries").

### 5. Output Format
Return:

RESEARCH_COMPLETE
signals_produced: {count}
beats_processed: {count}
local_files_processed: {count}
sources_checked: {count}
signal_highlights:
- {signal-id}: {one-line summary}
```

After the subagent returns, parse the output to extract counts. Then commit:

```
git add knowledge-base/signals/ knowledge-base/index.json metrics/ pipeline/editorial-feedback.md
```

Commit message: `Research cycle: {N} signals from {M} beats`

If the research subagent fails, log the error and continue to Step 4.

## Step 4: Execute Angle Stage

**Check**: Use Glob to re-scan `knowledge-base/signals/*.md`. Are there signals with `angle_potential >= 3`? (Read index.json for this if it was just updated, or scan signal files directly.)

If no viable signals exist AND no pending pitches from prior runs, skip to Step 5.

If work exists, dispatch a Task subagent (subagent_type: "general-purpose", model: "sonnet"):

```
You are the Angle Stage agent of an autonomous editorial pipeline. Scan the knowledge base for converging signals, construct falsifiable theses, and write pitch memos.

## Editorial Mission
{Paste PUBLICATION.md content}

## Quality Thresholds
{Paste relevant config.md sections — min sources for angle: 2}

## Existing Coverage (avoid duplication)
{List headlines from pipeline/010_pitches/, pipeline/020_approved/, pipeline/030_drafts/, pipeline/040_review/, pipeline/050_published/}

## Active Campaigns
{List active campaign slugs and theses from campaigns/active/}

## Your Task

### 1. Read All Signal Reports
Read all signal files from `knowledge-base/signals/*.md`. Prioritise:
- Signals from last 7 days
- angle_potential >= 3
- source_tier 1 or 2

### 2. Identify Convergence Patterns
Look for: cross-beat convergence, temporal convergence, contradiction signals, compounding signals, campaign-aligned signals.

### 3. Apply Quality Filters to Each Candidate Angle
- **"So What?" test**: Would a reader immediately understand why this matters? (pass/fail)
- **Synthesis test**: Does this REQUIRE multiple sources? Single-source angles are killed. (pass/fail — hard requirement)
- **Novelty test**: Is this angle saying something the audience hasn't seen this month? (pass/fail)
- **Durability test**: Will this be relevant in two weeks? (durable / time-sensitive / expired)

Kill any angle that fails "So What?", Synthesis, or Novelty.

### 4. Recommend Authors
Read author baselines from `voice-models/authors/*/baseline.md`. Match topic to author expertise. Set recommended_author and recommended_style in pitch memo.

### 5. Check Editorial Feedback
Read `pipeline/editorial-feedback.md` if it exists. Any open entries targeting `angle` should influence your convergence analysis and content type weighting. If your pitches address an open entry, mark it as addressed (change status to `addressed`, add `addressed_by: angle`, `addressed_date: {today}`, `resolution: {brief description}`, move from "Active Entries" to "Addressed Entries").

### 6. Write Pitch Memos
For each surviving angle, write to `pipeline/010_pitches/pitch-{YYYY-MM-DD}-{NNN}.md` with YAML frontmatter (id, date, status: pending, signals, beats, tags, timeliness, campaign, recommended_author, recommended_style, recommended_type) and body (Working Headline, Thesis, Supporting Evidence, Counter-Evidence, Source Map, Recommended Treatment, Timeliness Assessment, Campaign Alignment).

### 7. Output Format
Return:

ANGLE_COMPLETE
pitches_written: {count}
angles_considered: {count}
angles_killed: {count}
pitches:
- {pitch-id}: {headline} — {one-line thesis}
killed:
- {description}: {reason}
```

After the subagent returns, parse output and commit:

```
git add pipeline/010_pitches/ pipeline/editorial-feedback.md
```

Commit message: `Angle scan: {N} pitch memos from {M} signals`

If the angle subagent fails, log the error and continue to Step 5.

## Step 5: Execute Validate Stage

**Check**: Use Glob to re-scan `pipeline/010_pitches/*.md`. Read each and filter for `status: pending`.

If no pending pitches, skip to Step 6.

If work exists, dispatch a Task subagent (subagent_type: "general-purpose", model: "sonnet"):

```
You are the Validate Stage agent of an autonomous editorial pipeline. Validate all pending pitch memos by dispatching parallel validation subagents.

## Pending Pitches
{List pending pitch file paths}

## Your Task

For each pending pitch memo:

### 1. Read the Pitch Memo
Read the file, extract the thesis and supporting evidence.

### 2. Dispatch 4 Validation Subagents in Parallel (Task, model: "sonnet")

**Subagent 1 — Supporting Evidence**: Search for additional data, reports, commentary that SUPPORTS the thesis. Use WebSearch and WebFetch. Return: strength (strong/moderate/weak), new sources found, assessment.

**Subagent 2 — Counter-Evidence** (ADVERSARIAL): Actively try to disprove or weaken the thesis. Search for contradicting data, alternative explanations, expert disagreement. Return: threat_level (fatal/significant/manageable/minimal), counter sources, recommendation (PROCEED/REFINE/KILL).

**Subagent 3 — Scope Validation**: Assess geographic scope, audience breadth, content type fit. Return: scope_assessment (appropriate/too-broad/too-narrow/geographic-mismatch), audience_fit (strong/adequate/weak).

**Subagent 4 — Audience Resonance**: Check industry forums, social media, community discussions. Is the audience already discussing this? Return: audience_awareness (high/moderate/low/none), predicted_reception (high-value/useful/marginal/redundant).

### 3. Synthesise Results
Apply these rules:
- counter-evidence threat_level "fatal" → REJECT
- scope "geographic-mismatch" AND audience_fit "weak" → REJECT
- supporting strength "weak" AND counter-evidence "significant" → REJECT
- audience_awareness "high" AND predicted_reception "redundant" → REJECT
- If counter-evidence recommends REFINE → update the thesis
- Otherwise → VALIDATE

### 4. Update Pitch Memos
For validated pitches: set `status: validated`, add `validated_date`, append validation report section.
For rejected pitches: set `status: rejected`, add `rejected_date` and `rejected_reason`, move to `pipeline/rejected/` using Bash mv.

### 5. Output Format
Return:

VALIDATE_COMPLETE
validated: {count}
rejected: {count}
results:
- {pitch-id}: {headline} — {verdict}
```

After the subagent returns, parse output and commit:

```
git add pipeline/010_pitches/ pipeline/rejected/
```

Commit message: `Validate pitches: {N} validated, {M} rejected`

If the validate subagent fails, log the error and continue to Step 6 (to process any already-validated pitches).

## Step 6: Execute Editorial Stage

**Check**: Use Glob to re-scan `pipeline/010_pitches/*.md`. Read each and filter for `status: validated`.

If no validated pitches, skip to Step 7.

If work exists, read context needed for editorial decisions:
- Recent publications from `pipeline/050_published/`, `pipeline/040_review/`, `pipeline/030_drafts/`
- Active campaigns from `campaigns/active/`
- Available author baselines from `voice-models/authors/*/baseline.md`
- Brand guidelines from `voice-models/brand-guidelines.md`

Dispatch a Task subagent (subagent_type: "general-purpose", model: "sonnet"):

```
You are the Editorial Stage agent of an autonomous editorial pipeline. Act as editorial director — evaluate validated pitches, approve or kill, assign authors, write production briefs. You must operate with ZERO human interaction.

## Editorial Mission
{Paste PUBLICATION.md content}

## Quality Thresholds and Content Mix Targets
{Paste config.md content}

## Recent Publication History
{List recent headlines, content types, authors from pipeline/050_published/, pipeline/040_review/, pipeline/030_drafts/, pipeline/020_approved/}

## Active Campaigns
{Paste campaign details}

## Available Authors
{For each author: name, expertise summary from baseline, available styles}

## Brand Guidelines
{Paste brand-guidelines.md content}

## Validated Pitches to Review
{List validated pitch file paths}

## Your Task

### 1. Read Each Validated Pitch Memo

### 2. Evaluate Against Decision Criteria
- **Value threshold**: Would a busy professional stop scrolling?
- **Source strength**: At least 1 Tier 1/2 source, 2+ total, supporting evidence "moderate" or better
- **Editorial mix**: Avoid topic clustering, balance content types against targets
- **Campaign fit**: Prioritise campaign-aligned if quality sufficient
- **Redundancy**: Kill if recently published
- **Timeliness**: Fast-track time-sensitive angles

### 3. Render Decisions: APPROVE, KILL, or HOLD

### 4. Assign Authors (NON-INTERACTIVE)
For each approved piece:
1. Read all author baselines — extract expertise, tone, strengths
2. Score each author for this pitch:
   - Expertise match to topic: 0-4 points
   - Tone/style fit: 0-3 points
   - Workload balance (penalise if already assigned in this run): 0-2 points
   - Pitch memo recommended_author match: +1 bonus
3. Select highest scorer. If tied, prefer pitch memo's recommended_author.
4. Select style modifier based on content type:
   - Deep Analysis → style-deep-analysis
   - Commentary → style-commentary
   - Regulatory → style-regulatory
   - Practitioner Insights / Market Pulse → baseline (no modifier)
5. Verify the style file exists: `voice-models/authors/{author}/style-{style}.md`. If missing, fall back to baseline.
6. Document rationale in production brief.

### 5. Write Production Briefs
For each approved angle, write to `pipeline/020_approved/brief-{YYYY-MM-DD}-{NNN}.md` with YAML frontmatter (id, date, status: ready, pitch_id, author, style, content_type, target_length, audience, campaign, timeliness, deadline) and body (Approved Thesis, Source Inventory with primary/supporting/counter-arguments, Structure Guidance, Voice Notes, Do-Not-Include List, Editorial Decision Rationale).

### 6. Update Pitch Memos
- Approved: set `status: approved`, add `brief_id`
- Killed: set `status: rejected`, add `rejected_date`, `rejected_reason`, move to `pipeline/rejected/`
- Held: set `status: held`, add `hold_reason`, `hold_date`

### 7. Write Editorial Feedback
Write carry-forward notes to `pipeline/editorial-feedback.md` for any production notes (overlap warnings, framing guidance), angle guidance (data to recycle, underrepresented content types), research guidance (coverage gaps, beats to prioritise), or held pitch triggers. Also review and address any open entries whose conditions have been met. See the editorial skill for the entry format. Only write entries when there is specific, actionable intelligence — not for routine decisions.

### 8. Output Format
Return:

EDITORIAL_COMPLETE
approved: {count}
killed: {count}
held: {count}
approved_list:
- {brief-id}: {headline} — {author}/{style} — {content type}
killed_list:
- {pitch-id}: {headline} — {reason}
```

After the subagent returns, parse output and commit:

```
git add pipeline/020_approved/ pipeline/010_pitches/ pipeline/rejected/ pipeline/editorial-feedback.md
```

Commit message: `Editorial review: {N} approved, {M} killed, {K} held`

If the editorial subagent fails, log the error and continue to Step 7 (to process any already-ready briefs).

## Step 7: Execute Produce Stage

**Check**: Use Glob to re-scan `pipeline/020_approved/*.md`. Read each and filter for `status: ready`.

If no ready briefs, skip to Step 8.

If work exists, read brand guidelines from `voice-models/brand-guidelines.md` and formatting conventions from `FORMATTING.md` (if it exists).

Dispatch a Task subagent (subagent_type: "general-purpose"):

```
You are the Produce Stage agent of an autonomous editorial pipeline. Write article drafts from production briefs using the three-layer voice model.

## Editorial Mission
{Paste PUBLICATION.md content}

## Brand Voice Constraints (Layer 1 — HARD RULES)
{Paste brand-guidelines.md content}

## Formatting Conventions
{Paste FORMATTING.md content, or omit this section if FORMATTING.md does not exist}

## Ready Briefs
{List ready brief file paths}

## Your Task

For each ready brief:

### 1. Mark Brief Status
Edit the brief frontmatter: set `status: in-production`.

### 2. Load Voice Model
- Layer 2: Read `voice-models/authors/{author}/baseline.md`
- Layer 3: Read `voice-models/authors/{author}/style-{style}.md` (if specified)

### 3. Load Source Material
Read each signal file referenced in the brief's source inventory from `knowledge-base/signals/`.

### 4. Check Editorial Feedback
Read `pipeline/editorial-feedback.md` if it exists. Filter for open `production-note` entries targeting `produce`. If a note's `context` references a brief you are about to produce, include the note in the production subagent's prompt as an "Editorial Director's Note" section. After producing, mark consumed entries as addressed.

### 5. Dispatch Production Subagent (Task, model: "sonnet")
Prompt the production subagent with:
- CRITICAL RULES: synthesis not summarisation, no AI tells, specific over general, earned opinions
- Full brand guidelines, author baseline, style modifier
- Full production brief (thesis, sources, structure guidance, voice notes, do-not-include list)
- Full source material from signal reports
- Target word count from brief
- Output format: ---DRAFT_START--- / ---DRAFT_END--- with WORD_COUNT and PRODUCTION_NOTES

### 6. Save Draft
Write to `pipeline/030_drafts/draft-{YYYY-MM-DD}-{NNN}.md` with YAML frontmatter (id, date, status: draft, brief_id, pitch_id, author, style, content_type, word_count, revision: 0, max_revisions: 2, audience) and body (article text, Production Metadata section with notes and source references).

### 7. Update Brief
Edit brief frontmatter: set `status: produced`, add `draft_id`.

### 8. Output Format
Return:

PRODUCE_COMPLETE
drafts_written: {count}
drafts:
- {draft-id}: {headline} — {author} — {word count} words
```

After the subagent returns, parse output and commit:

```
git add pipeline/030_drafts/ pipeline/020_approved/ pipeline/editorial-feedback.md
```

Commit message: `Produce drafts: {N} articles written`

If the produce subagent fails, log the error and continue to Step 8 (to process any already-existing drafts).

## Step 8: Execute Quality Stage

**Check**: Use Glob to re-scan `pipeline/030_drafts/*.md`. Read each and filter for `status: draft` or `status: revision`.

If no drafts awaiting quality check, skip to Step 9.

If work exists, read brand guidelines and config (max revisions).

Dispatch a Task subagent (subagent_type: "general-purpose"):

```
You are the Quality Stage agent of an autonomous editorial pipeline. Assess all drafts against the 7-criteria quality gate. Pass drafts to human review, return for revision (max 2 cycles), or kill.

## Quality Criteria
{Paste PUBLICATION.md quality criteria}

## Configuration
Max revisions: {from config.md, default 2}

## Brand Guidelines
{Paste brand-guidelines.md content}

## Drafts for Review
{List draft file paths with current revision count}

## Your Task

For each draft:

### 1. Load Context
- Read the draft file
- Read the corresponding production brief from `pipeline/020_approved/{brief_id}.md`
- Read the author baseline from `voice-models/authors/{author}/baseline.md`
- Read the style modifier from `voice-models/authors/{author}/style-{style}.md` (if any)

### 2. Dispatch Quality Assessment Subagent (Task, model: "sonnet")
The assessor evaluates 7 criteria, each scored PASS/REVISE/FAIL:
1. **Insight Density** — no filler paragraphs, no repetition, no generic observations
2. **Source Fidelity** — all claims traceable, no misrepresentation, no over-extrapolation
3. **Thesis Delivery** — thesis established clearly, every section advances it, clear conclusion
4. **AI-Tell Scan** — no hedging, no false balance, no empty transitions, no formulaic openings/closings, no generic phrasing
5. **Voice Match** — vocabulary, rhythm, opening/closing style, perspective match the author
6. **Novelty** — combines sources in new ways, informed readers learn something
7. **Readability** — opening hooks, structured for scanning, appropriate length, maintains momentum

Output format: ---QUALITY_REPORT--- with Overall Verdict (PASS/REVISE/KILL), Criterion Scores table, Detailed Feedback (what works, what needs improvement), Specific Revision Instructions ---END_QUALITY_REPORT---

### 3. Process Verdicts

**PASS**: Update frontmatter: `status: passed`, add `quality_passed_date`. Append quality report. Rename and move to `pipeline/040_review/`, changing the `draft-` prefix to `for-review-` (e.g., `draft-2026-02-10-001.md` → `for-review-2026-02-10-001.md`).

**REVISE**: If `revision < max_revisions`:
- Increment revision count, set `status: revision`
- Dispatch a revision subagent (Task) with: current draft, quality feedback, voice model. Subagent makes ONLY the specified changes, preserves voice.
- Save revised draft, re-run quality assessment (loop back)
If `revision >= max_revisions`: KILL the draft.

**KILL**: Set `status: killed`, add `killed_reason`. Move to `pipeline/rejected/` (Bash mv). Update corresponding brief status.

### 4. Output Format
Return:

QUALITY_COMPLETE
passed: {count}
revised_and_passed: {count}
killed: {count}
first_pass_rate: {percentage}
passed_list:
- {draft-id}: {headline} — pipeline/040_review/{filename}
killed_list:
- {draft-id}: {headline} — {reason}
```

After the subagent returns, parse output and commit:

```
git add pipeline/040_review/ pipeline/030_drafts/ pipeline/rejected/ pipeline/020_approved/
```

Commit message: `Quality gate: {N} passed, {M} revised, {K} killed`

If the quality subagent fails, log the error — never auto-pass drafts.

## Step 9: Write Run Summary and Final Report

Count the final state:
- Use Glob to count files now in `pipeline/040_review/` (compare to baseline from Step 1 to determine how many are new)
- Compile results from each stage

Write the run report to `metrics/run-{YYYY-MM-DD-HHmm}.md`:

```markdown
# Newsroom Run Summary — {date} {time}

## Result
{N} articles moved to human review this run.

## Stage Results

### Research
- Signals produced: {count}
- Beats processed: {count}
- Sources checked: {count}
{Or: "Skipped — no active beats or local sources"}

### Angle
- Pitch memos written: {count}
- Angles killed by quality filter: {count}
{Or: "Skipped — no viable signals"}

### Validate
- Validated: {count}
- Rejected: {count}
{Or: "Skipped — no pending pitches"}

### Editorial
- Approved: {count}
- Killed: {count}
- Held: {count}
{Or: "Skipped — no validated pitches"}

### Produce
- Drafts written: {count}
{Or: "Skipped — no ready briefs"}

### Quality
- Passed: {count}
- Revised and passed: {count}
- Killed: {count}
- First-pass rate: {percentage}
{Or: "Skipped — no drafts to review"}

## Articles Ready for Human Review
{For each article now in pipeline/040_review/:}
1. **{Headline}** ({draft-id})
   - Author: {author} / Style: {style}
   - Content type: {type}
   - Word count: {count}
   - Path: pipeline/040_review/{filename}

## Pipeline Status
- Pending pitches: {count}
- Held pitches: {count}
- Ready briefs: {count}
- Drafts in progress: {count}
- Articles awaiting review: {total count}
- Editorial feedback: {open count} open entries ({breakdown by type})

## Errors
{List any stage failures or subagent errors, or "None"}

## Next Step
{If articles in review > 0: "Run `/review` to approve, revise, or kill the articles now awaiting human review."}
{If no articles: "No articles to review. The next `/run` will check for new signals."}
```

Output the summary to stdout. Then commit:

```
git add metrics/run-*.md
```

Commit message: `Run complete: {N} articles to review`

If no articles were produced and no errors occurred, the commit message should be: `Run complete: no new articles this cycle`

## Error Handling

### Stage Failures
- **Research or Angle failure**: Log error, continue to next stage. Later stages may have pending work from prior runs.
- **Validate, Editorial, Produce, or Quality failure**: Log error, skip stages that depend on the failed stage's output, but still process any independently pending work at later stages and write the run summary.
- Never silently swallow errors — all failures must appear in the run summary.

### Sub-Subagent Failures
- If a per-beat research agent fails: log it, continue with other beats.
- If 1 of 4 validation agents fails: proceed with 3 of 4 reports. Flag if counter-evidence agent failed (critical).
- If a production agent fails: keep brief at `status: ready` for retry next run.
- If a quality assessment agent fails: never auto-pass. Keep draft at current status for retry next run.

### Quality Standards
- Never auto-pass a draft that has any FAIL criterion.
- Never lower quality standards to produce output.
- Zero articles is a valid and expected outcome.
- The pipeline should kill most candidates at each stage — this is by design.

### Git Failures
- If a git commit fails, log the error and continue. Do not abort the run.
- Report all commit failures in the final summary.

### Missing Files
- Missing `config.md`: use defaults (scan mode, 80-step budget, 2 max revisions).
- Missing `PUBLICATION.md`: this is critical — abort the run. The editorial mission is required.
- Missing voice model files for an assigned author: skip that brief, report the error.
- Missing signal files referenced in a brief: continue with available sources, flag the gap.

</process>
