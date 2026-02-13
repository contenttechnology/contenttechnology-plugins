---
name: add-beat
description: Create a new research beat configuration with source definitions, schedule, and methodology.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, AskUserQuestion, Glob
---

<objective>
Walk the user through creating a new research beat — a topic area with defined sources that the research skill will monitor for signals. Produce a complete beat configuration file with YAML frontmatter and methodology sections.
</objective>

<process>

## Step 1: Get Beat Identity

Use AskUserQuestion to gather basic beat information:

**Question 1 — Beat name**: "What is this beat called?"
- Options: "Industry Analysis", "Regulatory & Legal", "Market Sentiment", "Technology & Innovation", "Market Economics" (these are examples — the user can provide any name via Other)

**Question 2 — Schedule**: "How often should this beat be checked?"
- Options:
  - "every-run — Check on every research cycle"
  - "daily — Check once per day"
  - "weekly — Check once per week"

Generate a slug from the beat name: lowercase, hyphens for spaces (e.g., "Financial Intelligence" → `financial-intelligence`).

## Step 2: Validate No Duplicate

Use Glob to check `beats/*.md` for an existing file matching the slug. If a beat with this slug already exists, inform the user and ask whether to overwrite or choose a different name.

## Step 3: Gather Scope and Topics

**Question 3 — Scope**: "Describe the scope of this beat in 2-3 sentences. What does it cover and what does it exclude?"
- Provide a free-text option, plus an example: "Covers major developments, trends, and data releases in the target domain. Excludes tangential topics unless directly relevant to the core audience."

**Question 4 — Key tags**: "What are the key topic tags for this beat? (Select all that apply)"
- multiSelect: true
- Provide domain-relevant options plus Other:
  - "industry-trends", "regulation", "compliance", "technology", "operations", "market-data", "competition", "pricing", "innovation"

## Step 4: Define Sources (Iterative)

Start a source-adding loop. For each source, use AskUserQuestion:

**Source URL/Identifier**: "Enter the URL or identifier for this source."
- Free text input via options like "Enter URL" with description

**Source Type**: "What type of source is this?"
- Options: "RSS feed", "Web page", "API endpoint", "Public records or filings database", "Forum or community"

**Check Frequency**: "How often should this source be checked?"
- Options: "every-run — Every research cycle", "daily — Once per day", "weekly — Once per week"

**Credibility Tier**: "What credibility tier does this source fall into?"
- Options:
  - "Tier 1 (Gold) — Official data, regulatory filings, primary sources"
  - "Tier 2 (Strong) — Industry publications, reputable data providers"
  - "Tier 3 (Context) — News articles, analyst commentary, blogs"
  - "Tier 4 (Signal only) — Social media, forums, vendor marketing"

**Source Name**: "Give this source a human-readable name."
- Free text via options like "Enter name" with description

After each source is defined, ask: "Add another source to this beat?"
- Options: "Yes, add another source", "No, I'm done adding sources"

Continue the loop until the user indicates they're done. Require at least 1 source.

## Step 5: Define Research Methodology

Based on the beat scope and sources, generate a research methodology section. Ask the user:

**Question — Priority signals**: "What types of signals should this beat prioritise?"
- multiSelect: true
- Options:
  - "New data releases or filings"
  - "Changes in language or positioning"
  - "Trend shifts or reversals"
  - "Industry discussions and sentiment"
  - "Competitive moves or announcements"

## Step 6: Write Beat Configuration

Write the beat config to `beats/{slug}.md`:

```markdown
---
name: {Beat Name}
slug: {slug}
active: true
schedule: {every-run | daily | weekly}
description: {Scope description from Step 3}
tags: [{tag1}, {tag2}, ...]
sources:
  - url: {url}
    type: {rss | web | api | filing | forum}
    frequency: {every-run | daily | weekly}
    tier: {1-4}
    name: {Human-readable name}
  - url: ...
    ...
---

## Scope
{Expanded scope description from Step 3}

## Research Methodology
When scanning this beat, research agents should:
- Focus on: {priority signals from Step 5}
- Check sources in tier order (highest credibility first)
- Flag new material that differs from previously indexed content
- Look for connections to signals from other beats

## Signal Priorities
{Based on priority signals selected:}
1. {Priority signal type 1} — Highest priority, always report
2. {Priority signal type 2} — Report when substantive
3. {Priority signal type 3} — Report when pattern emerges
```

## Step 7: Git Commit

Stage the new beat file and commit with message:
```
Add research beat: {Beat Name}

- {N} sources configured ({breakdown by tier})
- Schedule: {schedule}
- Tags: {tag list}
```

Inform the user that the beat is active and will be included in the next research cycle.

> **Next steps:**
> 1. Run `/add-author` to create author voices (if not already configured)
> 2. Run `/research` to scan this beat for signals immediately

</process>
