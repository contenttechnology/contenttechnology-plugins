---
name: quality
description: Run the quality gate on drafts — assess against editorial criteria, pass to human review, return for revision, or kill.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep
---

<objective>
Assess every draft in `pipeline/drafts/` against the quality gate checklist. Each draft is evaluated on insight density, source fidelity, thesis delivery, AI-tell detection, voice match, novelty, and readability. Passing drafts move to `pipeline/review/` for human review. Failing drafts are returned for revision (up to 2 cycles) or killed. This is the final automated checkpoint before human eyes.
</objective>

<process>

## Step 1: Load Drafts for Review

Use Glob to find all drafts: `pipeline/drafts/*.md`

Read each draft. Filter for:
- `status: draft` — new drafts awaiting first quality review
- `status: revision` — drafts returned from a previous quality review with feedback

Skip `status: passed` and `status: killed`.

If no drafts are found, report "No drafts to review. Run /produce first." and exit.

## Step 2: Load Quality Context

Read the following:

1. **`PUBLICATION.md`** — Editorial mission and quality criteria
2. **`config.md`** — Max revision cycles (default: 2)
3. **`voice-models/brand-guidelines.md`** — Brand constraints to check against

For each draft, also read:
- The corresponding production brief from `pipeline/approved/{brief_id}.md`
- The assigned author's voice model from `voice-models/authors/{author}/baseline.md`
- The style modifier (if any) from `voice-models/authors/{author}/style-{style}.md`

## Step 3: Dispatch Quality Assessment

For each draft, dispatch a Task subagent (subagent_type: "general-purpose") for quality assessment.

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

## Step 4: Process Quality Verdicts

For each draft, based on the subagent's quality report:

### PASS

1. Move the draft to `pipeline/review/` using Bash `mv`
2. Update the draft frontmatter: `status: passed`, add `quality_passed_date`
3. Append the quality report to the draft file (so human reviewers can see the assessment)
4. The draft is now ready for human review

### REVISE

1. Check the revision count: `revision` field in frontmatter
2. If `revision < max_revisions` (default 2):
   - Update frontmatter: `status: revision`, increment `revision` by 1
   - Append the quality feedback to the draft
   - The draft stays in `pipeline/drafts/` for the production agent to revise
   - **Dispatch a revision subagent** immediately (same prompt as production, but with the quality feedback included as revision instructions)
   - Save the revised draft, re-run quality assessment (recursive — up to max_revisions total)
3. If `revision >= max_revisions`:
   - This draft has failed too many times. Kill it.
   - Update frontmatter: `status: killed`, add `killed_reason: "Failed quality gate after {max_revisions} revisions"`
   - Move to `pipeline/rejected/`

### KILL

1. Update frontmatter: `status: killed`, add `killed_reason` from the quality report
2. Move draft to `pipeline/rejected/` using Bash `mv`
3. Update the corresponding production brief to `status: killed`

## Step 5: Handle Revisions Inline

When a draft receives a REVISE verdict and has remaining revision cycles:

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

## Step 6: Summary Output

```markdown
## Quality Gate Summary — {date}

### Passed to Human Review: {count}
{For each passed draft:}
1. **{Headline}** ({draft-id})
   - Author: {author} / Style: {style}
   - All 7 criteria: PASS
   - Moved to: pipeline/review/

### Revised and Passed: {count}
{Drafts that passed after revision:}
1. **{Headline}** ({draft-id})
   - Revisions: {count}
   - Initially failed: {criteria}
   - Now: PASS

### In Revision: {count}
{Drafts currently being revised — should be 0 at end of cycle}

### Killed: {count}
{For each killed draft:}
1. **{Headline}** ({draft-id})
   - Reason: {killed reason}
   - Revisions attempted: {count}

### Quality Metrics
- First-pass rate: {passed on first try / total} ({percentage})
- Revision success rate: {passed after revision / total revised}
- Kill rate: {killed / total}
- Most common issues: {list top 2-3 failing criteria}
```

## Step 7: Git Commit

Stage all new and modified files:
- `pipeline/review/*.md` (passed drafts moved here)
- `pipeline/drafts/*.md` (updated status on remaining drafts)
- `pipeline/rejected/*.md` (killed drafts moved here)
- `pipeline/approved/*.md` (updated brief status for killed drafts)

```
Quality gate: {N} passed, {M} revised, {K} killed

Passed to review:
- {draft-1}: "{headline}"
Killed:
- {draft-2}: "{headline}" ({reason})
```

## Error Handling

- If the quality subagent fails or returns unparseable output, keep the draft at current status and report the error. Do not auto-pass.
- If a voice model file is missing (can't assess voice match), proceed with the other 6 criteria and note "Voice match: SKIPPED (model not found)" in the report.
- If the production brief is missing (can't assess thesis delivery or source fidelity), flag the draft for manual review and move to `pipeline/review/` with a note.
- Never auto-pass a draft that has any FAIL criterion — revision or kill is mandatory.
- The quality gate should kill pieces. A 100% pass rate means the gate is too lenient.

</process>
