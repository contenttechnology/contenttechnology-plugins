---
name: quality
description: Run the quality gate on drafts and packages — assess against editorial criteria, pass to human review, return for revision, or kill.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep
---

<objective>
Assess every draft and content package in `pipeline/030_drafts/` against the quality gate. Article drafts (files starting with `draft-article-`) are evaluated on the existing 7 criteria. Content packages (files starting with `draft-package-`) are evaluated at both package-level and per-format level. Passing items move to `pipeline/040_review/` for human review. Failing items are returned for revision or killed. This is the final automated checkpoint before human eyes.
</objective>

<process>

## Step 1: Load Drafts and Packages for Review

Use Glob to find all files: `pipeline/030_drafts/*.md`

Read each file. Filter for:
- `status: draft` — new items awaiting first quality review
- `status: revision` — items returned from a previous quality review with feedback

Skip `status: passed` and `status: killed`.

**Detect file type from frontmatter or filename:**
- Has `content_type` field (or filename starts with `draft-article-`) → **article draft** (existing quality flow)
- Has `package_tier` field (or filename starts with `draft-package-`) → **content package** (new package quality flow)

Separate into two lists: article drafts and content packages.

If no items are found, report "No drafts or packages to review. Run /produce first." and exit.

## Step 2: Load Quality Context

Read the following:

1. **`PUBLICATION.md`** — Editorial mission and quality criteria
2. **`config.md`** — Max revision cycles (default: 2)
3. **`voice-models/brand-guidelines.md`** — Brand constraints to check against
4. **`FORMATTING.md`** — Formatting conventions to check against (if it exists)

For each draft, also read:
- The corresponding production brief from `pipeline/020_approved/{brief_id}.md`
- The assigned author's voice model from `voice-models/authors/{author}/baseline.md`
- The style modifier (if any) from `voice-models/authors/{author}/style-{style}.md`

## Step 3: Dispatch Article Quality Assessment

For each **article draft**, dispatch a Task subagent (subagent_type: "general-purpose") for quality assessment.

```
You are a quality gate assessor for the Newsroom. Your job is to ruthlessly evaluate an article draft against seven quality criteria. You must be honest and rigorous — passing a weak draft wastes human reviewer time and damages editorial credibility.

## The Draft
{Paste the complete article text}

## The Production Brief
{Paste the full production brief — thesis, sources, structure guidance, voice notes}

## Brand Voice Guidelines
{Paste brand-guidelines.md}

## Author Voice Model
{Paste the author's baseline.md}

## Style Modifier
{Paste the style modifier content, or "No style modifier — baseline voice only"}

## Formatting Conventions
{Paste FORMATTING.md content, or "No formatting conventions file found — assess readability using general best practices"}

## Revision History
This is revision {N} of max {max_revisions}.
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
- Does the formatting follow the conventions in FORMATTING.md? (paragraph length, heading structure, list usage, emphasis, etc.)

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

## Step 3b: Dispatch Package Quality Assessment

For each **content package**, dispatch a Task subagent (subagent_type: "general-purpose") for package quality assessment.

The package quality assessment evaluates both package-level coherence and per-format quality in a single pass.

```
You are a quality gate assessor for the Newsroom. Your job is to ruthlessly evaluate a content package against both package-level coherence and per-format quality criteria. You must be honest and rigorous — passing a weak package wastes human reviewer time and damages editorial credibility.

## The Package
{Paste the complete package content — all format sections}

## The Production Brief
{Paste the full production brief — thesis, sources, structure guidance, voice notes}

## Brand Voice Guidelines
{Paste brand-guidelines.md}

## Author Voice Model
{Paste the author's baseline.md}

## Style Modifier
{Paste the style modifier content, or "No style modifier — baseline voice only"}

## Package Metadata
- Package tier: {light | full | thread-only}
- Primary platform: {linkedin | x}
- Primary format: {determined by primary_platform}

## Revision History
This is revision {N} of max {max_revisions} (1 for packages).
{If revision > 0, paste previous quality feedback here}

## Package-Level Quality Checks

Evaluate the package as a whole:

### 1. Thesis Coherence
Do ALL formats express the same underlying angle/thesis? Each format should be a different expression of the same core insight. Flag any format that has drifted to a different thesis.
- PASS: All formats clearly express the same thesis
- REVISE: One or more formats have drifted — identify which
- FAIL: Package lacks a coherent thesis across formats

### 2. Format Independence
Does each format work entirely on its own? A reader seeing only the LinkedIn post should get the full insight. A reader seeing only a tweet should get value. No format should depend on having read another.
- PASS: Each format is self-contained
- REVISE: One or more formats depend on context from another — identify which
- FAIL: Multiple formats are derivatives rather than independent compositions

### 3. No Copy-Paste
Are formats independently composed, not truncated or excerpted from each other? The LinkedIn post should not read like a long version of the tweet. The tweet should not read like a trimmed LinkedIn post.
- PASS: Each format is clearly independently written
- REVISE: One or more formats appear derived — identify which and instruct to rewrite from scratch
- FAIL: Package is clearly one piece cut into different lengths

### 4. Reusable Line Quality
Do the reusable lines work standalone in a reply/comment context? Apply the "text to a colleague" test — would you send this as a standalone message?
- PASS: Lines work as standalone replies/comments
- REVISE: Lines need reworking — too dependent on context or too generic
- FAIL: Lines are excerpts rather than independently crafted

## Format-Level Quality Checks

Evaluate EACH format individually against these 7 criteria. Apply format-appropriate interpretation:

### Per-Format: 1. Insight Density
- For tweets: Every word must earn its place. Under 280 chars with genuine insight.
- For LinkedIn: No filler paragraphs, no repetition, no generic observations.
- For reusable lines: Each line must deliver a standalone insight.

### Per-Format: 2. Source Fidelity
- For tweets: Lighter bar — no room for citations, but claims must be accurate.
- For LinkedIn: Claims should be traceable even if not explicitly cited.
- For threads: Key claims in thread should reference evidence.

### Per-Format: 3. Thesis Delivery
- For all formats: Does this specific format clearly deliver the thesis?

### Per-Format: 4. AI-Tell Scan
- Same patterns to watch for across all formats, plus format-specific tells:
  - Tweets: "🧵" emoji threading, numbered lists (1/), "A thread on..."
  - LinkedIn: "I'm excited to share", "Thought leaders agree", "Here are my key takeaways:"
  - All: Hedging, false balance, empty transitions, generic phrasing

### Per-Format: 5. Voice Match
- Check against the author's baseline voice
- Check against the per-format style modifier (observational for tweets, analytical for threads, etc.)
- The author should sound like themselves across all formats, with appropriate register shifts

### Per-Format: 6. Novelty
- Same standard: Would an informed reader learn something from this specific format?

### Per-Format: 7. Readability
- For tweets: Reads naturally, not compressed or awkward
- For LinkedIn: Opening hooks, structured for scanning, appropriate length
- For threads: Each tweet has momentum, the thread builds interest
- For reusable lines: Natural conversational tone

## Output Format

Return your assessment in this exact format:

---QUALITY_REPORT---

## Overall Verdict: {PASS | REVISE | KILL}

## Package-Level Assessment

| Check | Result | Notes |
|-------|--------|-------|
| Thesis Coherence | {PASS/REVISE/FAIL} | {one-line note} |
| Format Independence | {PASS/REVISE/FAIL} | {one-line note} |
| No Copy-Paste | {PASS/REVISE/FAIL} | {one-line note} |
| Reusable Line Quality | {PASS/REVISE/FAIL} | {one-line note} |

## Format-Level Assessment

### LinkedIn Post
| Criterion | Score | Notes |
|-----------|-------|-------|
| Insight Density | {PASS/REVISE/FAIL} | {note} |
| Source Fidelity | {PASS/REVISE/FAIL} | {note} |
| Thesis Delivery | {PASS/REVISE/FAIL} | {note} |
| AI-Tell Scan | {PASS/REVISE/FAIL} | {note} |
| Voice Match | {PASS/REVISE/FAIL} | {note} |
| Novelty | {PASS/REVISE/FAIL} | {note} |
| Readability | {PASS/REVISE/FAIL} | {note} |

{Repeat for each format in the package: X Thread, Standalone Tweets, Reusable Lines, LinkedIn Comment Version}

## Detailed Feedback

### What Works Well
{2-3 specific things the package does well}

### Package-Level Issues
{For each REVISE/FAIL package-level check: specific feedback}

### Format-Level Issues
{For each format with REVISE/FAIL criteria: specific and actionable feedback}
- **{Format} — {Criterion}**: {Exactly what's wrong and how to fix it}

### Specific Revision Instructions
{If verdict is REVISE: which specific formats need revision and what changes to make}
{If verdict is KILL: explanation of why this package cannot be salvaged}
{If verdict is PASS: any minor suggestions that don't block approval}

---END_QUALITY_REPORT---
```

### Package Revision Policy

When processing package quality verdicts:
- **One format fails** → revise only that format, hold the rest unchanged
- **Primary format fails** → revise the entire package (all formats)
- **Package can lose individual formats** — if a weak tweet doesn't pass after revision, drop it from the package and keep the rest
- **Max one revision cycle per format** — format doesn't pass after one revision → cut it from the package
- **Primary format doesn't pass after one revision** → kill the entire package

## Step 4: Process Quality Verdicts

### 4a. Article Draft Verdicts

For each article draft, based on the subagent's quality report:

**PASS:**
1. Update the draft frontmatter: `status: passed`, add `quality_passed_date`
2. Append the quality report to the draft file (so human reviewers can see the assessment)
3. Move the draft to `pipeline/040_review/` using Bash `mv`. **Do NOT rename the file** — the filename must stay exactly the same (e.g., `mv pipeline/030_drafts/draft-article-2026-02-10-001.md pipeline/040_review/draft-article-2026-02-10-001.md`)
4. The draft is now ready for human review

**REVISE:**
1. Check the revision count: `revision` field in frontmatter
2. If `revision < max_revisions` (default 2):
   - Update frontmatter: `status: revision`, increment `revision` by 1
   - Append the quality feedback to the draft
   - The draft stays in `pipeline/030_drafts/` for the production agent to revise
   - **Dispatch a revision subagent** immediately (same prompt as production, but with the quality feedback included as revision instructions)
   - Save the revised draft, re-run quality assessment (recursive — up to max_revisions total)
3. If `revision >= max_revisions`:
   - This draft has failed too many times. Kill it.
   - Update frontmatter: `status: killed`, add `killed_reason: "Failed quality gate after {max_revisions} revisions"`
   - Move to `pipeline/rejected/`

**KILL:**
1. Update frontmatter: `status: killed`, add `killed_reason` from the quality report
2. Move draft to `pipeline/rejected/` using Bash `mv`
3. Update the corresponding production brief to `status: killed`

### 4b. Content Package Verdicts

For each content package, based on the subagent's quality report:

**PASS:**
1. Update the package frontmatter: `status: passed`, add `quality_passed_date`
2. Append the quality report to the package file
3. Move the package to `pipeline/040_review/` using Bash `mv`. **Do NOT rename the file** — the filename must stay exactly the same (e.g., `mv pipeline/030_drafts/draft-package-2026-02-10-001.md pipeline/040_review/draft-package-2026-02-10-001.md`)
4. The package is now ready for human review

**REVISE:**
1. Check the revision count: `revision` field in frontmatter
2. If `revision < max_revisions` (1 for packages):
   - Update frontmatter: `status: revision`, increment `revision` by 1
   - Append the quality feedback to the package
   - Determine which formats need revision from the quality report
   - **Dispatch a package revision subagent** (see Step 5b below)
   - Save the revised package, re-run quality assessment
3. If `revision >= max_revisions` (1):
   - Check if the primary format failed:
     - **Primary format failed** → Kill the entire package
     - **Non-primary format(s) failed** → Drop the failed formats from the package, keep the rest, set `status: passed` if remaining formats all pass
   - For killed packages: Update frontmatter: `status: killed`, add `killed_reason`, move to `pipeline/rejected/`

**KILL:**
1. Update frontmatter: `status: killed`, add `killed_reason` from the quality report
2. Move package to `pipeline/rejected/` using Bash `mv`
3. Update the corresponding production brief to `status: killed`

## Step 5: Handle Article Revisions Inline

When an article draft receives a REVISE verdict and has remaining revision cycles:

1. Dispatch a revision subagent (subagent_type: "general-purpose") with:

```
You are revising a draft that did not pass quality review. Make ONLY the changes specified in the revision instructions. Do not rewrite sections that passed. Preserve the author's voice.

## Current Draft
{Paste the current draft text}

## Quality Feedback
{Paste the detailed feedback and revision instructions}

## Voice Model (for reference — maintain this voice)
{Paste author baseline}

## Style Modifier
{Paste style modifier}

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

2. Save the revised draft (overwrite the current draft file body, update revision count)
3. Re-run the quality assessment on the revised draft (back to Step 3)

This creates a loop: draft → quality check → revise → quality check → revise → quality check → pass or kill.

## Step 5b: Handle Package Revisions Inline

When a content package receives a REVISE verdict and has remaining revision cycles:

1. Dispatch a package revision subagent (subagent_type: "general-purpose") with:

```
You are revising a content package that did not pass quality review. Revise ONLY the formats specified in the revision instructions. Do not rewrite formats that passed. Preserve the author's voice.

## Current Package
{Paste the complete package content — all format sections}

## Quality Feedback
{Paste the detailed feedback and revision instructions}

## Formats to Revise
{List only the specific formats that need revision, from the quality report}

## Formats to KEEP UNCHANGED
{List formats that passed — do not modify these}

## Voice Model (for reference — maintain this voice)
{Paste author baseline}

## Style Modifier
{Paste style modifier}

## Revision Instructions
Make these specific changes to the flagged formats:
{Paste the format-specific revision instructions from the quality report}

IMPORTANT: Return the COMPLETE package including both revised and unchanged formats.

## Output Format
Return the revised package in this format:

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
{List each change you made, referencing which format and which instruction}
```

2. Save the revised package (overwrite the format sections in the package file, update revision count)
3. Re-run the quality assessment on the revised package (back to Step 3b)

## Step 6: Summary Output

```markdown
## Quality Gate Summary — {date}

### Articles Passed to Human Review: {count}
{For each passed article draft:}
1. **{Headline}** ({draft-id})
   - Author: {author} / Style: {style}
   - All 7 criteria: PASS
   - Moved to: pipeline/040_review/

### Packages Passed to Human Review: {count}
{For each passed package:}
1. **{Headline}** ({pkg-id})
   - Author: {author} / Tier: {tier} / Platform: {platform}
   - Package-level: PASS / Format-level: {N} of {M} formats PASS
   - Formats dropped: {list any dropped formats, or "None"}
   - Moved to: pipeline/040_review/

### Revised and Passed: {count}
{Items that passed after revision:}
1. **{Headline}** ({id})
   - Type: {article | package}
   - Revisions: {count}
   - Initially failed: {criteria or formats}
   - Now: PASS

### Killed: {count}
{For each killed item:}
1. **{Headline}** ({id})
   - Type: {article | package}
   - Reason: {killed reason}
   - Revisions attempted: {count}

### Quality Metrics
- Articles: first-pass rate {percentage}, revision success rate {percentage}, kill rate {percentage}
- Packages: first-pass rate {percentage}, revision success rate {percentage}, kill rate {percentage}
- Most common issues: {list top 2-3 failing criteria}

### Review Documents

| Item | Type | Verdict | Document |
|------|------|---------|----------|
{For each passed article (first-pass):}
| {Headline} | Article | PASS | `pipeline/040_review/draft-article-{id}.md` |
{For each passed package (first-pass):}
| {Headline} | Package | PASS | `pipeline/040_review/draft-package-{id}.md` |
{For each revised-and-passed item:}
| {Headline} | {Type} | REVISED → PASS | `pipeline/040_review/{filename}` |
{For each killed item:}
| {Headline} | {Type} | KILLED | `pipeline/rejected/{filename}` |

### Next Step
Run `review` to approve, revise, or kill the drafts and packages that passed the quality gate.
```

## Step 7: Git Commit

Stage all new and modified files:
- `pipeline/040_review/*.md` (passed drafts moved here)
- `pipeline/030_drafts/*.md` (updated status on remaining drafts)
- `pipeline/rejected/*.md` (killed drafts moved here)
- `pipeline/020_approved/*.md` (updated brief status for killed drafts)

```
Quality gate: {N} passed ({A} articles, {P} packages), {M} revised, {K} killed

Passed to review:
- {draft-1}: "{headline}" (article)
- {pkg-1}: "{headline}" (package)
Killed:
- {draft-2}: "{headline}" ({reason})
```

## Error Handling

- If the quality subagent fails or returns unparseable output, keep the draft at current status and report the error. Do not auto-pass.
- If a voice model file is missing (can't assess voice match), proceed with the other 6 criteria and note "Voice match: SKIPPED (model not found)" in the report.
- If the production brief is missing (can't assess thesis delivery or source fidelity), flag the draft for manual review and move to `pipeline/040_review/` with a note.
- Never auto-pass a draft that has any FAIL criterion — revision or kill is mandatory.
- The quality gate should kill pieces. A 100% pass rate means the gate is too lenient.

</process>
