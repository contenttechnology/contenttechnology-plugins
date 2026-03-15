---
name: refine-voice
description: Synthesise accumulated style adaptations into targeted voice model updates — identifies recurring patterns across posted content and proposes specific refinements for human approval.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, AskUserQuestion
---

<objective>
Analyse accumulated style adaptation entries (logged by `/posted`) for a specific author and synthesise recurring patterns into concrete voice model updates. The skill identifies patterns that appear consistently across multiple posted pieces, proposes targeted additions to the author's baseline or style modifier files, and applies only human-approved changes. This creates a progressive learning loop: the more content the user posts and captures with `/posted`, the more accurately the voice model reflects their actual writing preferences.
</objective>

<critical-rule>
## MANDATORY: Human Approval for Every Voice Model Change

Voice model files are the foundation of content production quality. Every proposed change MUST be explicitly approved by the human before being applied (individually or via "Accept all remaining"). Never auto-apply changes without at least one explicit human approval action. If AskUserQuestion returns an empty or ambiguous response, re-ask. Do not infer approval.
</critical-rule>

<process>

## Step 1: Select Author

Use Glob to find adaptation files: `voice-models/authors/*/adaptations.md`

For each found file, read it and count entries under the "## Unprocessed Entries" section by counting `### AD-` headings in that section (entries between "## Unprocessed Entries" and "## Processed Entries").

If no adaptations.md files exist or all have zero unprocessed entries, report:
```
No adaptation data found. Use /posted to capture what you actually posted — the style differences accumulate here and feed into voice model refinement.
```
And exit.

Build a list of authors with unprocessed entries. For each, extract:
- Author name (from the directory path)
- Count of unprocessed entries
- Date range (oldest and newest `date` field from unprocessed entries)

If only one author has unprocessed entries, auto-select them and skip the question.

If multiple authors have data, use AskUserQuestion:

**Question**: "Which author's voice model would you like to refine?"

**Options**: One option per author with adaptation data, formatted as:
- **Label**: `{Author Name}`
- **Description**: `{N} unprocessed adaptations ({oldest date} to {newest date})`

## Step 2: Threshold Check

If the selected author has fewer than 5 unprocessed entries:

Use AskUserQuestion:

**Question**: "Only {N} adaptation entries for {author}. Minimum 5 recommended for reliable pattern detection. Results with fewer entries may be less accurate. Continue anyway?"

**Options**:
- **Label**: "Continue" — **Description**: "Proceed with {N} entries (results may be less reliable)"
- **Label**: "Wait" — **Description**: "Exit and collect more data with /posted first ({5 - N} more needed)"

If the user selects "Wait", exit with: "Run `/posted` after your next {5 - N} publications, then try `/refine-voice` again."

If the user selects "Continue", proceed with a flag that the dataset is below threshold.

## Step 3: Load Context

Read the following files:

1. `voice-models/authors/{author}/adaptations.md` — extract all unprocessed entries (the full text of each `### AD-` block under "## Unprocessed Entries")
2. `voice-models/authors/{author}/baseline.md` — current author baseline
3. All style modifiers: use Glob `voice-models/authors/{author}/style-*.md` and read each
4. `voice-models/brand-guidelines.md` — brand constraints that proposed changes must not violate

If `baseline.md` is missing, abort:
```
Cannot refine voice: baseline model for {author} not found at voice-models/authors/{author}/baseline.md.
Add the author with /add-author first.
```

## Step 4: Pattern Synthesis

Dispatch a Task subagent (subagent_type: "general-purpose"):

```
You are a voice model analyst for an editorial newsroom. Your job is to analyse style adaptation entries for a specific author and identify RECURRING patterns — changes that appear consistently across multiple posted pieces, not one-off edits.

## Author: {author}

## Current Voice Model

### Baseline
{Paste full baseline.md content}

### Style Modifiers
{For each style modifier file found:}
#### {style name}
{Paste full content}

### Brand Guidelines (HARD CONSTRAINTS — proposed changes must not violate these)
{Paste brand-guidelines.md content}

## Adaptation Entries ({N} total)

{Paste all unprocessed adaptation entries, each with its full content}

## Analysis Instructions

### Step 1: Pattern Identification

For each of the 7 style dimensions (tone_shifts, word_choice, structural_changes, brevity_preferences, punctuation_rhythm, platform_adaptation, evidence_handling), scan ALL entries and identify observations that appear in multiple entries.

A pattern is RECURRING if it appears in:
- 3 or more entries, OR
- 60% or more of total entries (whichever threshold is lower)

Weight recent entries more heavily than older ones.

### Step 2: Pattern Categorisation

For each recurring pattern, determine:

1. **Target file**: Does this pattern affect the author's general voice (→ baseline.md) or only specific content types/formats (→ the relevant style-{type}.md)?
   - If the pattern appears across multiple content types → baseline
   - If the pattern only appears for one content type or format → style modifier

2. **Target section**: Which section of the voice model file should this update? Map to existing sections:
   - Core Personality
   - Vocabulary Preferences
   - Vocabulary Prohibitions
   - Sentence Rhythm
   - Perspective & Stance
   - Opening Style
   - Closing Style
   - (Or a section in the relevant style modifier)

3. **Proposed text**: Write the specific text to add. It should be:
   - Concrete and actionable (not vague)
   - Written in the same style as the existing voice model content
   - A bullet point or short paragraph that fits naturally in the target section

4. **Brand check**: Verify the proposed change does not conflict with brand guidelines. If it does, flag it and do not propose it.

### Step 3: Classify Non-Patterns

- **Isolated observations** (appear in only 1-2 entries): List these as "monitoring" — they may become patterns with more data
- **Contradictory signals** (entries suggest opposite preferences): Flag these as "unresolvable" with an explanation of the contradiction

### Step 4: Confidence Assessment

For each proposed change:
- **high**: Appears in 5+ entries with consistent, clear pattern
- **medium**: Appears in 3-4 entries with consistent pattern
- **low**: Meets threshold but pattern is somewhat ambiguous

## Output Format

Return your analysis in this exact format:

---SYNTHESIS_REPORT---

## Recurring Patterns

{For each recurring pattern, numbered sequentially:}

### Pattern {N}: {Short descriptive name}
- **dimension**: {which of the 7 dimensions}
- **frequency**: {X of Y entries}
- **target_file**: {baseline.md | style-{type}.md}
- **target_section**: {section name}
- **confidence**: {high | medium | low}
- **evidence**: {2-3 specific examples from the adaptation entries showing this pattern}
- **proposed_text**: {The exact text to add to the voice model file}
- **brand_check**: {pass | conflict — if conflict, explain}

## Monitoring (Not Yet Patterns)

{For each isolated observation:}
- **{dimension}**: {description} (seen in {N} entries — needs {threshold - N} more to become a pattern)

## Contradictions

{For each contradictory signal, or "None detected":}
- **{dimension}**: {description of the contradiction and which entries conflict}

## Summary
{2-3 sentences: How many patterns found, overall direction of style drift, and recommendation}

---END_SYNTHESIS_REPORT---
```

If the subagent fails, report the error. Do not modify any voice model files. The adaptation entries remain unprocessed for a retry.

## Step 5: Present Proposed Changes

Parse the synthesis report from the subagent's response.

Display the full report to the user, organised as:

1. **Recurring Patterns Found**: For each pattern — the name, frequency, confidence, evidence, and proposed voice model edit
2. **Monitoring**: Isolated observations not yet patterns
3. **Contradictions**: Any conflicting signals (if present)

If no recurring patterns were found (all observations are isolated), report:
```
No recurring patterns detected yet across {N} adaptation entries. All observations are isolated — they may become patterns as you log more posted content with /posted.
```
Archive the entries (proceed to Step 7) and exit.

For each proposed change with `brand_check: pass`, use AskUserQuestion:

**Question**: "Apply this change to {author}'s voice model?\n\n**{Pattern name}** ({confidence} confidence, {frequency})\nTarget: `{target_file}` → {target_section}\nProposed addition: \"{proposed_text}\""

**Options**:
- **Label**: "Accept" — **Description**: "Add this to the voice model"
- **Label**: "Modify" — **Description**: "Accept the idea but adjust the wording (use Other to type)"
- **Label**: "Reject" — **Description**: "Skip this change"
- **Label**: "Accept all remaining" — **Description**: "Apply all remaining proposals without further prompts"

If the user selects "Accept all remaining", apply all subsequent proposals without further questions.

If the user provides modified text via "Other" after selecting "Modify", use their text instead of the proposed text.

For any pattern with `brand_check: conflict`, display it with a warning and recommend rejection. Still allow the user to override if they choose.

## Step 6: Apply Approved Changes

For each accepted change:

### Targeting baseline.md

Read `voice-models/authors/{author}/baseline.md`.

Check if a `## Learned Preferences` section exists at the end of the file. If not, add it:

```markdown

## Learned Preferences

Progressively refined from posted content analysis. See adaptations.md for source data.
```

Within `## Learned Preferences`, check if a subsection matching the target section exists (e.g., `### Vocabulary Learned`, `### Rhythm Learned`, `### Opening Style Learned`). The subsection name is `### {Target Section} Learned`.

If the subsection does not exist, create it.

Add the approved text as a bullet point under the relevant subsection, with a source reference:

```markdown
- {approved text} *(from {frequency} adaptations, {oldest date}–{newest date})*
```

Use Edit to apply the change.

### Targeting style-{type}.md

Same approach as baseline — add a `## Learned Preferences` section at the end of the style modifier file if it doesn't exist, create subsections as needed, and add the approved text with source reference.

Use Edit to apply the change.

## Step 7: Archive Processed Adaptations

In `voice-models/authors/{author}/adaptations.md`:

Move ALL unprocessed entries from the "## Unprocessed Entries" section to the "## Processed Entries" section. This includes entries that did not contribute to any accepted patterns — they were reviewed and either didn't meet the threshold or their patterns were rejected.

For each moved entry, append metadata:
```markdown
- **processed_date**: {YYYY-MM-DD}
- **synthesis_result**: {contributed to accepted pattern | contributed to rejected pattern | isolated | contradicting}
```

Use Edit to move the entries. The "## Unprocessed Entries" section should be empty after this step (containing only the heading).

## Step 8: Summary Output

```markdown
## Voice Refinement Complete — {author} — {date}

### Changes Applied: {count}
{For each applied change, numbered:}
1. **{Target section}** in `{target_file}` — {pattern name}
   - {Brief description of what was added}
   - Confidence: {level} | Based on: {frequency}
   - Source dates: {date range}

### Changes Rejected: {count}
{For each rejected change:}
1. **{Pattern name}** — {reason: user rejected | brand conflict}

### Monitoring ({count} isolated observations)
{Brief list of observations not yet strong enough to act on}

### Adaptations Processed: {count}
All {N} unprocessed entries have been archived to the Processed section.

### What Changed in the Voice Model
{For each modified file, list the file path and what was added}

### Next Steps
- Continue using `/posted` to capture more style data after publishing
- Run `/refine-voice` again after accumulating 5+ new adaptation entries
- Review the `## Learned Preferences` sections in modified voice model files to verify they feel right
- The next time `/produce` runs for {author}, the learned preferences will automatically influence the output
```

## Step 9: Git Commit

Stage all modified files:
- `voice-models/authors/{author}/baseline.md` (if modified)
- `voice-models/authors/{author}/style-*.md` (if any were modified)
- `voice-models/authors/{author}/adaptations.md`

Commit with message:
```
Refine voice: {author} — {N} patterns applied

- Applied: {comma-separated list of pattern names}
- Based on {M} adaptation entries ({date range})
- {K} isolated observations still monitoring
- Modified: {list of modified file names}
```

## Error Handling

- **No authors with adaptation data**: Report and exit. Suggest using `/posted` first.
- **Below threshold and user declines override**: Exit gracefully with encouragement to log more content.
- **Missing baseline.md**: Abort — cannot refine a nonexistent model. Suggest `/add-author`.
- **Missing style modifier targeted by a pattern**: Skip changes targeting that specific modifier. Report the gap and suggest the modifier may need to be created via `/add-author`.
- **Synthesis subagent failure**: Report the error. Do not modify voice model files. Adaptation entries remain unprocessed for retry.
- **All proposed changes rejected by user**: Still archive the adaptations as processed (they were reviewed, just not actionable). Note this in the summary.
- **Brand guideline conflict on all patterns**: Report that all detected patterns conflict with brand guidelines. Archive entries as processed. Suggest reviewing brand guidelines if the conflicts seem overly restrictive.
- **Adaptations file becomes very large (100+ processed entries)**: Note in summary that the processed entries section is growing large. Suggest the user may want to manually trim old processed entries to keep the file manageable.
- **Git commit failure**: Log the error, report in summary. Voice model changes are saved regardless.

</process>
