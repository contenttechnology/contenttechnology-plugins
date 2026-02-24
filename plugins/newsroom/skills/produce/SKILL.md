---
name: produce
description: Write article drafts and content packages from production briefs using the three-layer voice model — brand guidelines, author baseline, and style modifier.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep
---

<objective>
Produce article drafts and content packages from approved production briefs. For each brief, load the three-layer voice model (brand guidelines → author baseline → style modifier), compose the content according to the brief's guidance, and save to `pipeline/030_drafts/`. The production agent detects the brief type from frontmatter: briefs with `content_type` produce articles, briefs with `package_tier` produce content packages. Both paths write in the assigned author's authentic voice, weaving multiple sources into genuine synthesis.
</objective>

<process>

## Step 1: Load Production Briefs

Use Glob to find all production briefs: `pipeline/020_approved/*.md`

Read each brief. Filter for `status: ready` — these are ready for production. Skip any with `status: in-production` or `status: produced`.

**Detect brief type from frontmatter:**
- Has `content_type` field → **article brief** (existing article production flow)
- Has `package_tier` field → **package brief** (new package production flow)

Separate briefs into two lists: article briefs and package briefs. Both are processed in the same run.

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

## Step 3: Produce Each Article Draft

For each ready **article** production brief (has `content_type`), dispatch a Task subagent (subagent_type: "general-purpose") to write the draft.

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

### Dispatch Article Production Subagent

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

## Step 3b: Produce Each Content Package

For each ready **package** production brief (has `package_tier`), dispatch a Task subagent (subagent_type: "general-purpose") to write the content package.

Before dispatching, mark the brief as `status: in-production` by editing the frontmatter.

### Load the Voice Model

For the assigned author and style:

1. Read `voice-models/brand-guidelines.md` — Brand guidelines (Layer 1)
2. Read `voice-models/authors/{author}/baseline.md` — Author baseline (Layer 2)
3. Read `voice-models/authors/{author}/style-{style}.md` — Primary format style modifier (Layer 3), if one is specified

### Load Optional Style Modifier Overrides

If the brief contains a `## Format-Specific Style Overrides` section referencing specific style modifier files, read those files from `voice-models/authors/{author}/style-{modifier}.md`. These override the default per-format style mappings.

### Load Source Material

Read each signal file referenced in the brief's source inventory from `knowledge-base/signals/`.

### Dispatch Package Production Subagent

```
You are a content package producer for the Newsroom. Your job is to write a complete multi-format content package that delivers the approved thesis in the assigned author's voice across multiple social formats.

## CRITICAL RULES — READ FIRST
1. SYNTHESIS, NEVER SUMMARISATION: Weave sources into natural-sounding social content. Never reference sources as "according to" — embed the insight directly.
2. NO AI TELLS: Never use these patterns:
   - "In today's rapidly evolving..." or any variant
   - "Let's dive in" / "Let's explore" / "Let's unpack"
   - "It's worth noting that..."
   - "Here's the thing:" / "The reality is:" (as formulaic openers)
   - Excessive hedging: "it could be argued", "some might say"
   - Thread numbering (1/, 2/) or emoji bullets
3. SPECIFIC OVER GENERAL: Every claim must be backed by a specific data point or reference. "The market is changing" is bad. "Q3 showed a 14% revenue decline" is good.
4. FORMAT INDEPENDENCE: Each format must be independently composed. Do NOT excerpt, truncate, or summarise from another format. Each format is its own piece of writing that happens to express the same thesis.
5. NO COPY-PASTE between formats. The LinkedIn post is not a long version of the tweet. The tweet is not a short version of the LinkedIn post. Write each fresh.

## Format-Specific Writing Rules

### Standalone Tweets
- Must work without any context — no "as I mentioned" or thread references
- Under 280 characters
- Sound like an immediate thought, not a crafted statement
- Each tweet should illuminate a different facet of the thesis
- No hashtags unless they add meaning

### X Threads
- Each tweet must be independently interesting — someone might see only one
- Build sequentially but don't require reading previous tweets
- No numbering (1/, 2/) or emoji bullets
- Invisible transitions — each tweet flows naturally from the previous
- Opening tweet must hook on its own
- Final tweet must land the thesis without summarising

### LinkedIn Posts
- Front-load the insight — the first line must earn the scroll-stop
- Slightly more context and polish than X — LinkedIn readers expect professional depth
- Light package: 120-250 words
- Full/thread-only package: 300-500 words (or 400-800 for thread-only)
- Line breaks for readability — short paragraphs, not walls of text
- No "I'm excited to share" or "Thought leaders agree" patterns

### Reusable Lines
- NOT excerpts from other formats — independently crafted
- Must work as replies or comments in conversations
- One sentence per line — the "text to a colleague" test
- Should be deployable in response to related threads or posts
- No context needed — each line is self-contained

### LinkedIn Comment Version (full tier only)
- 40-80 words
- Reference the original topic without hijacking it
- Add a specific angle or data point — not just agreement
- Conversational but substantive

## Brand Voice Constraints (HARD RULES — cannot be violated)
{Paste full brand-guidelines.md content}

## Your Author Voice: {author name}
{Paste full baseline.md content}

## Primary Format Style: {style name}
{Paste full style modifier content, or "No style modifier — write in baseline voice" if none}

## Per-Format Style Modifier Defaults
Unless the brief specifies overrides in "Format-Specific Style Overrides":
- LinkedIn post/long post → observational or analytical (depending on length)
- X thread → analytical
- Standalone tweets → observational (compressed)
- Reusable lines → voice baseline only (no modifier)
- LinkedIn comment → responsive

{If style override files were loaded, paste them here with format mapping}

## Production Brief
{Paste the full package brief including thesis, source inventory, structure guidance, voice notes, and do-not-include list}

## Source Material
{For each source referenced in the brief, paste the signal report content:}

### {signal-id}: {summary}
{Full signal report content}

---

## Your Task

This is a **{package_tier}** package with primary platform **{primary_platform}**.

### Production Sequence
1. Write the **primary format first** (determined by primary_platform: {primary_platform})
   - If linkedin: Write the LinkedIn post first
   - If x: Write the X thread (or standalone tweets for light tier) first
2. Derive remaining formats — independently composed, not excerpted, same thesis/evidence/voice
3. Write **reusable lines last** — distilled core insights

### Tier-Specific Outputs Required

{If light:}
**Light Package:**
- 1 LinkedIn post (120-250 words)
- 2-3 standalone tweets (each <280 chars)
- 2-3 reusable lines

{If full:}
**Full Package:**
- 1 LinkedIn long post (300-500 words)
- 1 X thread (3-5 tweets)
- 2-3 standalone tweets (each <280 chars)
- 3-5 reusable lines
- 1 LinkedIn comment version (40-80 words)

{If thread-only:}
**Thread-Only Package:**
- 1 X thread (5-8 tweets)
- 1 LinkedIn long post (400-800 words)
- 2-3 standalone tweet extractions from the thread
- 3-5 reusable lines

## Output Format

Return the complete package in this exact format:

---PACKAGE_START---

## LinkedIn Post
{content}

## X Thread
### Tweet 1
{content}
### Tweet 2
{content}
{...additional tweets as needed}

## Standalone Tweets
### Tweet 1
{content}
### Tweet 2
{content}
{...additional tweets as needed}

## Reusable Lines
- {line}
- {line}
- {line}

## LinkedIn Comment Version
{content — only for full tier}

---PACKAGE_END---

PRODUCTION_NOTES: {Any notes about choices you made, format trade-offs, or areas where the brief was ambiguous. 2-3 sentences max.}
```

## Step 4: Save Drafts

For each completed draft, save to `pipeline/030_drafts/`. Check existing files to determine the next sequential number.

### 4a. Save Article Drafts

For each completed article draft:

**Filename**: `draft-{YYYY-MM-DD}-{NNN}.md`

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

### 4b. Save Content Packages

For each completed content package:

**Filename**: `pkg-{YYYY-MM-DD}-{NNN}.md`

```markdown
---
id: pkg-{YYYY-MM-DD}-{NNN}
date: {YYYY-MM-DD}
status: draft
brief_id: {production brief ID}
pitch_id: {original pitch ID}
related_brief_id: {article brief ID if dual output, null otherwise}
author: {author name}
style: {style slug}
package_tier: {light | full | thread-only}
primary_platform: {linkedin | x}
revision: 0
max_revisions: 1
audience: [{audience segments}]
---

## Thesis
{The approved thesis from the brief}

{All format sections from the subagent output, clearly separated:}

## LinkedIn Post
{content}

## X Thread
### Tweet 1
{content}
### Tweet 2
{content}

## Standalone Tweets
### Tweet 1
{content}
### Tweet 2
{content}

## Reusable Lines
- {line}
- {line}

## LinkedIn Comment Version
{content — only for full tier}

---

## Production Metadata

### Production Notes
{Notes from the production subagent}

### Source References
{List of signal IDs used, for traceability}

### Brief Reference
See `pipeline/020_approved/{brief-id}.md` for the full production brief.
```

Note: `max_revisions: 1` for packages (one revision cycle per format; primary format failure after one revision kills the package).

### Update Brief Status

Edit the production brief frontmatter to set `status: produced` and add `draft_id: {draft-id}` (for articles) or `package_id: {pkg-id}` (for packages).

## Step 5: Summary Output

```markdown
## Production Summary — {date}

### Article Drafts Produced: {count}
{For each article draft:}
1. **{Headline}** ({draft-id})
   - Author: {author} / Style: {style}
   - Word count: {count} (target: {range})
   - Content type: {type}
   - Brief: {brief-id}

### Content Packages Produced: {count}
{For each package:}
1. **{Headline}** ({pkg-id})
   - Author: {author} / Style: {style}
   - Package tier: {light | full | thread-only}
   - Primary platform: {linkedin | x}
   - Formats: {count of formats in package}
   - Brief: {brief-id}

### Production Notes
{Any notable decisions, compromises, or flags from the production agents}

### Next Step
Run `quality` to assess these drafts and packages against the quality gate.
```

## Step 6: Git Commit

Stage all new and modified files:
- `pipeline/030_drafts/*.md` (new drafts and packages)
- `pipeline/020_approved/*.md` (updated brief status)
- `pipeline/editorial-feedback.md` (if modified)

```
Produce drafts: {N} articles, {M} packages written

- {draft-1}: "{headline}" by {author} ({word count} words)
- {pkg-1}: "{headline}" by {author} ({tier} package, {platform})
```

## Error Handling

- If the assigned author's voice model files don't exist, report the error and skip that brief. Do not write with a substitute voice — voice authenticity is critical.
- If a referenced signal file is missing, note it in production notes but continue writing with available sources. Flag the gap.
- If the production subagent returns output that doesn't match the expected format (`---DRAFT_START---`/`---DRAFT_END---` for articles, `---PACKAGE_START---`/`---PACKAGE_END---` for packages), attempt to extract the content anyway. If impossible, report the failure and keep the brief at `status: ready` for retry.
- If the draft significantly exceeds or falls short of the target word count (>30% deviation), note it in production notes for the quality gate to assess.
- For packages: if a format section is missing from the subagent output (e.g., no reusable lines), save the package with available formats and note the gap in production notes. The quality gate will flag missing formats.

</process>
