---
name: rush
description: Rapid response pipeline for breaking news — compressed research, fast-track angle, abbreviated validation, immediate production and quality gate.
disable-model-invocation: true
argument-hint: "[topic description]"
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, WebFetch, WebSearch, AskUserQuestion
---

<objective>
Execute a compressed editorial pipeline for breaking news or time-sensitive topics. The rush skill collapses the normal multi-stage pipeline into a single fast session: focused research on the specific topic, fast-track angle construction, abbreviated validation, immediate production, and quality gate. The goal is a draft ready for human review within a single session.

The user triggers this with a topic description, e.g., "Rush: Major vendor just announced a significant pricing change."
</objective>

<process>

## Step 1: Parse the Rush Topic

The user's prompt contains the breaking news topic. Extract:
- **Topic**: The core subject of the breaking news
- **Urgency**: Infer from the prompt — is this hours-old, today, or emerging?

If the topic is unclear, use AskUserQuestion to clarify:

**Question**: "What is the breaking news or time-sensitive topic?"
- Free text input via descriptive options

Also ask for initial context:

**Question**: "What do you already know about this? Any URLs or details to start from?"
- Options:
  - "I have a URL or source to share"
  - "Just the headline — research from scratch"

If they have a URL, capture it for the research step.

## Step 2: Load Configuration and Context

Read:
1. **`PUBLICATION.md`** — Editorial mission
2. **`config.md`** — Quality thresholds
3. **`voice-models/brand-guidelines.md`** — Brand constraints
4. **`knowledge-base/index.json`** — Check for existing signals on this topic

Use Grep to search existing signals for related content: `knowledge-base/signals/*.md`
Search for keywords from the rush topic to find any prior coverage.

Use Glob to check for active campaigns in `campaigns/active/*.md` — is this topic aligned with an active campaign?

## Step 3: Focused Research

Dispatch 2-3 research subagents in parallel (Task, subagent_type: "general-purpose", model: "sonnet") focused specifically on the rush topic.

### Subagent 1: Primary Source Research

```
You are a rapid-response research agent. A breaking story requires immediate coverage.

## Topic
{Rush topic description}

## Starting Point
{URL or details provided by user, if any}

## Your Task
Find the primary source material for this story:
1. The original announcement, filing, press release, or event
2. Key data points and quotes
3. The specific facts — who, what, when, where, why
4. Any official statements

Use WebSearch and WebFetch to find primary sources. Prioritise:
- Official company announcements and press releases
- Regulatory filings
- Verified news reports from credible outlets

## Output Format
Return findings as:

PRIMARY_SOURCES:
{For each source found:}
- URL: {url}
  Type: {press release | filing | news report | official statement}
  Tier: {1-4}
  Key Facts:
    - {fact 1}
    - {fact 2}
  Key Quotes:
    - "{quote}" — {attribution}
  Date: {publication date}
```

### Subagent 2: Industry Context and Reaction

```
You are a rapid-response research agent gathering industry context and reaction.

## Topic
{Rush topic description}

## Your Task
Find how the industry is reacting and provide context:
1. Industry commentary and analysis
2. Social media and forum reactions from industry professionals
3. Historical context — has something similar happened before?
4. Competitor responses or related announcements
5. Expert analysis or predictions

Use WebSearch to find reactions, commentary, and context.

## Output Format
Return findings as:

CONTEXT_AND_REACTION:
{For each finding:}
- Source: {url or description}
  Type: {commentary | reaction | historical | expert analysis}
  Tier: {1-4}
  Summary: {what this adds to the story}
  Sentiment: {positive | negative | neutral | mixed}
  Key Points:
    - {point 1}
    - {point 2}
```

### Subagent 3: Impact Analysis (if topic warrants)

Only dispatch this if the topic involves financial, regulatory, or operational impact:

```
You are a rapid-response research agent assessing impact.

## Topic
{Rush topic description}

## Your Task
Assess the practical impact of this news:
1. Who is affected and how?
2. What are the immediate operational implications?
3. What are the financial implications?
4. What should practitioners do right now?
5. What's the timeline for impact?

Use WebSearch to find impact analysis, affected parties, and operational guidance.

## Output Format
Return findings as:

IMPACT_ANALYSIS:
- Affected parties: {who}
- Immediate impact: {what changes now}
- Financial impact: {if quantifiable}
- Operational implications:
  - {implication 1}
  - {implication 2}
- Recommended actions:
  - {action 1}
  - {action 2}
- Timeline: {when does this take effect}
```

## Step 4: Fast-Track Angle Construction

Once research subagents return, construct the angle inline (no separate angle skill invocation):

### Synthesise Research Results
Combine the findings from all subagents into a coherent picture:
- Primary facts and data
- Industry context and reaction
- Impact assessment

### Construct Thesis
Build a falsifiable thesis that:
- Combines multiple sources (minimum 2)
- Passes the "So What?" test — readers must immediately understand why this matters
- Has a specific, defensible claim — not just "X happened"
- Accounts for the context and reaction landscape

### Quick Quality Check
Apply abbreviated quality filters:
- **Synthesis test**: Does this require multiple sources? (mandatory — still cannot be single-source even in rush mode)
- **"So What?" test**: Would a reader stop scrolling? (mandatory)
- **Novelty**: This is breaking news, so novelty is likely high — but check we're adding insight, not just relaying the announcement

If the angle fails these tests, report to the user that the story doesn't yet have enough substance for a Newsroom piece, and suggest monitoring for developments.

## Step 5: Abbreviated Validation

Dispatch 2 validation subagents in parallel (abbreviated from the normal 4):

### Counter-Evidence Check (3-5 steps)

```
You are a rapid validation agent. Quickly check for counter-evidence to this thesis.

## Thesis
{The constructed thesis}

## Your Task (ABBREVIATED — 3-5 steps max)
Search for:
1. Anyone contradicting or disputing this news
2. Alternative interpretations
3. Reasons this might not be as significant as it appears

Be quick but thorough. This is a rapid response — we need speed but can't publish something that's factually wrong.

## Output
COUNTER_CHECK:
threat_level: {fatal | significant | manageable | minimal}
findings:
  - {counter-point 1, if any}
  - {counter-point 2, if any}
recommendation: {PROCEED | REFINE | KILL}
```

### Scope Check (3-5 steps)

```
You are a rapid validation agent checking the scope of this angle.

## Thesis
{The constructed thesis}

## Your Task (ABBREVIATED — 3-5 steps max)
Quickly assess:
1. Is this national or regional?
2. Does it affect the whole industry or a subset?
3. Is the significance being over- or under-stated?

## Output
SCOPE_CHECK:
scope: {national | regional | segment-specific}
significance: {high | moderate | low}
audience_fit: {broad | targeted}
notes: {any scope adjustments needed}
```

If counter-evidence is fatal, inform the user and do not proceed to production. If manageable, refine the thesis and proceed.

## Step 6: Author Assignment

Determine the best author for this rush piece:

1. Use Glob to list available authors: `voice-models/authors/*/baseline.md`
2. Read baselines quickly — match the topic to the author whose expertise and voice best fit
3. Select appropriate style modifier based on content type:
   - Financial/data-driven news → deep-analysis or commentary
   - Regulatory news → regulatory
   - Operational/competitive news → commentary or practitioner-insights
   - Industry drama/absurdity → humorous (if appropriate)

Use AskUserQuestion if there are multiple good options:

**Question**: "Which author should write this rush piece?"
- List available authors with brief rationale for each

## Step 7: Produce Draft

Dispatch a production subagent (Task, subagent_type: "general-purpose") with the full context:

```
You are a rapid-response production writer. Write a complete article draft on a breaking story.

## CRITICAL: SPEED AND ACCURACY
This is a rush piece — timeliness matters. But accuracy is non-negotiable. If you're uncertain about a fact, flag it rather than guessing.

## RULES
1. SYNTHESIS, NOT SUMMARISATION: Even in rush mode, weave sources together
2. NO AI TELLS: No hedging, no "In today's...", no empty transitions
3. SPECIFIC: Every claim backed by specific data or attribution
4. READER-FIRST: Write for people who need to understand what this means for their business

## Brand Voice Constraints
{Paste brand-guidelines.md}

## Author Voice: {author name}
{Paste baseline.md}

## Style: {style name}
{Paste style modifier}

## The Story
### Thesis
{The approved thesis}

### Primary Sources
{Primary source findings with facts, data, quotes}

### Context and Reaction
{Context findings}

### Impact
{Impact analysis}

### Counter-Arguments to Address
{From validation, if any}

## Structure Guidance
For a rush piece:
- Open with the news and why it matters — no throat-clearing
- Establish the facts quickly (paragraph 1-2)
- Provide context — why this is significant (paragraph 3-4)
- Analyse the implications for practitioners (core of the piece)
- Address counter-arguments or alternative interpretations briefly
- Close with what practitioners should do now and what to watch for next

## Target Length
{Based on content type — typically 600-1,200 words for rush pieces. Enough to be substantive, short enough to be timely.}

## Output Format
---DRAFT_START---
{Complete article with headline}
---DRAFT_END---

WORD_COUNT: {count}
CONFIDENCE_FLAGS: {any facts you're uncertain about — flag for human verification}
```

## Step 8: Quick Quality Check

Run an abbreviated quality gate inline (not dispatched as separate subagent — speed matters):

Review the draft yourself against these criteria:
1. **Factual accuracy**: Are all claims traceable to the research?
2. **Thesis delivery**: Does the piece deliver on the thesis?
3. **AI-tell scan**: Quick scan for obvious AI patterns
4. **Voice match**: Does it sound like the assigned author?
5. **Readability**: Would a busy professional read this right now?

If the draft has critical issues (factual errors, thesis drift, egregious AI tells), revise inline — edit the specific problems rather than re-producing the entire draft. Rush pieces get **1 revision cycle max**.

If the draft is unsalvageable, inform the user and explain why.

## Step 9: Save All Outputs

### Signal Reports
Write any new signals discovered during research to `knowledge-base/signals/` following the standard format. Update `knowledge-base/index.json`.

### Pitch Memo
Write a pitch memo to `pipeline/pitches/` with `status: approved` (retroactive — rush pieces skip the normal pitch → validate → editorial flow):

```markdown
---
id: pitch-{YYYY-MM-DD}-rush-{NNN}
date: {YYYY-MM-DD}
status: approved
rush: true
signals: [{signal IDs}]
beats: [{relevant beats}]
tags: [{tags}]
timeliness: time-sensitive
---

# {Headline}

## Thesis
{thesis}

## Rush Context
This angle was produced via the rush pipeline in response to: {original topic}

{Abbreviated supporting/counter evidence}
```

### Production Brief
Write a brief to `pipeline/approved/` with `status: produced`:

```markdown
---
id: brief-{YYYY-MM-DD}-rush-{NNN}
date: {YYYY-MM-DD}
status: produced
rush: true
pitch_id: {pitch ID}
author: {author}
style: {style}
draft_id: {draft ID}
---

# Rush Brief: {Headline}

{Abbreviated brief — thesis, sources, author assignment}
```

### Draft
Write the draft to `pipeline/review/` (skipping `pipeline/drafts/` since it passed the quality check):

```markdown
---
id: draft-{YYYY-MM-DD}-rush-{NNN}
date: {YYYY-MM-DD}
status: passed
rush: true
brief_id: {brief ID}
pitch_id: {pitch ID}
author: {author}
style: {style}
content_type: {type}
word_count: {count}
revision: 0
---

{Article text}

---

## Rush Production Metadata

### Confidence Flags
{Any facts flagged for human verification}

### Sources Used
{List of sources with URLs}

### Timeline
- Research started: {time}
- Draft completed: {time}
```

## Step 10: Summary and Handoff

Output a clear summary for the user:

```markdown
## Rush Complete: {Headline}

### Status: Ready for Human Review
Draft is in `pipeline/review/{draft-id}.md`

### Confidence Flags
{Any facts that need human verification before publication}

### Key Facts
{3-5 bullet point summary of the piece}

### Sources ({count})
{List sources with tiers}

### Author: {author} / Style: {style}
### Word Count: {count}
### Time-Sensitivity: {how long this piece remains relevant}

### Next Steps
1. Review the draft in `pipeline/review/`
2. Verify any flagged facts
3. Approve, revise, or kill
```

## Step 11: Git Commit

Stage all new files and commit:

```
Rush: {Headline}

- Topic: {rush topic}
- {N} signals captured, draft ready for review
- Author: {author} / {word count} words
- Confidence flags: {count or "none"}
```

## Error Handling

- If research subagents find almost nothing, inform the user: "Not enough source material for a Newsroom-quality piece. Consider monitoring this topic and running /newsroom:research when more information emerges."
- If the synthesis test fails (only one source), do not force production. Inform the user that the story needs more sources before Newsroom can cover it with integrity.
- If author voice models are missing, ask the user to select an author or write in brand-voice-only mode as a fallback.
- Always flag confidence issues explicitly — rush pieces have higher factual risk and the human must know what to verify.
- Speed matters but accuracy is non-negotiable. Never guess a fact, quote, or data point.

</process>
