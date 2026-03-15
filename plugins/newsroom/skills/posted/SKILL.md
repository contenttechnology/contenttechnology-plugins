---
name: posted
description: Capture what was actually posted to a platform and analyse style divergence from the approved version — logs adaptation entries to the author's voice model for progressive refinement.
disable-model-invocation: true
argument-hint: "<filename>"
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, AskUserQuestion
---

<objective>
Close the feedback loop between approved content and what actually gets posted. When the user posts content to a platform, they often make small tweaks — word choices, structural changes, tone shifts. This skill captures the posted version, performs a style-focused comparison against the approved version, and logs structured adaptation observations to the author's voice model directory. Over time, these observations feed into `/refine-voice` to progressively update the author's voice model.

Usage: `/posted article-2026-03-15-001.md` or `/posted package-2026-03-10-002.md`
</objective>

<process>

## Step 1: Locate the Source File

The user must provide a filename as an argument (e.g., `article-2026-03-15-001.md` or `package-2026-03-10-002.md`). If no filename is provided, report:
```
Usage: /posted <filename>
Example: /posted article-2026-03-15-001.md

Provide the filename of the published or archived piece you posted.
```
And exit.

Strip any path prefix the user may have included (e.g., `pipeline/050_published/article-...md` → `article-...md`).

Search for the file in two locations, in order:
1. `pipeline/050_published/{filename}`
2. `pipeline/archived/{filename}`

Use Read to attempt to load the file from `pipeline/050_published/` first. If it does not exist there, try `pipeline/archived/`.

If the file is not found in either location, report:
```
File "{filename}" not found in pipeline/050_published/ or pipeline/archived/.

Check the filename and try again. You can list available files with:
  ls pipeline/050_published/
  ls pipeline/archived/
```
And exit.

Once found, record the full path (`source_path`) and read the file. Parse YAML frontmatter and extract:
- `id`
- `author`
- `style`
- `content_type` (articles) or `package_tier` (packages)
- `published_date` or `archived_date`

Also extract the headline from the first `#` heading in the markdown body (after frontmatter).

Detect item type from frontmatter and filename:
- Has `content_type` field, or filename starts with `article-` → **article**
- Has `package_tier` field, or filename starts with `package-` → **package**

Display the matched piece to the user:
```
Found: "{headline}" by {author}/{style} — {content_type or package_tier}
Source: {source_path}
```

## Step 2: Receive Posted Content

Use AskUserQuestion:

**Question**: "Paste the content exactly as you posted it (or as close as possible). Include the full text."

**Options**:
- **Label**: "Paste content" — **Description**: "Use Other to paste the full text of what you actually posted"

Capture the pasted text. If the response is empty or fewer than 10 characters, re-ask once. If still empty, exit with: "No content received. Run /posted again when you have the text."

## Step 3: Sanity Check

Compare the pasted content against the source file's body text to verify the user pasted the right content. Extract the article body (for articles) or the full package content (for packages) from the source file.

Check for basic similarity: look for at least a few shared distinctive phrases, proper nouns, or data points between the pasted content and the source. A rough heuristic: extract the key noun phrases and named entities from both texts and check for overlap.

If the pasted content shares **very little** with the source (e.g., no recognisable phrases, names, or data points in common), display a warning:

```
⚠ The pasted content doesn't look like it matches "{headline}".

The approved piece discusses: {2-3 key topics/phrases from the source}
The pasted content discusses: {2-3 key topics/phrases from the pasted text}

This may mean the wrong filename was provided, or the wrong content was pasted.
```

Use AskUserQuestion:

**Question**: "The pasted content doesn't appear to match the source file. Continue anyway?"

**Options**:
- **Label**: "Continue" — **Description**: "Proceed with analysis — the content is correct despite the differences"
- **Label**: "Cancel" — **Description**: "Exit so I can re-check the filename or pasted content"

If the user selects "Cancel", exit.

If the content looks like a reasonable match (shares key topics, names, or data points), skip this warning and proceed.

## Step 4: Package Format Selection (if applicable)

Check if the source piece has a `package_tier` field in its frontmatter.

If it is a **package**:

Parse the format sections from the package body — these are `##` headings like "LinkedIn Post", "X Thread", "Standalone Tweets", "Reusable Lines", "LinkedIn Comment Version".

Use AskUserQuestion:

**Question**: "Which format did you post?"

**Options**: One option per format section found in the package:
- **Label**: `{Format name}` — **Description**: First line preview of that format's content (truncated to 80 chars)

Record the selected format name and extract just that format's content from the package for comparison.

If it is an **article**: skip this step. The full article body is the comparison target.

## Step 5: Save Posted Version

Determine the next sequential number for today by scanning existing files in `pipeline/060_posted/` with pattern `posted-{YYYY-MM-DD}-*.md`.

Create directory `pipeline/060_posted/` if it does not exist (using Bash `mkdir -p`).

Save to `pipeline/060_posted/posted-{YYYY-MM-DD}-{NNN}.md`:

```markdown
---
id: posted-{YYYY-MM-DD}-{NNN}
date: {YYYY-MM-DD}
source_id: {published piece ID}
author: {author from published piece}
style: {style from published piece}
content_type: {article | linkedin_post | x_thread | standalone_tweet | reusable_lines | linkedin_comment}
format: {if package: specific format name selected in Step 3, else: article}
status: pending-analysis
---

## Posted Content

{The pasted content exactly as the user provided it}

## Source Reference

See `{source_path}` for the approved version.
```

## Step 6: Style-Focused Comparison

Extract the approved version text:
- For **articles**: the full article body from the published file (everything between the frontmatter and the Production Metadata section)
- For **packages**: just the selected format section from the published file

Load voice model context:
1. Read `voice-models/brand-guidelines.md`
2. Read `voice-models/authors/{author}/baseline.md`
3. Read `voice-models/authors/{author}/style-{style}.md` (if it exists)

Dispatch a Task subagent (subagent_type: "general-purpose"):

```
You are a style analyst for an editorial newsroom. Your job is to compare an APPROVED version of content with the POSTED version (what was actually published to a platform) and identify meaningful style patterns.

## CRITICAL INSTRUCTION
Do NOT produce a line-by-line textual diff. Instead, identify meaningful STYLE patterns — changes that reflect how the author prefers to express ideas versus how the system generated them. Focus on recurring tendencies, not individual word swaps.

## Approved Version
{Paste the approved version text}

## Posted Version (what was actually published)
{Paste the posted content}

## Author Voice Model (for context — understand what the system was aiming for)

### Baseline
{Paste baseline.md content, or "Not available" if missing}

### Style Modifier
{Paste style modifier content, or "No style modifier applied"}

## Analysis Dimensions

Analyse the differences through EACH of these 7 dimensions. For each dimension, describe any observed patterns. If no meaningful change was observed for a dimension, say "none observed". Be specific and concrete — cite examples from the text.

### 1. Tone Shifts
Changes in formality level, directness, warmth, or emotional register. Example: "Shifted from formal third-person analysis to direct first-person address" or "Softened authoritative statements with conversational asides".

### 2. Word Choice Patterns
Specific vocabulary preferences or avoidances. Example: "Replaced 'utilise' with 'use' throughout" or "Added industry-specific shorthand ('TAM' instead of 'total addressable market')".

### 3. Structural Changes
Paragraph length changes, section reordering, how openings or closings were modified. Example: "Condensed the 3-paragraph opening into a single punchy sentence" or "Moved the key data point from paragraph 4 to the opening".

### 4. Brevity Preferences
What was cut, what was expanded, compression patterns. Example: "Cut all transitional sentences between sections" or "Expanded the conclusion with a personal call-to-action".

### 5. Punctuation & Rhythm
Sentence length changes, em-dash usage, rhetorical question additions/removals, list formatting. Example: "Broke long compound sentences into short punchy fragments" or "Added em-dashes for parenthetical asides instead of commas".

### 6. Platform Adaptation
Format-specific adjustments: hook style, CTA handling, hashtag preferences, thread structure. Example: "Added a hook question as the first line" or "Removed all hashtags except one".

### 7. Evidence Handling
How data points, quotes, or citations were presented differently. Example: "Moved the statistic into the opening rather than burying it in paragraph 3" or "Paraphrased the direct quote into a more conversational reference".

## Output Format

Return your analysis in this exact format:

---STYLE_ANALYSIS---

## Overall Assessment
{2-3 sentences: How different is the posted version from the approved? Are the changes mostly cosmetic, structural, or tonal? Do they suggest clear preferences or seem context-specific?}

## Dimension Analysis

### tone_shifts
{Description of observed patterns, with specific examples from the text. Or "none observed".}

### word_choice
{Description with examples. Or "none observed".}

### structural_changes
{Description with examples. Or "none observed".}

### brevity_preferences
{Description with examples. Or "none observed".}

### punctuation_rhythm
{Description with examples. Or "none observed".}

### platform_adaptation
{Description with examples. Or "none observed".}

### evidence_handling
{Description with examples. Or "none observed".}

## Summary
{1-2 sentence summary of the most significant style patterns observed.}

## Confidence
{high | medium | low} — How clear and intentional do the changes appear? "high" = clear, consistent pattern across multiple changes. "medium" = some clear patterns mixed with ambiguous edits. "low" = mostly minor or context-specific changes, hard to generalise.

---END_STYLE_ANALYSIS---
```

If the subagent fails, update the posted file's status to `analysis-failed` and report the error. The posted content is still saved for future re-analysis.

## Step 7: Log Adaptation Entry

Parse the style analysis from the subagent's response (between `---STYLE_ANALYSIS---` and `---END_STYLE_ANALYSIS---`).

Check if `voice-models/authors/{author}/adaptations.md` exists. If not, create it:

```markdown
# {Author} — Style Adaptations

Accumulated style observations from posted content comparisons. Processed by /refine-voice into voice model updates.

## Unprocessed Entries

## Processed Entries
```

Determine the next sequential adaptation ID by counting existing `### AD-` entries in the file.

Append a new entry under the "## Unprocessed Entries" heading (before "## Processed Entries"):

```markdown
### AD-{YYYY-MM-DD}-{NNN}
- **date**: {YYYY-MM-DD}
- **source_id**: {published piece ID}
- **posted_id**: {posted file ID}
- **content_type**: {content_type from posted file frontmatter}
- **style**: {style slug}
- **observations**:
  - **tone_shifts**: {from analysis, or "none observed"}
  - **word_choice**: {from analysis, or "none observed"}
  - **structural_changes**: {from analysis, or "none observed"}
  - **brevity_preferences**: {from analysis, or "none observed"}
  - **punctuation_rhythm**: {from analysis, or "none observed"}
  - **platform_adaptation**: {from analysis, or "none observed"}
  - **evidence_handling**: {from analysis, or "none observed"}
- **summary**: {summary from analysis}
- **confidence**: {confidence from analysis}
```

## Step 8: Update Package Format Status (if applicable)

If the source piece is a package and has `formats_published` in its frontmatter:

Read the published package file. Map the posted format heading to the corresponding `formats_published` key:

| Format Heading | Key |
|---|---|
| LinkedIn Post | `linkedin_post` |
| X Thread | `x_thread` |
| Standalone Tweets | `tweet_1`, `tweet_2`, etc. |
| Reusable Lines | `reusable_lines` |
| LinkedIn Comment Version | `linkedin_comment` |

Match the heading selected in Step 4 to the closest key in `formats_published`.

Use Edit to update that format's `published: false` to `published: true` in the published piece's frontmatter.

If the source is an article, skip this step.

## Step 9: Update Posted File Status

Edit the posted file's frontmatter to set `status: analysed`.

Append the full style analysis to the posted file after the "## Source Reference" section:

```markdown
## Style Analysis

{The full analysis text from the subagent, excluding the delimiter tags}
```

## Step 10: Summary Output

Count the total number of unprocessed adaptation entries for this author by reading the adaptations file.

Output:

```markdown
## Posted Content Captured — {date}

### Matched to
**{Headline}** by {author}/{style}
Content type: {content_type or format name}
Source: `{source_path}`

### Style Observations
{The summary from the analysis}
Confidence: {confidence level}

### Key Patterns
{List the dimensions where meaningful changes were observed (not "none observed"), with a brief note for each}

### Adaptation Log
Entry **AD-{id}** added to `voice-models/authors/{author}/adaptations.md`
Total unprocessed adaptations for {author}: **{count}**
{If count >= 5: "You have enough adaptation data to run `/refine-voice` and update {author}'s voice model."}
{If count < 5: "{5 - count} more entries needed before `/refine-voice` can synthesise patterns (minimum 5)."}
```

## Step 11: Git Commit

Stage all new and modified files:
- `pipeline/060_posted/{posted-file}.md`
- `voice-models/authors/{author}/adaptations.md`
- `{source_path}` (only if formats_published was updated)

Commit with message:
```
Posted: "{headline}" by {author}

- {N} style observations logged to adaptations.md
- Key patterns: {1-2 dimension names with strongest observations}
- Total unprocessed adaptations for {author}: {count}
```

## Error Handling

- **No filename argument provided**: Display usage instructions and exit.
- **File not found in published or archived**: Report the error with the filename, suggest `ls` commands to list available files, and exit.
- **Pasted content is very short (< 10 characters)**: Re-ask once. If still too short, exit. Note: tweets are naturally short — don't reject based on length above the 10-char minimum.
- **Sanity check fails and user cancels**: Exit cleanly. The user can re-run with the correct filename or content.
- **Style analysis subagent failure**: Save the posted content anyway (it has reference value). Set status to `analysis-failed`. Report the error and suggest re-running `/posted` with the same filename.
- **Author voice model files missing**: Proceed with analysis but instruct the subagent that baseline comparison was not possible. The analysis focuses purely on approved-vs-posted differences without voice model context.
- **Adaptations file write conflict**: Read the file immediately before appending to get the latest state. Use sequential IDs based on the current count.
- **Package format not found in formats_published**: Log a warning but don't fail. The format tracking may not match the section headings exactly.
- **Git commit failure**: Log the error, report in summary. The files are saved regardless.

</process>
