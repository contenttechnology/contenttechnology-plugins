---
name: angle
description: Scan the knowledge base for converging signals, construct falsifiable theses, and write pitch memos to the pipeline.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

<objective>
Scan the knowledge base for patterns of converging signals across beats and time periods. Construct falsifiable theses that combine multiple sources into genuine editorial angles. Write pitch memos for viable angles to `pipeline/010_pitches/`. This is the editorial brain of Newsroom — it turns raw intelligence into publishable ideas.
</objective>

<process>

## Step 1: Load Context

Read the following files to build full editorial context:

1. **`PUBLICATION.md`** — Editorial mission and quality criteria
2. **`config.md`** — Quality thresholds (min sources for angle: 2)
3. **`knowledge-base/index.json`** — Signal metadata, tags, dates, tiers

Use Glob to check for active campaigns in `campaigns/active/*.md` and read any found.

Use Glob to check for existing pitch memos in `pipeline/010_pitches/*.md` — read these to avoid proposing duplicate angles.

Also check `pipeline/020_approved/*.md`, `pipeline/030_drafts/*.md`, `pipeline/040_review/*.md`, and `pipeline/050_published/*.md` for recently covered angles.

### Editorial Feedback

Read `pipeline/editorial-feedback.md` if it exists. Filter for entries where `status: open` and `targets` includes `angle`.

For each relevant entry:
- **angle-guidance**: Use these to shape convergence analysis. If editorial recommended recycling specific signal data into a different content type, actively look for that pattern. If editorial noted underrepresented content types, weight those higher in pitch recommendations.
- **held-pitch**: Check whether new signals in the knowledge base satisfy the conditions noted in the entry. If so, consider constructing a new pitch that incorporates the held pitch's thesis with stronger supporting evidence, or note in the pitch memo that this revisits a previously held angle with new data.

If the feedback file does not exist or contains no entries targeting angle, proceed normally.

After completing the angle scan: if your pitch memos directly address an open entry (e.g., you created a pitch recycling the data editorial suggested, or produced pitches for underrepresented content types), update the entry in `pipeline/editorial-feedback.md` — change `status` to `addressed`, add `addressed_by: angle`, `addressed_date: {today}`, `resolution: {brief description}`, and move it from "Active Entries" to "Addressed Entries".

## Step 2: Load Recent Signals

Use Glob to find all signal reports: `knowledge-base/signals/*.md`

Read each signal file. For efficiency, if there are many signals (>30), prioritise:
1. Signals from the last 7 days first
2. Signals with `angle_potential` >= 3
3. Signals with `source_tier` 1 or 2

Parse each signal's frontmatter to build a working index of:
- Signal ID, date, beat, tags
- Source tier and angle potential
- Suggested angles from each signal
- Related signals references

## Step 3: Identify Convergence Patterns

This is the core analytical step. Look for convergences across the signal inventory:

### Pattern Types to Detect

1. **Cross-beat convergence**: Signals from different beats that point to the same conclusion. Example: Industry Analysis shows pricing changes + Market Sentiment shows complaints about cost increases = angle about pricing squeeze.

2. **Temporal convergence**: Multiple signals about the same topic arriving within a short window, suggesting something is developing. Example: Three signals about a regulatory topic in one week after months of silence.

3. **Contradiction signals**: Signals that directly contradict each other or challenge conventional wisdom. Example: Official data says one thing but industry forums report the opposite.

4. **Compounding signals**: New signals that connect to older signals in the knowledge base, creating a richer picture than either alone. Use the `related_signals` field and shared tags to find these.

5. **Campaign-aligned signals**: Signals that directly serve an active campaign's thesis or topic area.

### Convergence Scoring

For each potential convergence pattern found, assess:
- **Signal count**: How many signals support this pattern? (minimum 2 required)
- **Source diversity**: Do signals come from multiple beats or source types?
- **Tier quality**: What's the highest-tier source involved?
- **Recency**: How fresh are the underlying signals?
- **Novelty**: Has this angle or a similar one been covered recently?

## Step 4: Apply Quality Filters

For each candidate angle, apply the four quality tests:

### The "So What?" Test
Would a reader immediately understand why this matters to their work? If the angle requires explaining why the reader should care, it's not ready. Score: pass/fail.

### The Synthesis Test
Does this angle require multiple sources? Can the thesis only be constructed by combining different data points? If a single article covers the same ground, kill it. Score: pass/fail (hard requirement — single-source angles are killed).

### The Novelty Test
Is this angle saying something the audience hasn't seen in trade publications this month? Check recent published pieces and pipeline contents for overlap. Score: pass/fail.

### The Durability Test
Will this be relevant in two weeks? If time-sensitive, flag for fast-tracking but don't kill it — just note the urgency. Score: durable / time-sensitive / expired.

Kill any angle that fails the "So What?", Synthesis, or Novelty tests. Flag time-sensitive angles for prioritisation.

## Step 5: Construct Pitch Memos

For each surviving angle, write a pitch memo to `pipeline/010_pitches/`.

### Filename Convention
`pitch-{YYYY-MM-DD}-{NNN}.md` where NNN is a zero-padded sequential number for the day.

Check existing files in `pipeline/010_pitches/` to determine the next available number for today's date.

### Pitch Memo Format

```markdown
---
id: pitch-{YYYY-MM-DD}-{NNN}
date: {YYYY-MM-DD}
status: pending
signals: [{signal-id-1}, {signal-id-2}, ...]
beats: [{beat-1}, {beat-2}]
tags: [{tag1}, {tag2}]
timeliness: durable | time-sensitive
campaign: {campaign-slug or null}
recommended_author: {author-name or null}
recommended_style: {style-slug or null}
recommended_type: {deep-analysis | commentary | regulatory | practitioner-insights | market-pulse}
---

# {Working Headline}

## Thesis
{2-3 sentence falsifiable thesis. This is the core argument the piece will make. It must be specific enough to be wrong.}

## Supporting Evidence
{For each supporting signal, list:}
- **{signal-id}** (Tier {N}, {beat}): {One-line summary of what this signal contributes}
- **{signal-id}** (Tier {N}, {beat}): {One-line summary}

## Counter-Evidence
{Known counter-arguments or contradicting data. If none found, note "No counter-evidence identified — validation should actively seek this."}

## Source Map
- Primary sources: {signal IDs that anchor the thesis}
- Supporting sources: {signal IDs that add context or colour}
- Gaps: {what additional evidence would strengthen this — guides validation}

## Recommended Treatment
- **Content type**: {from recommended_type}
- **Author**: {recommended author, with brief rationale}
- **Style**: {recommended style modifier}
- **Target audience**: {primary audience segment}
- **Estimated length**: {word range based on content type}

## Timeliness Assessment
{Why this is or isn't time-sensitive. If time-sensitive: what's the window? If durable: what makes it evergreen?}

## Campaign Alignment
{If this serves an active campaign, explain how. If not: "No active campaign alignment."}
```

## Step 6: Determine Author Recommendations

For each pitch memo, recommend an author and style by:

1. Use Glob to list available authors: `voice-models/authors/*/baseline.md`
2. Read each author's baseline to understand their perspective and strengths
3. Match the angle's topic, tone, and complexity to the best-fit author:
   - Data-heavy financial analysis → author with financial/analytical strength
   - Regulatory topics → author with regulatory expertise
   - Practitioner-focused practical pieces → author with operational perspective
   - Opinion/commentary → author with strong editorial voice

4. Check what styles that author has available: `voice-models/authors/{name}/style-*.md`
5. Recommend the style that best matches the content type

If uncertain, set `recommended_author: null` and note "Author assignment deferred to editorial review."

## Step 7: Summary Output

After writing all pitch memos, output a summary:

```markdown
## Angle Scan Summary — {date}

### Pitch Memos Written: {count}

| Pitch | |  |
|-------|-------|-------|
| **{Working Headline}** ({pitch-id}) | | |
| {Thesis — one-line summary} | | |
| Signals: {count} from {beat count} beats | Timeliness: {durable/time-sensitive} | Recommended: {author} / {style} / {content type} |
| | | |
| **{Working Headline}** ({pitch-id}) | | |
| ... | | |

### Angles Considered and Killed: {count}

| Angle | Reason |
|-------|--------|
| {Brief description} | {Which test failed and why} |

### Knowledge Base Status
- Total signals reviewed: {count}
- Signals with angle potential >= 3: {count}
- Cross-beat convergences detected: {count}
```

## Step 8: Git Commit

Stage all new and modified files:
- `pipeline/010_pitches/*.md` (new pitch memos)
- `pipeline/editorial-feedback.md` (if modified)

Commit with message:

```
Angle scan: {N} pitch memos from {M} signals

- {Pitch 1 headline}
- {Pitch 2 headline}
- ...
- {K} candidate angles killed (quality filter)
```

## Error Handling

- If no signals exist in the knowledge base, report "No signals in knowledge base. Run /research first." and exit
- If all candidate angles fail quality filters, report "No viable angles found this cycle" — this is expected and healthy
- If no authors exist in voice-models/, still write pitch memos but set recommended_author to null
- Never lower quality standards to produce pitch memos — zero pitches is a valid and common outcome

</process>
