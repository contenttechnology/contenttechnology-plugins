---
name: review
description: Interactive human review of quality-approved drafts and content packages — approve, revise with feedback, or kill with reasoning.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, AskUserQuestion
---

<objective>
Interactive skill for human review of quality-approved drafts and content packages in `pipeline/040_review/`. The human selects an item, reads it, and decides: approve, revise, or kill. For content packages, additional options include selective approval (keep some formats, drop others) and format-specific revision. Revision feedback is applied by a production subagent and re-assessed by the quality gate before returning to the review queue. Every decision is logged and committed.
</objective>

<process>

## Step 1: Load Items for Review

Use Glob to find all files: `pipeline/040_review/*.md`

Read each file. Parse YAML frontmatter and detect the item type:

**Article drafts** (has `content_type` field, or filename starts with `draft-article-`):
- `id` (draft ID)
- `date` (production date)
- `author` (author name)
- `style` (style slug)
- `content_type` (content type)
- `word_count` (approximate word count)
- `brief_id` (production brief ID)
- `pitch_id` (original pitch ID)
- `revision` (automated quality revision count)
- `human_revision` (human revision count — may not exist yet, default 0)
- `rush` (boolean, if present)

**Content packages** (has `package_tier` field, or filename starts with `draft-package-`):
- `id` (package ID)
- `date` (production date)
- `author` (author name)
- `style` (style slug)
- `package_tier` (light | full | thread-only)
- `primary_platform` (linkedin | x)
- `related_brief_id` (companion article brief ID, if dual output)
- `brief_id` (production brief ID)
- `pitch_id` (original pitch ID)
- `revision` (automated quality revision count)
- `human_revision` (human revision count — may not exist yet, default 0)

Also extract the headline from the first `#` heading in the markdown body (after frontmatter). Count the number of format sections (## headings) in packages.

If no items are found, report:
```
No drafts or packages awaiting review. The pipeline has not produced any quality-approved items.
Run /run or /quality first.
```
And exit.

## Step 2: Present Review Queue

Use AskUserQuestion to show the review queue.

**Question**: "These items are ready for review. Which would you like to review?"

**Options**: One option per item (max 4 — if more exist, show the 4 oldest first), formatted as:

For **article drafts**:
- **Label**: `{Headline}` (truncated to fit)
- **Description**: `[Article] {author}/{style} — {word_count} words — {content_type} — {date}` plus any flags:
  - If `rush: true`: append `[RUSH]`
  - If `human_revision > 0`: append `[Revised {N}x]`

For **content packages**:
- **Label**: `{Headline}` (truncated to fit)
- **Description**: `[Package] {author} — {package_tier} — {primary_platform} — {N} formats — {date}` plus any flags:
  - If `related_brief_id` is not null: append `[Dual output]`
  - If `human_revision > 0`: append `[Revised {N}x]`

If there are more than 4 items, note in the question text how many total are waiting.

The user can select "Other" to exit the review session.

If the user selects "Other" with exit intent, proceed to Step 6 (session summary).

## Step 3: Present the Selected Item

Read the full content of the selected file. The presentation and decision options differ based on whether it's an article draft or a content package.

### 3a. Article Draft Presentation

Present to the human:

1. **Metadata summary**:
   ```
   Draft: {id}
   Date: {date}
   Author: {author} / Style: {style}
   Content Type: {content_type}
   Word Count: {word_count}
   Revisions: {revision} automated, {human_revision} human
   Brief: {brief_id}
   ```

2. **Quality report**: If a quality report section is appended to the draft (from `quality`), display a condensed version showing the 7 criterion scores table.

3. **Full article text**: The complete draft body.

Then use AskUserQuestion:

**Question**: "What is your decision for this draft?"

**Options**:
- **Label**: "Approve" — **Description**: "Publish this draft — move to pipeline/050_published/"
- **Label**: "Revise" — **Description**: "Send back with feedback for revision and quality re-assessment"
- **Label**: "Kill" — **Description**: "Reject this draft — move to pipeline/rejected/ with reasoning"

### 3b. Content Package Presentation

Present to the human:

1. **Metadata summary**:
   ```
   Package: {id}
   Date: {date}
   Author: {author} / Style: {style}
   Package Tier: {package_tier}
   Primary Platform: {primary_platform}
   Related Article Brief: {related_brief_id or "None (standalone package)"}
   Revisions: {revision} automated, {human_revision} human
   Brief: {brief_id}
   ```

2. **Quality report**: If a quality report is appended, display both the package-level assessment table and the per-format scores tables.

3. **Full package content**: Display the entire package with all formats clearly separated. Show each format section with its heading.

Then use AskUserQuestion:

**Question**: "What is your decision for this package?"

**Options**:
- **Label**: "Approve all" — **Description**: "Approve the entire package — all formats move to pipeline/050_published/"
- **Label**: "Approve selectively" — **Description**: "Pick which formats to keep, drop the rest"
- **Label**: "Revise formats" — **Description**: "Send specific formats back for revision with targeted feedback"
- **Label**: "Kill package" — **Description**: "Reject the entire package — move to pipeline/rejected/"

## Step 4a: Approve Path (Articles)

When the human selects "Approve" for an article draft:

1. **Optional notes**: Use AskUserQuestion:
   - **Question**: "Any notes to log with the approval? (Recorded for calibration, won't change the draft.)"
   - **Options**:
     - **Label**: "No notes" — **Description**: "Approve as-is"
     - **Label**: "Add notes" — **Description**: "Record minor observations (use Other to type)"

2. **Update frontmatter** via Edit:
   - Set `status: published`
   - Update `id`: strip the `draft-` prefix (e.g., `draft-article-2026-02-10-001` becomes `article-2026-02-10-001`)
   - Add `published_date: {YYYY-MM-DD}`
   - Add `approved_by: human`
   - If notes provided, add `approval_notes: {notes}`

3. **Move and rename file** via Bash: strip the `draft-` prefix from the filename (e.g., `mv pipeline/040_review/draft-article-2026-02-10-001.md pipeline/050_published/article-2026-02-10-001.md`)

4. **Write decision log** to `metrics/review-{YYYY-MM-DD-HHmm}-{article-id}.md`:

```markdown
---
type: review-decision
draft_id: {draft-id}
date: {YYYY-MM-DDTHH:mm}
decision: approved
author: {author}
style: {style}
content_type: {content_type}
word_count: {word_count}
quality_revisions: {revision}
human_revisions: {human_revision}
---

## Review Decision: Approved

**Draft**: {headline}
**Decision**: Approved for publication
**Notes**: {approval notes or "None"}
```

5. **Git commit** via Bash:
```
Review: approve "{headline}"

- Published to pipeline/050_published/
- Author: {author}/{style}
- {word_count} words
```

## Step 4a-pkg: Approve Path (Packages)

### Approve All

When the human selects "Approve all" for a content package:

1. **Per-format publication timing**: Use AskUserQuestion:
   - **Question**: "How should the formats be published? You can stagger timing."
   - **Options**:
     - **Label**: "Publish all now" — **Description**: "All formats ready for immediate publication"
     - **Label**: "Stagger timing" — **Description**: "Specify timing per format (use Other to describe)"
     - **Label**: "Bank for later" — **Description**: "Approve but hold all formats for strategic timing"

2. **Update frontmatter** via Edit:
   - Set `status: published`
   - Update `id`: strip the `draft-` prefix (e.g., `draft-package-2026-02-10-001` becomes `package-2026-02-10-001`)
   - Add `published_date: {YYYY-MM-DD}`
   - Add `approved_by: human`
   - Add `formats_published` metadata tracking per-format publish status:
     ```yaml
     formats_published:
       linkedin_post:
         published: false
       tweet_1:
         published: false
       tweet_2:
         published: false
       reusable_lines:
         published: false
     ```
   - If timing notes provided, add `publication_timing: {notes}`

3. **Move and rename file** via Bash: strip the `draft-` prefix from the filename (e.g., `mv pipeline/040_review/draft-package-2026-02-10-001.md pipeline/050_published/package-2026-02-10-001.md`)

4. **Write decision log** to `metrics/review-{YYYY-MM-DD-HHmm}-{package-id}.md`:

```markdown
---
type: review-decision
package_id: {package-id}
date: {YYYY-MM-DDTHH:mm}
decision: approved
author: {author}
style: {style}
package_tier: {tier}
primary_platform: {platform}
format_count: {count}
quality_revisions: {revision}
human_revisions: {human_revision}
---

## Review Decision: Package Approved

**Package**: {headline}
**Decision**: All formats approved for publication
**Timing**: {publication timing or "Immediate"}
**Notes**: {approval notes or "None"}
```

5. **Git commit** via Bash:
```
Review: approve package "{headline}"

- Published to pipeline/050_published/
- Author: {author} / Tier: {tier} / Platform: {platform}
- {format_count} formats approved
```

### Approve Selectively

When the human selects "Approve selectively":

1. **Format selection**: Use AskUserQuestion (multiSelect: true):
   - **Question**: "Which formats do you want to keep? Unselected formats will be dropped."
   - **Options**: One option per format section found in the package:
     - **Label**: "LinkedIn Post" — **Description**: First line preview
     - **Label**: "X Thread" — **Description**: "{N} tweets"
     - **Label**: "Standalone Tweets" — **Description**: "{N} tweets"
     - **Label**: "Reusable Lines" — **Description**: "{N} lines"
     - **Label**: "LinkedIn Comment" — **Description**: First line preview
   (Only show formats that exist in the package)

2. **Remove dropped formats** from the package body via Edit. Add `formats_dropped: [{list of dropped format names}]` to frontmatter.

3. **Update frontmatter and move** — same as "Approve all" flow above, with `formats_published` only listing kept formats.

4. **Write decision log** noting which formats were kept and which were dropped.

5. **Git commit**:
```
Review: selectively approve package "{headline}"

- Kept: {list of kept formats}
- Dropped: {list of dropped formats}
```

## Step 4b: Revise Path (Articles)

When the human selects "Revise" for an article draft:

1. **Capture revision notes**: Use AskUserQuestion:
   - **Question**: "What needs to change? Be as specific as possible — cite paragraphs, sentences, or sections. (Use Other to type your feedback.)"
   - **Options**:
     - **Label**: "Strengthen opening" — **Description**: "The opening doesn't hook — needs a stronger lead"
     - **Label**: "More evidence" — **Description**: "Claims need stronger data or source support"
     - **Label**: "Voice issues" — **Description**: "Doesn't sound like this author — tone or style is off"
     - **Label**: "Restructure" — **Description**: "The flow or structure needs reworking"
   - The user will typically use "Other" for detailed notes, but preset options provide quick feedback for common issues.

2. **Update draft frontmatter** via Edit:
   - Set `status: human-revision`
   - Add or increment `human_revision` (default 0 + 1)
   - Add `human_revision_notes: {the notes}`

3. **Load voice model context**:
   - Read `voice-models/brand-guidelines.md`
   - Read `voice-models/authors/{author}/baseline.md`
   - Read `voice-models/authors/{author}/style-{style}.md` (if style is specified in frontmatter)
   - Read the corresponding production brief from `pipeline/020_approved/{brief_id}.md`

   If author voice model files are missing, report the error and skip the revision. Ask the human if they want to approve as-is or kill instead.

4. **Dispatch revision subagent** via Task (subagent_type: "general-purpose", model: "sonnet"):

```
You are revising a draft that received human review feedback. Make ONLY the changes specified in the revision notes. Do not rewrite sections the reviewer did not mention. Preserve the author's voice exactly.

## Current Draft
{Paste the complete article text}

## Human Reviewer Feedback
{Paste the human's revision notes}

## Voice Model (maintain this voice exactly)

### Brand Guidelines
{Paste brand-guidelines.md}

### Author Baseline: {author}
{Paste baseline.md}

### Style Modifier: {style}
{Paste style modifier content, or "No style modifier — baseline voice only"}

## Production Brief (for reference)
{Paste the thesis and structure guidance from the brief, or "Brief not available" if missing}

## Instructions
1. Address every point in the human reviewer's feedback
2. Do NOT rewrite sections that were not mentioned
3. Preserve the author's voice and style throughout
4. Maintain the original thesis and structure unless the feedback specifically asks for changes
5. Keep the same approximate word count unless the feedback implies length changes

## Output Format
---REVISED_DRAFT---
{Complete revised article text — full article, not just changed sections}
---END_REVISED_DRAFT---

CHANGES_MADE:
{Numbered list of each change you made, referencing which feedback point it addresses}
```

5. **Save revised draft**: Parse the `---REVISED_DRAFT---` block from the subagent response. Overwrite the article body in the draft file (preserve frontmatter and production metadata). Update frontmatter via Edit:
   - Set `status: revision`
   - Increment `revision` count

6. **Move file** via Bash: `mv pipeline/040_review/{filename} pipeline/030_drafts/{filename}`

7. **Dispatch quality re-assessment** via Task (subagent_type: "general-purpose", model: "sonnet"):

```
You are a quality gate assessor for the Newsroom. Your job is to ruthlessly evaluate an article draft against seven quality criteria. You must be honest and rigorous — passing a weak draft wastes human reviewer time and damages editorial credibility.

## The Draft
{Paste the complete revised article text}

## The Production Brief
{Paste the full production brief — thesis, sources, structure guidance, voice notes. Or "Brief not available" if missing.}

## Brand Voice Guidelines
{Paste brand-guidelines.md}

## Author Voice Model
{Paste the author's baseline.md}

## Style Modifier
{Paste the style modifier content, or "No style modifier — baseline voice only"}

## Revision History
This draft has been through {revision} automated revision(s) and {human_revision} human revision(s).
Latest human feedback: {human_revision_notes}

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
{If verdict is REVISE: numbered list of specific changes to make.}
{If verdict is KILL: explanation of why this draft cannot be salvaged.}
{If verdict is PASS: any minor suggestions that don't block approval.}

---END_QUALITY_REPORT---
```

8. **Process quality verdict**:

   - **PASS**: Move draft back to `pipeline/040_review/` via Bash `mv pipeline/030_drafts/{filename} pipeline/040_review/{filename}`. Update frontmatter: `status: passed`. Append quality report to the draft. The draft re-enters the review queue for the human to see the result on their next review pass.

   - **REVISE or KILL**: The human triggered this revision and should see the result. Move back to `pipeline/040_review/` via Bash `mv pipeline/030_drafts/{filename} pipeline/040_review/{filename}`. Set `status: passed`. Append quality report with a note: "Quality gate flagged issues after human-requested revision. Review the quality report below." Let the human decide on the next pass.

9. **Write decision log** to `metrics/review-{YYYY-MM-DD-HHmm}-{draft-id}.md`:

```markdown
---
type: review-decision
draft_id: {draft-id}
date: {YYYY-MM-DDTHH:mm}
decision: revise
author: {author}
style: {style}
content_type: {content_type}
human_revision_number: {N}
quality_reassessment: {PASS|REVISE|KILL}
---

## Review Decision: Revise

**Draft**: {headline}
**Decision**: Sent back for revision (human revision {N})
**Feedback**: {human's revision notes}
**Quality re-assessment**: {verdict}
**Changes made**: {summary of changes from revision subagent}
```

10. **Git commit** via Bash:
```
Review: revise "{headline}" (human revision {N})

- Human feedback applied and quality re-assessed
- Quality verdict: {verdict}
- Draft returned to pipeline/040_review/
```

If the revision subagent fails, report the error, keep the draft in `pipeline/040_review/` unchanged, and ask the human if they want to approve as-is or kill instead.

If the quality re-assessment subagent fails, move the revised draft back to `pipeline/040_review/` without a quality report. Note that quality was not re-assessed. Let the human decide.

## Step 4b-pkg: Revise Path (Packages)

When the human selects "Revise formats" for a content package:

1. **Select formats to revise**: Use AskUserQuestion (multiSelect: true):
   - **Question**: "Which formats need revision? Select all that apply."
   - **Options**: One option per format section found in the package (same as selective approve list)

2. **Capture per-format feedback**: For each selected format, use AskUserQuestion:
   - **Question**: "What needs to change in the {format name}? Be as specific as possible."
   - **Options**:
     - **Label**: "Stronger hook" — **Description**: "The opening doesn't grab attention"
     - **Label**: "Voice issues" — **Description**: "Doesn't sound like this author"
     - **Label**: "Too generic" — **Description**: "Needs more specific data or insight"
     - **Label**: "Restructure" — **Description**: "The flow or structure needs reworking"
   - The user will typically use "Other" for detailed notes.

3. **Update frontmatter** via Edit:
   - Set `status: human-revision`
   - Add or increment `human_revision`
   - Add `human_revision_notes: {combined per-format feedback}`
   - Add `formats_flagged: [{list of formats being revised}]`

4. **Load voice model context** (same as article revise path — brand guidelines, author baseline, style modifier, production brief).

5. **Dispatch package revision subagent** via Task (subagent_type: "general-purpose", model: "sonnet"):

```
You are revising specific formats in a content package that received human review feedback. Revise ONLY the formats specified below. Do NOT modify formats that were not flagged. Preserve the author's voice exactly.

## Complete Current Package
{Paste the complete package content — all format sections. The reviewer needs to see the full context.}

## Formats to Revise (ONLY modify these)
{For each flagged format:}
### {Format Name}
**Feedback**: {human's per-format revision notes}

## Formats to KEEP UNCHANGED (do NOT modify)
{List all formats NOT flagged for revision}

## Voice Model (maintain this voice exactly)

### Brand Guidelines
{Paste brand-guidelines.md}

### Author Baseline: {author}
{Paste baseline.md}

### Style Modifier: {style}
{Paste style modifier content, or "No style modifier — baseline voice only"}

## Production Brief (for reference)
{Paste the thesis and structure guidance from the brief}

## Instructions
1. Address every point in the human reviewer's feedback for each flagged format
2. Do NOT rewrite formats that were not flagged
3. Preserve the author's voice and style throughout
4. Maintain thesis coherence across all formats
5. Return the COMPLETE package including both revised and unchanged formats

## Output Format
---REVISED_PACKAGE---

## LinkedIn Post
{content — revised or unchanged}

## X Thread
{content — revised or unchanged}

## Standalone Tweets
{content — revised or unchanged}

## Reusable Lines
{content — revised or unchanged}

## LinkedIn Comment Version
{content — revised or unchanged, if applicable}

---END_REVISED_PACKAGE---

CHANGES_MADE:
{List each change you made, referencing which format and which feedback point it addresses}
```

6. **Save revised package**: Parse the `---REVISED_PACKAGE---` block. Overwrite the format sections in the package file (preserve frontmatter and production metadata). Update frontmatter:
   - Set `status: revision`
   - Increment `revision` count

7. **Move file** via Bash: `mv pipeline/040_review/{filename} pipeline/030_drafts/{filename}`

8. **Dispatch quality re-assessment** — use the same package quality assessment prompt from the quality skill (Step 3b). The full package-level + format-level assessment is re-run.

9. **Process quality verdict**: Same as article revise path — move back to `pipeline/040_review/` regardless of quality verdict so the human sees the result on their next pass.

10. **Write decision log** and **git commit** (similar to article revise path, noting format-specific revisions).

## Step 4c: Kill Path

When the human selects "Kill" (for articles) or "Kill package" (for packages):

1. **Capture kill reason**: Use AskUserQuestion:
   - **Question**: "Why are you killing this?" (applies to both articles and packages)
   - **Options**:
     - **Label**: "Thesis wrong" — **Description**: "The thesis is incorrect, outdated, or no longer relevant"
     - **Label**: "Not interesting" — **Description**: "Not valuable enough for our audience"
     - **Label**: "Already covered" — **Description**: "Topic already covered better elsewhere"
     - **Label**: "Quality issues" — **Description**: "Voice or quality problems beyond what revision can fix"
   - The user can also use "Other" to provide a custom reason.

2. **Update frontmatter** via Edit:
   - Set `status: killed`
   - Update `id`: strip the `draft-` prefix (e.g., `draft-article-2026-02-10-001` becomes `article-2026-02-10-001`, or `draft-package-2026-02-10-001` becomes `package-2026-02-10-001`)
   - Add `killed_by: human`
   - Add `killed_date: {YYYY-MM-DD}`
   - Add `killed_reason: {reason}`

3. **Move and rename file** via Bash: strip the `draft-` prefix from the filename (e.g., `mv pipeline/040_review/draft-article-2026-02-10-001.md pipeline/rejected/article-2026-02-10-001.md`)

4. **Update corresponding production brief**: Read `brief_id` from the draft frontmatter. Edit the brief in `pipeline/020_approved/{brief_id}.md` to set `status: killed`. If the brief file is not found, log the gap and continue.

5. **Write decision log** to `metrics/review-{YYYY-MM-DD-HHmm}-{id}.md`:

For **article drafts**:
```markdown
---
type: review-decision
draft_id: {draft-id}
date: {YYYY-MM-DDTHH:mm}
decision: killed
author: {author}
style: {style}
content_type: {content_type}
killed_reason: {reason}
quality_revisions: {revision}
human_revisions: {human_revision}
---

## Review Decision: Killed

**Draft**: {headline}
**Decision**: Killed
**Reason**: {kill reason}
**Revisions before kill**: {revision} automated, {human_revision} human
```

For **content packages**:
```markdown
---
type: review-decision
package_id: {package-id}
date: {YYYY-MM-DDTHH:mm}
decision: killed
author: {author}
style: {style}
package_tier: {tier}
primary_platform: {platform}
killed_reason: {reason}
quality_revisions: {revision}
human_revisions: {human_revision}
---

## Review Decision: Package Killed

**Package**: {headline}
**Decision**: Killed
**Reason**: {kill reason}
**Formats**: {list of formats in the package}
**Revisions before kill**: {revision} automated, {human_revision} human
```

6. **Git commit** via Bash:
```
Review: kill "{headline}"

- Reason: {killed reason}
- Moved to pipeline/rejected/
```

## Step 5: Loop Behaviour

After processing one item, re-scan `pipeline/040_review/` using Glob to get a fresh count (revision processing may have added an item back).

If more items remain, use AskUserQuestion:
- **Question**: "{N} more item(s) waiting for review ({A} articles, {P} packages). Continue?"
- **Options**:
  - **Label**: "Yes" — **Description**: "Review the next item"
  - **Label**: "No" — **Description**: "Done for now — exit review session"

If "Yes", return to Step 2 (re-scan and present fresh queue).
If "No", proceed to Step 6.

## Step 6: Session Summary

Output a summary of all decisions made in this session:

```markdown
## Review Session Summary — {date}

### Decisions Made: {total count}

#### Articles Approved: {count}
{For each approved article draft:}
1. **{Headline}** ({article-id}) — Published to pipeline/050_published/

#### Packages Approved: {count}
{For each approved package:}
1. **{Headline}** ({package-id}) — {approval type: all/selective} — {format_count} formats
   {If selective: "Kept: {list}, Dropped: {list}"}

#### Revised: {count}
{For each revised item:}
1. **{Headline}** ({id}) — [{Article|Package}] Human revision {N}, quality re-assessment: {verdict}
   {If package: "Formats revised: {list}"}

#### Killed: {count}
{For each killed item:}
1. **{Headline}** ({id}) — [{Article|Package}] Reason: {reason}

### Remaining in Review: {count}
{List any unreviewed items still in pipeline/040_review/ with type indicator}

### Pipeline Status
- In review: {count} ({A} articles, {P} packages)
- Published (total): {count in pipeline/050_published/}
- Rejected (total): {count in pipeline/rejected/}

### Next Steps
{If remaining in review > 0: "Run `review` again to continue reviewing remaining items."}
{If remaining == 0 and published > 0: "All items reviewed. Run `run` to start the next pipeline cycle."}
```

## Error Handling

- **No drafts in review**: Report and exit cleanly. No AskUserQuestion needed.
- **Missing voice model files during revision**: Report the error, skip the revision, ask the human if they want to approve as-is or kill.
- **Missing production brief during revision**: Proceed with revision using only the draft text and human feedback. Note the gap. The brief is "for reference" — not critical for targeted revisions.
- **Revision subagent failure**: Report the error, keep the draft at its current location in `pipeline/040_review/`, ask the human whether to retry, approve as-is, or kill.
- **Quality re-assessment subagent failure**: Move the revised draft back to `pipeline/040_review/` without quality report. Note that quality was not re-assessed. Let the human decide.
- **Git commit failure**: Log the error, continue with the review session. Report all git failures in the session summary.
- **File move failure**: Report the error, do not proceed with that draft. The draft remains in its current location.

</process>
