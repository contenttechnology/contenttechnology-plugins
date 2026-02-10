---
name: revoice
description: Re-produce an existing draft with a different author's voice — fresh write from the original brief, full quality gate, lineage tracking.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, AskUserQuestion
---

<objective>
Re-produce an existing quality-approved or published draft with a different author's voice. Instead of transforming the existing text, this skill writes fresh from the original production brief with a new author/style assignment — producing the most authentic voice possible. The new draft goes through the full quality gate. Both drafts share the same `pitch_id` for lineage tracking.

Use this when editorial wants to test how a different author would handle the same angle, or when an article needs to reach a different audience segment via a different voice.
</objective>

<process>

## Step 1: Scan for Eligible Drafts

Use Glob to find drafts in both locations:
- `pipeline/review/*.md` — quality-approved drafts awaiting human review
- `pipeline/published/*.md` — published drafts

Read each file. Parse YAML frontmatter and filter for drafts with `status: passed` or `status: published`. Extract:
- `id` (draft ID)
- `date` (production date)
- `author` (author name)
- `style` (style slug)
- `content_type` (content type)
- `word_count` (approximate word count)
- `brief_id` (production brief ID)
- `pitch_id` (original pitch ID)

Also extract the headline from the first `#` heading in the markdown body (after frontmatter).

If no eligible drafts are found, report:
```
No eligible drafts for revoicing. Drafts must have passed quality review or been published.
Run /run or /quality first to get drafts through the pipeline.
```
And exit.

## Step 2: Select Draft

Use AskUserQuestion to present eligible drafts.

**Question**: "Which draft would you like to revoice with a different author?"

**Options**: One option per draft (max 4 — if more exist, show the 4 most recent first), formatted as:

- **Label**: `{Headline}` (truncated to fit)
- **Description**: `{author}/{style} — {word_count} words — {content_type} — {date} — {status}`

If there are more than 4 eligible drafts, note in the question text how many total are available.

If the user selects "Other" with exit intent, exit the skill.

## Step 3: Load Original Production Brief

Read the selected draft's metadata. Load its original production brief from `pipeline/approved/{brief_id}.md`.

If the brief file exists, extract:
- Thesis
- Source inventory (primary and supporting sources with signal IDs)
- Structure guidance
- Counter-arguments
- Voice notes
- Do-not-include list
- `pitch_id`

If the brief is missing, reconstruct essentials from the draft itself:
- Extract the thesis from the article's opening and structure
- Extract source references from the draft's Production Metadata section
- Use the draft's frontmatter for `pitch_id`, `content_type`, `audience`
- Log a note that the brief was reconstructed

## Step 4: Select New Author and Style

Use Glob to list available authors: `voice-models/authors/*/baseline.md`

Exclude the current author (from the selected draft's frontmatter). For each remaining author, also check available style modifiers: `voice-models/authors/{name}/style-*.md`.

If no other authors are available, report:
```
No alternative authors available for revoicing. Add another author with /add-author first.
```
And exit.

Use AskUserQuestion to present author options.

**Question**: "Which author should write the new version?"

**Options**: One option per available author (max 4), formatted as:

- **Label**: `{Author Name}`
- **Description**: `Styles: {comma-separated list of available style slugs, e.g. "deep-analysis, commentary, baseline-only"}`

After author selection, if the selected author has style modifiers available, use AskUserQuestion to select the style.

**Question**: "Which style should {author} write in?"

**Options**: One option per available style, plus a baseline option:

- **Label**: `{style-slug}` — **Description**: "Style modifier: {style-slug}"
- **Label**: `Baseline only` — **Description**: "Write in {author}'s baseline voice with no style modifier"

If the selected author has no style modifiers, use baseline only and skip this question.

## Step 5: Confirm Revoicing

Use AskUserQuestion to confirm and optionally capture custom voice notes.

**Question**: "Confirm revoicing: **{headline}** from {original-author}/{original-style} → {new-author}/{new-style}. Any custom voice notes?"

**Options**:
- **Label**: "Confirm" — **Description**: "Proceed with revoicing as shown"
- **Label**: "Add voice notes" — **Description**: "Add custom voice direction (use Other to type)"
- **Label**: "Cancel" — **Description**: "Abort revoicing"

If the user selects "Cancel" or "Other" with cancel intent, exit the skill.

If the user selects "Add voice notes" or provides text via "Other", capture those as custom voice notes for the production brief.

## Step 6: Create Variant Production Brief

Read existing briefs in `pipeline/approved/` to determine the next sequential number for today: `brief-{YYYY-MM-DD}-{NNN}.md`.

Create a variant production brief in `pipeline/approved/` by copying the original brief's content with the following changes:

### Frontmatter
```yaml
---
id: brief-{YYYY-MM-DD}-{NNN}
date: {YYYY-MM-DD}
status: in-production
pitch_id: {original pitch_id — same as original brief}
author: {new-author}
style: {new-style}
content_type: {same as original}
target_length: {same as original}
audience: [{same as original}]
campaign: {same as original}
timeliness: {same as original}
revoice_of: {original-brief-id}
variant: true
---
```

### Body
Copy the original brief's body content (thesis, source inventory, structure guidance, counter-arguments, do-not-include list) with these updates:

- **Voice Notes**: Replace the original author/style assignment with the new author/style. Include rationale: "Revoiced from {original-author}/{original-style} to explore {new-author}'s voice on this angle."
- If custom voice notes were provided, add them under a `### Custom Voice Direction` sub-heading within the Voice Notes section.
- Add a `## Revoice Context` section at the end:
  ```
  ## Revoice Context
  This is a voice variant of {original-brief-id}. The original was produced as {original-draft-id} by {original-author}/{original-style}.
  Write fresh in the new voice — do not mimic, copy, or transform the original draft.
  ```

## Step 7: Load Voice Model

Load the 3-layer voice model for the new author:

1. Read `voice-models/brand-guidelines.md` (Layer 1 — brand constraints)
2. Read `voice-models/authors/{new-author}/baseline.md` (Layer 2 — author baseline)
3. Read `voice-models/authors/{new-author}/style-{new-style}.md` (Layer 3 — style modifier, if specified)

If the author baseline file is missing, abort:
```
Cannot revoice: voice model for {new-author} not found at voice-models/authors/{new-author}/baseline.md.
Voice authenticity is critical — do not substitute. Add the author with /add-author first.
```

If a style modifier was selected but the file is missing, use AskUserQuestion:

**Question**: "Style modifier `{style}` not found for {author}. Use baseline voice instead?"
**Options**:
- **Label**: "Use baseline" — **Description**: "Proceed with {author}'s baseline voice only"
- **Label**: "Abort" — **Description**: "Cancel revoicing"

### Load Source Signals

Read each signal file referenced in the brief's source inventory:
- Read primary sources from `knowledge-base/signals/{signal-id}.md`
- Read supporting sources from `knowledge-base/signals/{signal-id}.md`

If any signal files are missing, note the gap but proceed with available sources. Add a flag in the production notes.

## Step 8: Produce New Draft

Dispatch a production subagent via Task (subagent_type: "general-purpose", model: "sonnet"):

```
You are a production writer for the Newsroom. Your job is to write a complete article draft that delivers the approved thesis in the assigned author's voice.

## CRITICAL RULES — READ FIRST
1. SYNTHESIS, NEVER SUMMARISATION: Weave sources together. Never present sources sequentially ("According to X... Meanwhile, Y says..."). Instead, build arguments where evidence from multiple sources supports each point.
2. NO AI TELLS: Never use these patterns:
   - "In today's rapidly evolving..." or any variant
   - "Let's dive in" / "Let's explore"
   - "It's worth noting that..."
   - "In conclusion" / "To summarise"
   - "The landscape is shifting"
   - Excessive hedging: "it could be argued", "some might say"
   - False balance: presenting both sides as equal when evidence favours one
   - Empty transitions: "Moving on to...", "Another important aspect..."
3. SPECIFIC OVER GENERAL: Every claim must be backed by a specific data point, quote, or reference. "Revenue increased" is bad. "Revenue climbed 14% to $1.2B" is good.
4. EARNED OPINIONS: Strong positions are welcome when supported by evidence. Clearly distinguish between reported facts and editorial opinion.

## Voice Variant — IMPORTANT
This is a revoiced piece. An earlier version of this article was written by a different author. You are writing FRESH in your assigned voice. Do NOT mimic, copy, or transform the original. Approach the brief as if you are writing this piece for the first time. Your voice, your angle on the thesis, your rhythm.

## Brand Voice Constraints (HARD RULES — cannot be violated)
{Paste full brand-guidelines.md content}

## Your Author Voice: {new-author name}
{Paste full baseline.md content}

## Style Modifier: {new-style name}
{Paste full style modifier content, or "No style modifier — write in baseline voice" if none}

{If custom voice notes exist:}
## Custom Voice Direction
{Paste custom voice notes}

## Production Brief
{Paste the full production brief including thesis, source inventory, structure guidance, counter-arguments, and do-not-include list}

## Source Material
{For each source referenced in the brief, paste the signal report content:}

### {signal-id}: {summary}
{Full signal report content}

---

## Your Task

Write a complete article draft that:
1. Delivers the approved thesis through genuine synthesis of the source material
2. Follows the structure guidance from the brief
3. Sounds authentically like {new-author} writing in {new-style} mode
4. Respects all brand voice constraints
5. Falls within the target length: {word range}
6. Addresses the counter-arguments identified in the brief
7. Delivers a clear "so what?" for the target audience: {audience segments}
8. Avoids everything on the do-not-include list

## Output Format

Return the complete draft in this exact format:

---DRAFT_START---
{The complete article, ready for quality review. Include a headline. Do not include metadata or frontmatter — just the article text.}
---DRAFT_END---

WORD_COUNT: {approximate word count}

PRODUCTION_NOTES: {Any notes about choices you made, compromises, or areas where the brief was ambiguous. 2-3 sentences max.}
```

If the production subagent fails, report the error, update the variant brief to `status: failed`, and exit. Do not attempt to auto-generate a draft.

## Step 9: Save New Draft

Parse the `---DRAFT_START---` / `---DRAFT_END---` block from the subagent response.

### Filename Convention
`draft-{YYYY-MM-DD}-{NNN}.md` — check existing files in `pipeline/drafts/` to determine the next sequential number.

### Draft File Format

```markdown
---
id: draft-{YYYY-MM-DD}-{NNN}
date: {YYYY-MM-DD}
status: draft
brief_id: {variant-brief-id}
pitch_id: {original pitch_id — same as original draft}
author: {new-author}
style: {new-style}
content_type: {content type}
word_count: {approximate count}
revision: 0
max_revisions: 2
audience: [{audience segments}]
revoice_of: {original-draft-id}
original_brief: {original-brief-id}
variant: true
---

{Complete article text from the subagent — headline and body}

---

## Production Metadata

### Production Notes
{Notes from the production subagent}
{If sources were missing, flag here}

### Revoice Lineage
- Original draft: {original-draft-id}
- Original author: {original-author}/{original-style}
- Original brief: {original-brief-id}
- Variant brief: {variant-brief-id}

### Source References
{List of signal IDs used, for traceability}

### Brief Reference
See `pipeline/approved/{variant-brief-id}.md` for the variant production brief.
```

### Update Variant Brief Status

Edit the variant production brief frontmatter to set `status: produced` and add `draft_id: {new-draft-id}`.

## Step 10: Quality Gate

Dispatch a quality assessment subagent via Task (subagent_type: "general-purpose", model: "sonnet"):

```
You are a quality gate assessor for the Newsroom. Your job is to ruthlessly evaluate an article draft against seven quality criteria. You must be honest and rigorous — passing a weak draft wastes human reviewer time and damages editorial credibility.

## The Draft
{Paste the complete article text}

## The Production Brief
{Paste the full variant production brief — thesis, sources, structure guidance, voice notes}

## Brand Voice Guidelines
{Paste brand-guidelines.md}

## Author Voice Model
{Paste the NEW author's baseline.md — this is the voice to evaluate against}

## Style Modifier
{Paste the NEW style modifier content, or "No style modifier — baseline voice only"}

## Revision History
This is revision {N} of max 2.
{If revision > 0, paste previous quality feedback here}

## Quality Assessment Criteria

Evaluate the draft against EACH of these seven criteria. For each, assign: PASS, REVISE, or FAIL.

### 1. Insight Density
Does every section add new information? Are there filler paragraphs? Look for:
- Paragraphs that could be deleted without losing information
- Repetition of the same point in different words
- Generic observations that any reader already knows
- "Setup" paragraphs that delay getting to the point

### 2. Source Fidelity
Are all claims traceable to sources in the brief? Look for:
- Claims that aren't supported by any referenced source
- Misrepresentation of source material
- Over-extrapolation from limited data
- Sources used but not actually relevant to the claim they support

### 3. Thesis Delivery
Does the piece deliver on its promised thesis, or does it drift? Look for:
- Does the opening establish the thesis clearly?
- Does every section advance the thesis?
- Does the piece arrive at a clear conclusion that follows from the evidence?
- Does it drift into tangential topics?

### 4. AI-Tell Scan
Does the writing contain AI-typical patterns? Look for ALL of these:
- Hedging: "it could be argued", "some might say", "it remains to be seen"
- False balance: presenting weak counter-arguments as equal to strong evidence
- Empty transitions: "Moving on to", "Another important aspect", "It's worth noting"
- Formulaic openings: "In today's...", "The landscape of..."
- Formulaic closings: "In conclusion", "To summarise", "Only time will tell"
- Generic phrasing: "a wide range of", "various stakeholders", "significant impact"
- Excessive qualification: stacking hedges ("could potentially perhaps")
- List-heavy structure: using bullet points where prose would be stronger
- Paragraph-level repetition: restating the same idea in slightly different words

### 5. Voice Match
Does this read authentically as the assigned author in the assigned style? Look for:
- Does the vocabulary match the author's preferences and prohibitions?
- Does the sentence rhythm match the author's style?
- Does the opening match the author's opening style?
- Does the closing match the author's closing style?
- Does the perspective align with the author's stance?
- If a style modifier is applied, are the adjustments reflected?

### 6. Novelty
Would an informed reader learn something new? Look for:
- Does this combine sources in a way that creates new insight?
- Is the thesis genuinely original or just repackaging known information?
- Would an industry professional who reads trade publications find value?
- Does the "so what?" deliver actionable or thought-provoking insight?

### 7. Readability
Would a busy professional read past the first 200 words? Look for:
- Does the opening hook grab attention immediately?
- Is the piece structured for scanning (headers, short paragraphs)?
- Is the length appropriate for the content type?
- Is the pacing right — does it maintain momentum?
- Are there sections where a reader would lose interest?

## Output Format

Return your assessment in this exact format:

---QUALITY_REPORT---

## Overall Verdict: {PASS | REVISE | KILL}

## Criterion Scores

| Criterion | Score | Notes |
|-----------|-------|-------|
| Insight Density | {PASS/REVISE/FAIL} | {one-line note} |
| Source Fidelity | {PASS/REVISE/FAIL} | {one-line note} |
| Thesis Delivery | {PASS/REVISE/FAIL} | {one-line note} |
| AI-Tell Scan | {PASS/REVISE/FAIL} | {one-line note} |
| Voice Match | {PASS/REVISE/FAIL} | {one-line note} |
| Novelty | {PASS/REVISE/FAIL} | {one-line note} |
| Readability | {PASS/REVISE/FAIL} | {one-line note} |

## Detailed Feedback

### What Works Well
{2-3 specific things the draft does well}

### What Needs Improvement
{For each REVISE/FAIL criterion, specific and actionable feedback:}
- **{Criterion}**: {Exactly what's wrong and exactly how to fix it. Be specific — cite paragraphs or sentences.}

### Specific Revision Instructions
{If verdict is REVISE: numbered list of specific changes to make. Each instruction should be concrete and actionable.}
{If verdict is KILL: explanation of why this draft cannot be salvaged.}
{If verdict is PASS: any minor suggestions that don't block approval.}

---END_QUALITY_REPORT---
```

If the quality subagent fails, report the error. Do not auto-pass. Keep the draft in `pipeline/drafts/` and exit.

## Step 11: Process Quality Verdict

### PASS

1. Update draft frontmatter: `status: passed`, add `quality_passed_date: {YYYY-MM-DD}`
2. Append the quality report to the draft file
3. Rename and move to `pipeline/review/` using Bash `mv`, changing the `draft-` prefix to `for-review-` (e.g., `draft-2026-02-10-001.md` becomes `for-review-2026-02-10-001.md`)

### REVISE

1. Check the revision count: `revision` field in frontmatter
2. If `revision < 2` (max 2 revision cycles):
   - Update frontmatter: `status: revision`, increment `revision` by 1
   - Append the quality feedback to the draft
   - Dispatch a revision subagent (Task, subagent_type: "general-purpose", model: "sonnet"):

   ```
   You are revising a draft that did not pass quality review. Make ONLY the changes specified in the revision instructions. Do not rewrite sections that passed. Preserve the author's voice.

   ## Current Draft
   {Paste the current draft text}

   ## Quality Feedback
   {Paste the detailed feedback and revision instructions}

   ## Voice Model (for reference — maintain this voice)
   {Paste new author baseline}

   ## Style Modifier
   {Paste new style modifier}

   ## Revision Instructions
   Make these specific changes:
   {Paste the numbered revision instructions from the quality report}

   ## Output Format
   Return the revised draft in this format:

   ---REVISED_DRAFT---
   {Complete revised article text}
   ---END_REVISED_DRAFT---

   CHANGES_MADE:
   {List each change you made, referencing the instruction number}
   ```

   - Save the revised draft (overwrite the article body, preserve frontmatter and metadata)
   - Re-run the quality assessment (back to Step 10)

3. If `revision >= 2`:
   - Draft has failed too many times. Kill it.
   - Update frontmatter: `status: killed`, add `killed_reason: "Failed quality gate after 2 revisions"`
   - Move to `pipeline/rejected/` using Bash `mv`
   - Update the variant brief to `status: killed`

### KILL

1. Update frontmatter: `status: killed`, add `killed_reason` from the quality report
2. Move draft to `pipeline/rejected/` using Bash `mv`
3. Update the variant brief to `status: killed`

## Step 12: Summary Output

```markdown
## Revoice Complete — {date}

### Original Draft
- **Draft**: {original-draft-id}
- **Author**: {original-author} / {original-style}
- **Headline**: {headline}

### New Variant
- **Draft**: {new-draft-id}
- **Author**: {new-author} / {new-style}
- **Quality verdict**: {PASS / REVISE+PASS / KILLED}
- **Revisions**: {count}
- **Location**: `{pipeline/review/ or pipeline/rejected/}{filename}`

### Lineage
- **Pitch**: {pitch_id}
- **Original brief**: {original-brief-id}
- **Variant brief**: {variant-brief-id}
- Both drafts share the same pitch_id for editorial lineage tracking.

### Next Steps
{If PASS: "The revoiced draft is in `pipeline/review/` — run /review to approve, revise, or kill."}
{If KILLED: "The revoiced draft did not pass quality. Review the quality report in `pipeline/rejected/{filename}` for details."}
```

## Step 13: Git Commit

Stage all new and modified files:
- `pipeline/approved/*.md` (variant brief)
- `pipeline/drafts/*.md` or `pipeline/review/*.md` or `pipeline/rejected/*.md` (new draft)

Commit with:
```
Revoice: "{headline}" as {new-author}/{new-style}

- Original: {original-draft-id} by {original-author}/{original-style}
- Variant brief: {variant-brief-id}
- Variant draft: {new-draft-id}
- Quality: {verdict}
```

## Error Handling

- **Missing style modifier for target author**: Offer baseline fallback via AskUserQuestion or abort. Do not silently substitute.
- **Missing original production brief**: Reconstruct essentials from the draft's metadata and article content. Log the reconstruction. Proceed.
- **Missing voice model files (baseline)**: Abort immediately. Do not substitute another author's voice — voice authenticity is critical.
- **Missing source signal files**: Proceed with available sources. Flag the gap in production notes so the quality gate and human reviewer are aware.
- **Production subagent failure**: Report the error. Update variant brief to `status: failed`. Do not auto-generate.
- **Quality subagent failure**: Report the error. Do not auto-pass. Keep draft in `pipeline/drafts/` for manual review.
- **No eligible drafts**: Report and exit cleanly.
- **No alternative authors**: Report and exit — need at least 2 authors for revoicing.
- **Git commit failure**: Log the error, report in summary. Do not fail the skill over a git issue.

</process>
