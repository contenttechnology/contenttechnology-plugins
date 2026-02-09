---
name: editorial
description: Evaluate validated pitch memos as editorial director — approve or kill angles, assign authors and styles, and produce production briefs.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

<objective>
Act as the editorial director. Evaluate all validated pitch memos against quality criteria, editorial mix, campaign priorities, and source strength. Approve the strongest angles with author and style assignments, kill marginal ones, and produce production briefs for approved pieces. This is the gatekeeper that ensures only genuinely valuable content enters production.
</objective>

<process>

## Step 1: Load Editorial Context

Read the following to build full editorial context:

1. **`PUBLICATION.md`** — Editorial mission and quality criteria
2. **`config.md`** — Quality thresholds, content mix targets
3. **`editorial-calendar.md`** — Current calendar, gaps, recurring commitments

### Recent Publication History

Use Glob and Read to review recent pipeline state:
- `pipeline/published/*.md` — What's been published recently? Look at content types, topics, authors
- `pipeline/review/*.md` — What's currently in human review?
- `pipeline/drafts/*.md` — What's currently in production?
- `pipeline/approved/*.md` — What's already approved and queued?

Build a picture of the current editorial mix:
- Which content types have been covered recently?
- Which authors have been assigned recently?
- Which topics have been covered?
- What gaps exist in the editorial calendar?

### Active Campaigns

Use Glob to check `campaigns/active/*.md` and read any found. Campaigns influence prioritisation.

### Available Authors

Use Glob to list `voice-models/authors/*/baseline.md`. Read each baseline to understand author strengths and available styles. For each author, also check available style modifiers: `voice-models/authors/{name}/style-*.md`.

Read `voice-models/brand-guidelines.md` for global constraints.

## Step 2: Load Validated Pitch Memos

Use Glob to find all pitch memos: `pipeline/pitches/*.md`

Read each and filter for `status: validated` — these have passed validation and are ready for editorial review. Skip `pending` (not yet validated), `approved`, and `rejected`.

If no validated pitch memos are found, report "No validated pitches to review. Run /newsroom:validate first." and exit.

## Step 3: Evaluate Each Pitch

For each validated pitch memo, apply the editorial decision criteria:

### Value Threshold
Is this genuinely valuable to the target audience? Would a busy professional stop scrolling to read this?
- **Pass**: Clear, immediate value to the target audience
- **Marginal**: Might be valuable but feels like filler
- **Fail**: Not compelling enough to justify production effort

If the answer is "Marginal" or "Fail", kill the angle unless it serves a critical campaign need.

### Source Strength
Does the pitch have enough high-tier sources to be credible?
- At least 1 Tier 1 or Tier 2 source for the primary thesis
- At least 2 total sources (from config.md min_sources_for_angle)
- Validation report shows supporting evidence strength of "moderate" or better

### Editorial Mix
How does this fit the current content portfolio?
- Check against recent publications: avoid clustering on the same topic
- Check against content mix targets in config.md: are we underserving any content type?
- Prioritise content types that haven't been published recently
- Consider audience segment balance

### Campaign Fit
Does this angle serve an active campaign?
- Campaign-aligned angles get priority if quality is sufficient
- Non-campaign angles are evaluated purely on merit

### Redundancy Check
Has a similar angle been published recently?
- Check published pieces for topic overlap
- A new angle on the same topic is fine if it adds genuinely new information
- A re-hash of a recently published angle is killed

### Timeliness
- Time-sensitive angles get fast-tracked if they pass other criteria
- Durable angles can wait for the right slot in the editorial calendar

## Step 4: Make Editorial Decisions

For each pitch, render one of three decisions:

### APPROVE
The angle is strong, well-supported, and fills a need. Proceed to production.

### KILL
The angle is marginal, redundant, insufficiently sourced, or doesn't serve the audience. Move to rejected with clear reasoning.

### HOLD
The angle has potential but isn't ready — needs more evidence, better timing, or should wait for a related development. Keep in pitches with `status: held` and a note explaining what's needed.

## Step 5: Assign Authors and Styles

For each approved angle:

1. **Select the author** best suited to this angle:
   - Match author expertise and perspective to the topic
   - Consider author workload: avoid assigning too many pieces to one author in the same cycle
   - Consider the recommended author from the pitch memo, but override if a better fit exists
   - Rationale must be documented

2. **Select the style modifier**:
   - Match the content type to an available style for the chosen author
   - Deep Analysis → `style-deep-analysis.md`
   - Commentary → `style-commentary.md`
   - Regulatory → `style-regulatory.md`
   - Practitioner Insights / Market Pulse → author's baseline (no modifier needed for shorter formats)

3. **Determine content type, length, and format**:
   - Content type from the pitch memo recommendation (may override)
   - Length range from content type definitions:
     - Deep Analysis: 1,500-2,500 words
     - Data Intelligence: 800-1,200 words
     - Regulatory Watch: 600-1,000 words
     - Practitioner Insights: 400-800 words
     - Market Pulse: 300-600 words

4. **Identify the target audience segment**:
   - Tailor to the audience segments defined during project init
   - May be multiple segments

## Step 6: Write Production Briefs

For each approved angle, write a production brief to `pipeline/approved/`.

### Filename Convention
`brief-{YYYY-MM-DD}-{NNN}.md` — sequential number for the day.

### Production Brief Format

```markdown
---
id: brief-{YYYY-MM-DD}-{NNN}
date: {YYYY-MM-DD}
status: ready
pitch_id: {original pitch memo ID}
author: {author-name}
style: {style-slug}
content_type: {deep-analysis | data-intelligence | regulatory | practitioner-insights | market-pulse}
target_length: {word range}
audience: [{audience segments}]
campaign: {campaign-slug or null}
timeliness: {durable | time-sensitive}
deadline: {date if time-sensitive, null otherwise}
---

# Production Brief: {Working Headline}

## Approved Thesis
{The thesis — may be refined from the pitch memo based on validation results. This is the final thesis the production agent must deliver.}

## Source Inventory

### Primary Sources (must be woven into the narrative)
{For each primary source:}
- **{signal-id}**: {what this source contributes and how to use it}

### Supporting Sources (use for context and colour)
{For each supporting source:}
- **{signal-id}**: {what this adds}

### Counter-Arguments to Address
{From the validation report — the piece must acknowledge these:}
- {counter-argument}: {how to address it}

## Structure Guidance
{Narrative arc recommendation:}
- **Opening**: {how to open — what hook or data point to lead with}
- **Core argument**: {the 2-3 key sections that build the thesis}
- **Counter-argument**: {where to acknowledge and address the other side}
- **"So what?"**: {the practical implication to deliver — what should the reader do?}
- **Close**: {how to land the piece}

## Voice Notes
- **Author**: {author name} — {brief note on why this author}
- **Style**: {style name} — {brief note on why this style}
- **Specific guidance**: {any piece-specific voice notes — e.g., "lean into the data on this one" or "the practitioner angle is the hook"}

## Do-Not-Include List
- {Any topics, claims, or framings to avoid}
- {Brand guideline constraints particularly relevant to this piece}
- {Information that's unverified or Tier 4 only}

## Editorial Decision Rationale
{2-3 sentences on why this was approved and what makes it worth producing}
```

## Step 7: Update Pitch Memo Status

For each decision:

**Approved**: Edit the pitch memo frontmatter to set `status: approved` and add `brief_id: {brief-id}`.

**Killed**: Edit the pitch memo frontmatter to set `status: rejected`, add `rejected_date` and `rejected_reason`. Move the file to `pipeline/rejected/` using Bash `mv`.

**Held**: Edit the pitch memo frontmatter to set `status: held`, add `hold_reason` and `hold_date`.

## Step 8: Summary Output

```markdown
## Editorial Review Summary — {date}

### Approved for Production: {count}
{For each approved piece:}
1. **{Headline}** ({brief-id})
   - Author: {author} / Style: {style}
   - Content type: {type} / Length: {range}
   - Audience: {segments}
   - Priority: {normal | fast-track}

### Killed: {count}
{For each killed piece:}
1. **{Headline}** ({pitch-id})
   - Reason: {why}

### Held: {count}
{For each held piece:}
1. **{Headline}** ({pitch-id})
   - Needs: {what's required before approval}

### Editorial Mix Status
- Deep Analysis: {published this month} / {target}
- Practitioner Insights: {published this week} / {target}
- Market Pulse: {published this fortnight} / {target}
- {Other types...}
```

## Step 9: Git Commit

Stage all new and modified files:
- `pipeline/approved/*.md` (new production briefs)
- `pipeline/pitches/*.md` (updated status)
- `pipeline/rejected/*.md` (moved rejected pitches)

```
Editorial review: {N} approved, {M} killed, {K} held

Approved:
- {brief-1}: {headline} → {author}/{style}
Killed:
- {pitch-1}: {reason}
```

## Error Handling

- If no authors exist in `voice-models/`, approve the angle but set `author: unassigned` and note that an author must be created before production
- If the editorial calendar is missing, proceed without mix analysis but note it in the summary
- If campaign files can't be read, proceed without campaign alignment
- It is expected and healthy for the editorial director to kill most pitches — a high approval rate indicates the quality bar is too low

</process>
