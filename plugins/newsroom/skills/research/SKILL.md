---
name: research
description: Run a research cycle across all active beats — dispatch subagents, process local sources, produce signal reports, and update the knowledge base.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, WebFetch, WebSearch
---

<objective>
Execute the research stage of the editorial pipeline. Scan all active beats for new signals by dispatching subagents per beat, process any unprocessed local source files, produce signal reports, and update the knowledge base index. This is the engine's primary intelligence-gathering operation.
</objective>

<process>

## Step 1: Load Configuration

Read `config.md` from the project root to determine:
- Research mode (scan / investigate / deep-dive)
- Step budget for this cycle
- Source rotation settings

Read `knowledge-base/index.json` to get:
- `next_signal_id` — for assigning sequential IDs to new signals
- `processed_urls` — to avoid re-processing known content
- `processed_files` — to identify unprocessed local sources

Store these in working memory for the duration of the research cycle.

### Editorial Feedback

Read `pipeline/editorial-feedback.md` if it exists. Filter for entries where `status: open` and `targets` includes `research`.

For each relevant entry:
- **research-guidance**: Use these to prioritise beats and search queries this cycle. If editorial identified coverage gaps in a specific beat or topic, prioritise that beat's sources and expand search queries in that direction.
- **held-pitch**: Note what evidence is needed. When scanning beats, actively look for signals that could satisfy held pitch conditions.

If the feedback file does not exist or contains no entries targeting research, proceed normally.

After completing the research cycle: if your research produced signals that directly address an open entry, update the entry in `pipeline/editorial-feedback.md` — change `status` to `addressed`, add `addressed_by: research`, `addressed_date: {today}`, `resolution: {brief description}`, and move it from "Active Entries" to "Addressed Entries".

## Step 2: Identify Active Beats

Use Glob to find all beat configs: `beats/*.md`

Read each beat config file. Parse the YAML frontmatter to determine:
- Is this beat `active: true`?
- Does the schedule match the current cycle? (every-run beats always run; daily beats check if it's been 24+ hours since last run; weekly beats check if it's been 7+ days since last run)
- What sources does this beat define?

Build a list of beats to process this cycle.

If no active beats are found, report this to the user and skip to Step 5 (local sources).

## Step 3: Dispatch Research Subagents

For each active beat, dispatch a Task subagent (subagent_type: "general-purpose") with a detailed prompt.

**Calculate step budget per beat**: Divide the total step budget across active beats, weighted by number of sources. Beats with more sources get proportionally more budget.

**Subagent prompt template** (customise per beat):

```
You are a research agent for the "{beat_name}" beat of the Content Intelligence Engine.

## Your Beat
{Paste the full beat config markdown here, including scope and methodology}

## Already Processed Content
The following URLs and content have already been processed — do NOT report on these:
{List of processed_urls relevant to this beat's sources}

## Research Mode: {mode}
- scan: Quick check of each source. 2-3 steps per source. Extract headlines, key data points, notable changes.
- investigate: Follow promising threads. 10-15 steps per source.
- deep-dive: Exhaustive investigation. 20-30 steps per source.

## Your Task
1. For each source in the beat config, check for new content:
   - For web pages: Use WebFetch to load the page and identify new material
   - For RSS-type sources: Use WebFetch to check the feed
   - For search-based sources: Use WebSearch with relevant queries
2. For each piece of genuinely new content found:
   - Extract key data points, quotes, and facts
   - Assess the angle potential (1-5 scale)
   - Assess confidence (high/medium/low)
   - Note any connections to other topics or signals
3. Skip sources that have no new content (compare against processed URLs list)

## Output Format
Return your findings as a series of signal reports, each formatted as:

---SIGNAL---
beat: {beat_slug}
source_tier: {tier from beat config}
angle_potential: {1-5}
confidence: {high|medium|low}
source_url: {url}
source_name: {name}
source_type: {type}
tags: [{relevant tags}]
summary: |
  {2-4 sentence summary of the signal}
key_data_points:
  - {specific data point 1}
  - {specific data point 2}
suggested_angles:
  - {potential angle this signal could support}
related_topics:
  - {related topic or connection}
---END_SIGNAL---

If a source has no new content, note it briefly:
---NO_NEW---
source_url: {url}
source_name: {name}
reason: {no changes detected / same content as last scan}
---END_NO_NEW---
```

Launch subagents in parallel where possible (multiple Task calls in one message). Use `model: "sonnet"` for cost efficiency on research scanning.

## Step 4: Collect and Process Subagent Results

As each subagent returns:

1. Parse the `---SIGNAL---` blocks from the response
2. For each signal found:
   - Assign the next sequential signal ID: `sig-{YYYY-MM-DD}-{NNN}` (where NNN is zero-padded from `next_signal_id`)
   - Increment `next_signal_id`
   - Write the signal report to `knowledge-base/signals/{signal_id}.md` with full YAML frontmatter:

```markdown
---
id: {signal_id}
date: {today's date YYYY-MM-DD}
beat: {beat_slug}
source_tier: {tier}
angle_potential: {1-5}
confidence: {high|medium|low}
sources:
  - url: {source_url}
    type: {source_type}
    name: {source_name}
    accessed: {ISO timestamp}
related_signals: []
tags: [{tags}]
---

## Summary
{summary from subagent}

## Key Data Points
{key_data_points as bullet list}

## Suggested Angles
{suggested_angles as bullet list}
```

3. Update `processed_urls` in the index with each source URL checked (both those with and without new content)
4. Track the `---NO_NEW---` entries for the cycle summary

## Step 5: Process Local Source Files

Use Glob to scan `knowledge-base/sources/` for markdown files (excluding `.gitkeep`).

For each file found:
1. Check `processed_files` in the index — has this file already been processed? Compare by filename.
2. If not yet processed:
   - Read the file content
   - Parse any YAML frontmatter (beat, source_tier, title, url)
   - If `beat` is specified, associate with that beat; otherwise mark as `cross-beat`
   - Default `source_tier` to 1 if not specified (human-submitted sources are gold tier)
   - Generate a signal report from the content:
     - Assign next signal ID
     - Summarise the key points
     - Assess angle potential
     - Identify relevant tags
   - Write the signal report to `knowledge-base/signals/`
   - Add the filename to `processed_files` in the index with the processing timestamp

## Step 6: Update Knowledge Base Index

Write the updated `knowledge-base/index.json` with:
- Updated `last_updated` timestamp (ISO format)
- Updated `next_signal_id`
- Updated `processed_urls` with all URLs checked this cycle
- Updated `processed_files` with any newly processed local files
- Updated `signals` with metadata for each new signal:
  ```json
  {
    "sig-2026-02-08-001": {
      "date": "2026-02-08",
      "beat": "financial-intelligence",
      "tags": ["industry-trends", "market-data"],
      "source_tier": 1,
      "angle_potential": 4
    }
  }
  ```

Ensure the JSON is valid and properly formatted. Use `JSON.stringify` equivalent formatting (2-space indent).

## Step 7: Write Cycle Summary

Write a cycle summary to `metrics/cycle-{YYYY-MM-DD-HHmm}.md`:

```markdown
# Research Cycle Summary — {date and time}

## Configuration
- Mode: {research mode}
- Step budget: {budget used}
- Beats processed: {count}

## Results
- Total signals produced: {count}
- Signals by beat:
  {beat_name}: {count} signals
  ...
- Sources with no new content: {count}
- Local source files processed: {count}

## Signal Highlights
{List the top 3-5 signals by angle_potential, with their IDs and one-line summaries}

## Sources Checked
{List all sources checked with status: new content / no changes}

### Next Step
Run `/angle` to scan these signals for converging patterns and construct pitch memos.
```

## Step 8: Git Commit

Stage all new and modified files:
- `knowledge-base/signals/*.md` (new signal reports)
- `knowledge-base/index.json` (updated index)
- `metrics/cycle-*.md` (new cycle summary)
- `pipeline/editorial-feedback.md` (if modified)

Commit with message:
```
Research cycle: {N} signals from {M} beats

- Processed {beat count} active beats
- Produced {signal count} new signals
- {local file count} local source files processed
- Mode: {research mode}
```

## Error Handling

- If a subagent fails or returns no parseable signals, log it in the cycle summary and continue with other beats
- If WebFetch or WebSearch fails for a specific source, note the failure in the cycle summary and skip that source
- If `knowledge-base/index.json` is missing or corrupted, create a fresh index with `next_signal_id: 1`
- If `config.md` is missing, use defaults: scan mode, 80-step budget
- Never crash the entire research cycle because of a single source or beat failure

</process>
