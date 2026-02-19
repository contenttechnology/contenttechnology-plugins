---
name: produce
description: Write article drafts from production briefs using the three-layer voice model — brand guidelines, author baseline, and style modifier.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep
---

<objective>
Produce article drafts from approved production briefs. For each brief, load the three-layer voice model (brand guidelines → author baseline → style modifier), compose the article according to the brief's structure guidance, and save the draft to `pipeline/030_drafts/`. The production agent writes in the assigned author's authentic voice, weaving multiple sources into genuine synthesis.
</objective>

<process>

## Step 1: Load Production Briefs

Use Glob to find all production briefs: `pipeline/020_approved/*.md`

Read each brief. Filter for `status: ready` — these are ready for production. Skip any with `status: in-production` or `status: produced`.

If no ready briefs are found, report "No production briefs ready. Run /editorial first." and exit.

## Step 2: Load Shared Context

Read the following once (shared across all drafts):

1. **`PUBLICATION.md`** — Editorial mission and quality criteria
2. **`voice-models/brand-guidelines.md`** — Global brand voice constraints (Layer 1)
3. **`FORMATTING.md`** — Global formatting conventions (if it exists)

### Editorial Feedback

Read `pipeline/editorial-feedback.md` if it exists. Filter for entries where `status: open`, `targets` includes `produce`, and `type` is `production-note`.

For each relevant entry, check if the `context` field references any of the briefs you are about to produce. If so, include the note in the production subagent's prompt as an "Editorial Director's Note" section, placed after the production brief content and before the source material. This ensures the production agent is aware of overlap warnings, framing guidance, or other editorial constraints.

After producing all drafts, mark any production-note entries you consumed as addressed in `pipeline/editorial-feedback.md` — change `status` to `addressed`, add `addressed_by: produce`, `addressed_date: {today}`, `resolution: {e.g., "Applied to draft-2026-02-10-001 — led with regulatory angle per editorial guidance"}`, and move from "Active Entries" to "Addressed Entries".

If the feedback file does not exist or contains no entries targeting produce, proceed normally.

## Step 3: Produce Each Draft

For each ready production brief, dispatch a Task subagent (subagent_type: "general-purpose") to write the draft.

Before dispatching, mark the brief as `status: in-production` by editing the frontmatter.

### Load the Voice Model

For the assigned author and style:

1. Read `voice-models/authors/{author}/baseline.md` — Author baseline (Layer 2)
2. Read `voice-models/authors/{author}/style-{style}.md` — Style modifier (Layer 3), if one is specified. If no style modifier is specified, use the baseline only.

### Load Source Material

Read each signal file referenced in the brief's source inventory:
- Read primary sources from `knowledge-base/signals/{signal-id}.md`
- Read supporting sources from `knowledge-base/signals/{signal-id}.md`

Compile the source material into a reference document for the production agent.

### Dispatch Production Subagent

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

## Brand Voice Constraints (HARD RULES — cannot be violated)
{Paste full brand-guidelines.md content}

## Formatting Conventions (APPLY TO ALL CONTENT)
{Paste full FORMATTING.md content, or omit this section if FORMATTING.md does not exist}

## Your Author Voice: {author name}
{Paste full baseline.md content}

## Style Modifier: {style name}
{Paste full style modifier content, or "No style modifier — write in baseline voice" if none}

## Production Brief
{Paste the full production brief including thesis, source inventory, structure guidance, voice notes, and do-not-include list}

## Source Material
{For each source referenced in the brief, paste the signal report content:}

### {signal-id}: {summary}
{Full signal report content}

---

## Your Task

Write a complete article draft that:
1. Delivers the approved thesis through genuine synthesis of the source material
2. Follows the structure guidance from the brief
3. Sounds authentically like {author name} writing in {style} mode
4. Respects all brand voice constraints
5. Falls within the target length: {word range}
6. Addresses the counter-arguments identified in the brief
7. Delivers a clear "so what?" for the target audience: {audience segments}
8. Avoids everything on the do-not-include list
9. Follows the formatting conventions from FORMATTING.md (paragraph length, heading structure, list usage, etc.)
10. Ensures dates are relative to today's date

## Output Format

Return the complete draft in this exact format:

---DRAFT_START---
{The complete article, ready for quality review. Include a headline. Do not include metadata or frontmatter — just the article text.}
---DRAFT_END---

WORD_COUNT: {approximate word count}

PRODUCTION_NOTES: {Any notes about choices you made, compromises, or areas where the brief was ambiguous. 2-3 sentences max.}
```

## Step 4: Save Drafts

For each completed draft:

### Filename Convention
`draft-{YYYY-MM-DD}-{NNN}.md` — sequential number for the day.

Check existing files in `pipeline/030_drafts/` to determine the next number.

### Draft File Format

```markdown
---
id: draft-{YYYY-MM-DD}-{NNN}
date: {YYYY-MM-DD}
status: draft
brief_id: {production brief ID}
pitch_id: {original pitch ID}
author: {author name}
style: {style slug}
content_type: {content type}
word_count: {approximate count}
revision: 0
max_revisions: 2
audience: [{audience segments}]
---

{Complete article text from the subagent — headline and body}

---

## Production Metadata

### Production Notes
{Notes from the production subagent}

### Source References
{List of signal IDs used, for traceability}

### Brief Reference
See `pipeline/020_approved/{brief-id}.md` for the full production brief.
```

### Update Brief Status

Edit the production brief frontmatter to set `status: produced` and add `draft_id: {draft-id}`.

## Step 5: Summary Output

```markdown
## Production Summary — {date}

### Drafts Produced: {count}
{For each draft:}
1. **{Headline}** ({draft-id})
   - Author: {author} / Style: {style}
   - Word count: {count} (target: {range})
   - Content type: {type}
   - Brief: {brief-id}

### Production Notes
{Any notable decisions, compromises, or flags from the production agents}

### Next Step
Run `quality` to assess these drafts against the quality gate.
```

## Step 6: Git Commit

Stage all new and modified files:
- `pipeline/030_drafts/*.md` (new drafts)
- `pipeline/020_approved/*.md` (updated brief status)
- `pipeline/editorial-feedback.md` (if modified)

```
Produce drafts: {N} articles written

- {draft-1}: "{headline}" by {author} ({word count} words)
- {draft-2}: "{headline}" by {author} ({word count} words)
```

## Error Handling

- If the assigned author's voice model files don't exist, report the error and skip that brief. Do not write with a substitute voice — voice authenticity is critical.
- If a referenced signal file is missing, note it in production notes but continue writing with available sources. Flag the gap.
- If the production subagent returns output that doesn't match the expected format, attempt to extract the draft text anyway. If impossible, report the failure and keep the brief at `status: ready` for retry.
- If the draft significantly exceeds or falls short of the target word count (>30% deviation), note it in production notes for the quality gate to assess.

</process>
