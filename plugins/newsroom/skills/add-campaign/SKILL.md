---
name: add-campaign
description: Interactive session to create a new editorial campaign — seasonal, event-driven, thematic, or rapid response.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, Glob
---

<objective>
Walk the user through defining a new editorial campaign. Campaigns focus the engine's research, angle construction, and production around a specific topic, event, or theme for a defined period. The campaign brief guides all pipeline stages to prioritise aligned content.
</objective>

<process>

## Step 1: Campaign Type

Use AskUserQuestion to determine the campaign type:

**Question — Type**: "What type of campaign is this?"
- Options:
  - "Seasonal — Recurring industry cycle (e.g., Q1 rate increases, summer demand, budget season)"
  - "Event-driven — Specific event creating an audience interest window (e.g., conference, major announcement, regulatory change)"
  - "Thematic — Sustained focus on a topic for 4-8 weeks (e.g., emerging market trends, technology adoption, regulatory impact)"
  - "Rapid Response — Breaking news requiring expedited pipeline (use /rush for immediate firefighting)"

If the user selects "Rapid Response", inform them that `/rush` is better suited for immediate breaking news, but a rapid response campaign can be created here to sustain coverage over several days after the initial rush piece. Ask if they want to continue or use `/rush` instead.

## Step 2: Campaign Identity

Use AskUserQuestion to gather:

**Question 1 — Name**: "What is the campaign name?"
- Options: Provide examples relevant to the selected type, plus Other for free text
  - Seasonal: "Q1 Rate Season 2026", "Summer Demand Cycle", "Budget Planning Season"
  - Event-driven: "Annual Industry Conference", "Q4 Data Releases", "Major Vendor Announcement"
  - Thematic: "Market Consolidation Trends", "Technology Adoption Deep Dive", "Regulatory Landscape Guide"

**Question 2 — Duration**: "How long will this campaign run?"
- Options:
  - "1-2 weeks (event-driven, rapid response)"
  - "3-4 weeks (seasonal, short thematic)"
  - "6-8 weeks (full thematic series)"
  - "Ongoing until manually closed"

Generate a slug from the campaign name: lowercase, hyphens for spaces.

## Step 3: Campaign Thesis and Goals

**Question 3 — Central thesis**: "What is the central thesis or question this campaign explores?"
- Options: Provide type-appropriate examples plus Other
  - "How are practitioners adapting to [specific change]?"
  - "What does [event] mean for the industry?"
  - "The hidden economics of [topic]"

**Question 4 — Goals**: "What should this campaign achieve? Select all that apply."
- multiSelect: true
- Options:
  - "Establish authority on this topic before competitors"
  - "Provide actionable guidance during a critical period"
  - "Build a comprehensive resource on a complex topic"
  - "Capture audience attention during a high-interest window"

## Step 4: Content Plan

**Question 5 — Planned pieces**: "How many pieces do you envision for this campaign?"
- Options:
  - "2-3 pieces (focused burst)"
  - "4-6 pieces (standard campaign)"
  - "7-10 pieces (comprehensive series)"
  - "Flexible — produce as warranted"

**Question 6 — Content types**: "What content types should this campaign include? Select all that apply."
- multiSelect: true
- Options:
  - "Deep Analysis — Flagship multi-source synthesis (1,500-2,500 words)"
  - "Commentary — Opinionated shorter takes (800-1,200 words)"
  - "Regulatory Watch — Regulatory impact analysis (600-1,000 words)"
  - "Practitioner Insights — Practical operational intelligence (400-800 words)"
  - "Market Pulse — Data-driven snapshots (300-600 words)"

## Step 5: Research Focus

**Question 7 — Key topics**: "What specific topics or keywords should research prioritise for this campaign?"
- Options: Provide examples relevant to the campaign thesis plus Other for free text

**Question 8 — Priority sources**: "Are there specific sources that are critical for this campaign?"
- Options:
  - "Yes, I'll specify key sources"
  - "No, use existing beat sources"

If they choose to specify sources, ask for URLs/descriptions iteratively (similar to add-beat source loop). These become campaign-specific research priorities.

## Step 6: Author and Audience

**Question 9 — Preferred author**: "Is there a preferred author for this campaign?"

Use Glob to find `voice-models/authors/*/baseline.md` and list available authors as options, plus:
- "Rotate across authors"
- "No preference — assign per piece"

**Question 10 — Target audience**: "Who is the primary audience for this campaign?"
- multiSelect: true
- Options:
  - "Industry practitioners"
  - "Business leaders and executives"
  - "Industry investors"
  - "Technology buyers"

## Step 7: Validate No Duplicate

Use Glob to check `campaigns/active/*.md` for an existing campaign with the same slug. If found, inform the user and ask whether to replace or rename.

## Step 8: Write Campaign Brief

Write the campaign brief to `campaigns/active/{slug}.md`:

```markdown
---
name: {Campaign Name}
slug: {slug}
type: {seasonal | event-driven | thematic | rapid-response}
status: active
start_date: {today's date}
end_date: {calculated from duration, or null if ongoing}
duration: {selected duration}
preferred_author: {author or null}
audience: [{audience segments}]
tags: [{key topics}]
piece_count_target: {target or "flexible"}
---

# Campaign: {Campaign Name}

## Central Thesis
{The central thesis or question from Step 3}

## Campaign Goals
{Goals from Step 4 as bullet points}

## Content Plan

### Target Pieces: {count or "flexible"}
### Content Types
{List of selected content types with brief notes on how each serves the campaign}

### Suggested Sequence
{Based on campaign type and content plan, suggest an order:}
1. {First piece — e.g., "Opening analysis establishing the landscape"}
2. {Second piece — e.g., "Data-driven deep dive on the core thesis"}
3. {Third piece — e.g., "Practitioner perspective / practical implications"}
{...}

## Research Priorities

### Key Topics
{Key topics from Step 7 as bullet points}

### Priority Sources
{Campaign-specific sources if provided, or "Use existing beat sources"}

### Research Guidance
When scanning beats during this campaign:
- Prioritise signals related to: {key topics}
- Flag any signals that connect to the central thesis
- Look for: {type-specific guidance}
  - Seasonal: historical patterns, year-over-year comparisons, early indicators
  - Event-driven: pre-event speculation, live coverage, post-event analysis
  - Thematic: multiple angles on the core topic, counter-arguments, data patterns

## Pipeline Influence

### Angle Construction
The angle agent should actively look for convergences related to this campaign's thesis. Campaign-aligned angles receive priority in editorial review.

### Editorial Priority
Campaign pieces should be prioritised in the editorial mix, but never at the expense of quality. A weak campaign piece is worse than no campaign piece.

### Production Notes
{Any specific guidance for production — tone, framing, what to emphasise}

## Success Criteria
{What would make this campaign successful — based on goals}

## Status Log
- {today's date}: Campaign created
```

## Step 9: Git Commit

Stage the new campaign brief:

```
Add campaign: {Campaign Name}

- Type: {type}
- Duration: {duration}
- Target: {piece count} pieces
- Focus: {central thesis summary}
```

Inform the user that the campaign is active and will influence the next research and editorial cycles.

> **Next steps:**
> 1. Run `/research` to start gathering signals aligned with this campaign
> 2. Or run `/run` to execute the full pipeline with campaign priorities active

</process>
