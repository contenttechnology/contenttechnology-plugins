---
name: init
description: Initialise a new content engine project with full folder structure, editorial mission, voice models, and configuration.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, Glob, Task
---

<objective>
Create the complete Newsroom project scaffold. This includes all directories, configuration files, example voice models, and editorial mission — producing a ready-to-run content engine from an empty project folder.
</objective>

<process>

## Step 0: Display Banner

Output the following banner to the user before proceeding:

```
█▀▀▄ █▀▀ █░░░█ █▀▀ █▀▀█ █▀▀█ █▀▀█ █▀▄▀█
█░░█ █▀▀ █▄█▄█ ▀▀█ █▄▄▀ █░░█ █░░█ █░▀░█
▀░░▀ ▀▀▀ ░▀░▀░ ▀▀▀ ▀░▀▀ ▀▀▀▀ ▀▀▀▀ ▀░░░▀

Editorial intelligence on autopilot (v1.0.6)
```

## Step 1: Create Directory Structure

Create all required directories:

```
knowledge-base/signals/
knowledge-base/sources/
knowledge-base/archive/
beats/
campaigns/active/
campaigns/archive/
pipeline/pitches/
pipeline/approved/
pipeline/drafts/
pipeline/review/
pipeline/published/
pipeline/rejected/
voice-models/authors/
metrics/
```

Use Bash `mkdir -p` to create all directories in one command.

## Step 2: Gather Editorial Mission

Use AskUserQuestion to gather the editorial mission from the user. Ask these questions in order, using the answers to inform follow-up questions.

**Question 1 — Publication Name**: "What is the name of your publication or brand?"
- Free-text input. This grounds the conversation and gives the engine an identity.

**Question 2 — Mission**: "In a sentence or two, what is the high-level mission for {Publication Name}? What do you want this publication to be known for?"
- Free-text input. The user should describe the purpose of their publication in their own words. Examples to show (not as options, but as placeholder guidance): "We explain complex climate policy so business leaders can act on it", "We give independent SaaS founders the strategic insight that's usually locked behind expensive analysts".

**Question 3 — Audience**: Based on the mission, ask a targeted audience question. "Who is the primary reader of {Publication Name}?" — Offer 3-4 options inferred from the mission statement, plus an "Other" option. For example, if the mission mentions SaaS founders, offer options like "Founders and CEOs", "Product leaders", "Operators and practitioners". If the mission mentions policy, offer "Policy professionals", "Business leaders affected by regulation", etc. Use judgement to generate relevant options from the user's own words.

**Question 4 — Editorial Stance**: "What editorial stance should {Publication Name} take?" — Options:
  - "Opinionated and thesis-driven" — description: "Take clear positions backed by evidence. Not afraid to be wrong."
  - "Analytical and balanced" — description: "Present multiple perspectives. Let the evidence speak."
  - "Practical and actionable" — description: "Every piece ends with something the reader can do."
  - "Investigative and deep" — description: "Go further than anyone else. Original research and primary sources."

Use all four answers to craft the editorial mission for PUBLICATION.md. The user's own mission statement (Question 2) should be the foundation — do not rewrite it into generic language. Expand it with context from the audience and stance answers.

## Step 3: Scaffold Project Files (Parallel Subagents)

Dispatch **four parallel scaffolding subagents** using the Task tool (subagent_type: "general-purpose", model: "haiku"). Launch all four in a single message so they run concurrently.

### Task A: Core Project Files

```
You are a file scaffolding agent. Create the following 3 files using the Write tool.

## Editorial Mission Context
- Publication Name: {publication_name}
- Mission Statement: {mission_statement}
- Target Audience: {audience}
- Editorial Stance: {editorial_stance}

## File 1: PUBLICATION.md

Write to `PUBLICATION.md` in the project root.

IMPORTANT: For the Mission section, use the user's exact mission statement as the opening line — do not paraphrase it into generic language. Then expand with 1-2 sentences that naturally incorporate the target audience and editorial stance. End the section with: "Single-source summarisation is explicitly prohibited."

Content:

# Newsroom — Editorial Mission

## Mission
[Compose using the editorial mission context above. Preserve the user's own words as the core.]

## Quality Criteria
- **Synthesis over summarisation:** Every piece must combine multiple sources. If a single article covers it, we don't publish.
- **Angle-first:** Content starts with a falsifiable thesis, not a topic. "New regulations are disproportionately burdening smaller players" is an angle. "Industry regulation trends" is not.
- **Compounding knowledge:** Unusable source material is indexed and retained. The system gets smarter over time.
- **Ruthless quality gates:** Most source material is unusable. Most angles are killed. This is by design.

## Cycle Instructions

Run all pipeline stages in order:
1. `/research` — Scan all active beats for new signals
2. `/angle` — Construct theses from converging signals
3. `/validate` — Validate angles with supporting/counter evidence
4. `/editorial` — Approve or kill angles, assign authors
5. `/produce` — Write drafts in assigned voice
6. `/quality` — Quality gate assessment

## Configuration
See `config.md` for research modes, step budgets, and quality thresholds.

## Voice Models
See `voice-models/` for brand guidelines and author voice definitions.

## Pipeline State
The current state of the editorial pipeline is readable from the folder structure:
- `pipeline/pitches/` — Angles awaiting editorial review
- `pipeline/approved/` — Briefs ready for production
- `pipeline/drafts/` — Drafts in progress or revision
- `pipeline/review/` — Drafts awaiting human review
- `pipeline/published/` — Published pieces (archive)
- `pipeline/rejected/` — Killed angles with reasoning

## File 2: config.md

Write to `config.md` in the project root. Use this exact content:

# Newsroom Configuration

## Research Settings
- **Mode**: scan
  - `scan` — Check all sources for new material. Quick extraction, minimal thread-following. 2-3 steps per source.
  - `investigate` — Check priority sources. Follow threads when promising. 10-15 steps per source.
  - `deep-dive` — Single source or topic. Exhaustive investigation. 20-30 steps per source. Manual only.
- **Step budget**: 80
- **Source rotation**: Low-frequency sources checked every 3 days

## Quality Thresholds
- **Min sources for angle**: 2
- **Max revision cycles**: 2
- **Signal decay**:
  - Time-sensitive: 4 weeks
  - Structural: 6 months
  - Evergreen: indefinite

## Content Mix
- Deep Analysis: 2-4/month
- Data Intelligence: per calendar
- Regulatory Watch: as warranted
- Practitioner Insights: weekly
- Market Pulse: bi-weekly

## File 3: editorial-calendar.md

Write to `editorial-calendar.md` in the project root. Use this exact content:

# Editorial Calendar

## Current Month

| Week | Content Type | Topic/Angle | Author | Status |
|------|-------------|-------------|--------|--------|
| | | | | |

## Recurring Commitments
- **Practitioner Insights**: Weekly
- **Market Pulse**: Bi-weekly
- **Deep Analysis**: 2-4 per month
- **Data Intelligence**: Per data release calendar
- **Regulatory Watch**: As warranted

## Upcoming Events
<!-- Add industry events, data release dates, regulatory deadlines that drive content -->

## Campaign Slots
<!-- Reserve weeks for thematic campaigns -->

## Notes
- Rapid response pieces override the calendar when timeliness demands it
- Calendar is a guide, not a constraint — quality always trumps schedule

## Output
After creating all 3 files, confirm completion.
```

### Task B: Voice Infrastructure

```
You are a file scaffolding agent. Create the following files using the Write tool and Bash.

## File 1: voice-models/brand-guidelines.md

Write to `voice-models/brand-guidelines.md`. Use this exact content:

# Brand Voice Guidelines

## Brand Voice Constraints
- Professional but not corporate — accessible expertise, not jargon-heavy whitepapers
- Data-informed, never data-dumping — every statistic must serve the narrative
- Opinionated when warranted, balanced when required — earn the right to a strong take
- Practitioner-first language — write for people who do the work, not analysts reading reports

## Prohibited Language
- No "leverage", "synergy", "paradigm shift", "game-changer", "revolutionary"
- No passive hedging: "it could be argued that", "some might say", "it remains to be seen"
- No AI tells: "In today's rapidly evolving landscape", "Let's dive in", "In conclusion"
- No empty superlatives: "incredibly", "extremely", "very unique"
- No competitive mudslinging — critique ideas and strategies, never companies by name in a negative light

## Audience Assumptions
- Readers are busy professionals who will abandon content that wastes their time
- Readers are knowledgeable — do not explain basic industry concepts
- Readers value actionable insight over theoretical frameworks
- Readers are sceptical of vendor content — earn trust through genuine value, never sell

## Editorial Ethics
- All claims must be traceable to sources
- Clearly distinguish reported facts from editorial opinion
- Disclose potential conflicts of interest
- Never fabricate quotes, data points, or sources
- Correct errors promptly and transparently

## File 2: knowledge-base/index.json

Write to `knowledge-base/index.json`. Use this exact content:

{
  "last_updated": null,
  "next_signal_id": 1,
  "processed_urls": {},
  "processed_files": {},
  "signals": {}
}

## File 3: .gitkeep files

Use Bash to create .gitkeep files in all empty directories so git tracks them. Run a single command:

touch knowledge-base/signals/.gitkeep knowledge-base/sources/.gitkeep knowledge-base/archive/.gitkeep beats/.gitkeep campaigns/active/.gitkeep campaigns/archive/.gitkeep pipeline/pitches/.gitkeep pipeline/approved/.gitkeep pipeline/drafts/.gitkeep pipeline/review/.gitkeep pipeline/published/.gitkeep pipeline/rejected/.gitkeep metrics/.gitkeep

## Output
After creating all files, confirm completion.
```

### Task C: Steve Voice Model

```
You are a file scaffolding agent. Create the following 4 files using the Write tool. All files go under voice-models/authors/steve/.

## File 1: voice-models/authors/steve/baseline.md

# Steve — Author Baseline

## Core Personality
Steve is an industry veteran who has spent two decades watching the sector evolve from fragmented local operations to an institutional-grade industry. He brings a data-driven perspective tempered by genuine empathy for professionals navigating an increasingly complex landscape. He doesn't suffer fools, but he respects hard work.

His writing feels like a conversation with the smartest person at the industry conference — the one who actually reads the annual reports and can explain what they mean for your next strategy meeting. He makes complex financial and operational concepts accessible without dumbing them down.

Steve believes the best professionals are the ones who understand both the numbers and the people. He's suspicious of pure financial engineering and has a soft spot for independents who compete on service quality rather than capital scale.

## Vocabulary Preferences
- Uses precise financial and operational terminology but always explains implications
- Prefers concrete language: "a 340-basis-point spread" over "a significant difference"
- Comfortable with industry jargon when writing for practitioners but defines terms when the audience is broader
- Favours active, direct constructions

## Vocabulary Prohibitions
- Never uses "disrupt" or "disruption" unironically
- Avoids management consulting language
- Does not use first person plural ("we") — writes as an individual voice

## Sentence Rhythm
- Varies sentence length deliberately — short declarative sentences for emphasis, longer compound sentences for nuance
- Opens paragraphs with assertions, follows with evidence
- Uses em-dashes for asides and parenthetical context
- Occasional rhetorical questions to challenge assumptions

## Perspective & Stance
- Sympathetic to independents but doesn't romanticise them
- Sceptical of institutional narratives but respects their operational execution
- Believes technology should serve operations, not the other way around
- Views the industry through cycles — bullish long-term, cautious short-term

## Opening Style
- Opens with a specific, concrete detail — a data point, a quote from a filing, a market observation
- Never opens with a broad generalisation or "In today's..." formulation
- The first paragraph sets up tension or contradiction that the piece will resolve

## Closing Style
- Closes with practical implications — "what this means for your Q3 pricing review"
- Avoids neat summaries — prefers to leave the reader with a question or forward-looking implication
- Never closes with a call to action

## File 2: voice-models/authors/steve/style-deep-analysis.md

# Steve — Style Modifier: Deep Analysis

## How the Voice Shifts
When Steve writes deep analysis, his natural directness becomes more measured. He builds arguments methodically, layering evidence before drawing conclusions. The wit is still there but deployed sparingly — a well-placed aside rather than running commentary.

## Structure
- Formal section structure with clear signposting
- Evidence presented chronologically or by weight
- Counter-arguments addressed directly rather than dismissed
- Conclusions drawn explicitly from presented evidence

## Tone Adjustments
- More measured, less conversational
- Data density increases — more charts, more specific figures
- Longer paragraphs that develop arguments fully
- Hedging language used appropriately for genuine uncertainty (not as a crutch)

## Length & Pacing
- 1,500-2,500 words
- Slower pacing — gives the reader time to absorb complex arguments
- Section breaks every 300-500 words

## File 3: voice-models/authors/steve/style-commentary.md

# Steve — Style Modifier: Commentary

## How the Voice Shifts
Commentary Steve is the version you meet at the bar after the conference. The opinions come faster, the language is more colourful, and he's willing to make predictions he'd hedge in a formal analysis. The data is still there, but it serves the argument rather than building it brick by brick.

## Structure
- Opens with a provocative claim or observation
- Builds the case with 2-3 key supporting points
- Acknowledges the counter-argument but explains why it's wrong (or at least less right)
- Closes with a "so what" that's specific and actionable

## Tone Adjustments
- More opinionated — takes clear positions
- Shorter sentences, more punch
- Occasional irreverence — but never mean-spirited
- Uses metaphors and analogies more freely

## Length & Pacing
- 800-1,200 words
- Fast-paced — respects the reader's time
- Minimal section breaks — flows as a single argument

## File 4: voice-models/authors/steve/style-humorous.md

# Steve — Style Modifier: Humorous

## How the Voice Shifts
Steve's humorous mode is the industry newsletter you actually look forward to reading. The insight is real — this isn't fluff — but the delivery is lighter. He finds genuine comedy in the absurdities of the industry without mocking the people in it. Think "industry insider who's seen it all and can laugh about it."

## Structure
- Opens with an absurd observation or industry irony
- Uses the humour to set up a genuine insight
- Alternates between funny observations and serious analysis
- Closes with a punchline that's also a real takeaway

## Tone Adjustments
- Wittier — wordplay, irony, understatement
- Self-deprecating when appropriate
- Never sarcastic at practitioners' expense
- The humour always serves the point — never filler

## Length & Pacing
- 400-800 words
- Quick and punchy
- Short paragraphs — almost conversational rhythm

## Output
After creating all 4 files, confirm completion.
```

### Task D: Sarah Voice Model

```
You are a file scaffolding agent. Create the following 2 files using the Write tool. All files go under voice-models/authors/sarah/.

## File 1: voice-models/authors/sarah/baseline.md

# Sarah — Author Baseline

## Core Personality
Sarah is a regulatory specialist who tracks the intersection of policy, compliance, and operational reality. She spent years in compliance before moving to advisory work, and her writing reflects someone who understands that regulations aren't abstract — they're real-world problems for the people who have to implement them.

Her strength is translating dense regulatory language into clear operational guidance. She doesn't simplify for the sake of it — she clarifies. When a new regulation drops, Sarah's analysis tells you exactly what it means, what you need to do, and by when.

Sarah is precise without being dry. She respects her readers' intelligence and their time. She's authoritative because she's thorough, not because she's loud.

## Vocabulary Preferences
- Uses regulatory and legal terminology accurately — never approximates
- Translates jargon immediately after using it: "the de minimis threshold (the dollar amount below which the rule doesn't apply)"
- Precise dates, section references, and filing numbers
- Active voice even when discussing passive regulatory processes

## Vocabulary Prohibitions
- Never uses vague legal hedging: "may or may not", "could potentially"
- Avoids sensationalism: no "bombshell", "seismic shift", "groundbreaking"
- Does not editorialise about regulatory intent — reports what the regulation says and does

## Sentence Rhythm
- Consistently clear and direct — shorter average sentence length than Steve
- Uses numbered lists and bullet points for actionable items
- Topic sentences that tell you exactly what the paragraph will cover
- Minimal use of subordinate clauses — one idea per sentence when explaining complex regulations

## Perspective & Stance
- Neutral on regulatory philosophy — does not argue for or against regulation
- Practical above all — "here's what this means for you" is her north star
- Sympathetic to the compliance burden on smaller organisations
- Believes good compliance is a competitive advantage, not just a cost

## Opening Style
- Opens with what changed and why it matters — "On February 3, the FTC finalised new rules that will require..."
- Immediate practical relevance — no throat-clearing
- Often opens with a date and a specific regulatory action

## Closing Style
- Closes with a timeline and action items
- "What to do now" section with concrete steps
- Provides next dates to watch

## File 2: voice-models/authors/sarah/style-regulatory.md

# Sarah — Style Modifier: Regulatory Analysis

## How the Voice Shifts
In regulatory analysis mode, Sarah becomes even more precise and structured. Every claim references a specific section, date, or filing. The writing is denser but never unclear — she achieves density through specificity, not complexity.

## Structure
- Opens with what happened (the regulatory action)
- Context section: why this matters, what it changes
- Analysis section: detailed breakdown of key provisions
- Impact section: what practitioners need to do differently
- Timeline: key dates and deadlines
- Action items: numbered, specific, actionable

## Tone Adjustments
- More formal — fewer contractions, more precise language
- Dense with references and citations
- Explanatory without being condescending
- Urgency communicated through specificity, not exclamation marks

## Length & Pacing
- 600-1,000 words
- Structured for scanning — readers should be able to jump to the section they need
- Heavy use of headers, bullets, and bold text for key dates/amounts

## Output
After creating all 2 files, confirm completion.
```

### Wait for Completion

Once all four subagents return, proceed to Step 4. If any task reports errors, create those files directly before continuing.

## Step 4: Create Initial Beats (Optional)

Ask the user if they would like to create any research beats now. Use AskUserQuestion:

**Question**: "Would you like to create some research beats now? Beats define the topics your engine will monitor for signals."
- Options:
  - "Yes, let me add some beats" — description: "Define one or more beats by short description"
  - "No, I'll add beats later" — description: "Skip for now — use /add-beat later to add beats"

If the user chooses to add beats, enter a loop:

**For each beat**, use AskUserQuestion to gather:

**Question 1 — Beat description**: "Describe this beat in one line (e.g., 'Track AI regulation and policy developments across major markets')."
- Options:
  - "Enter description" — description: "Type a one-line description of what this beat covers"

**Question 2 — Frequency**: "How often should this beat be checked?"
- Options:
  - "every-run — Check on every research cycle (Recommended)" — description: "Most beats should run every cycle"
  - "daily — Check once per day" — description: "For lower-priority or slow-moving topics"
  - "weekly — Check once per week" — description: "For background monitoring"

After capturing each beat, derive a beat name and slug from the description:
- **Name**: Extract the core topic from the description (e.g., "AI Regulation & Policy" from "Track AI regulation and policy developments across major markets")
- **Slug**: Lowercase, hyphenated version of the name (e.g., `ai-regulation-policy`)

Write a beat file to `beats/{slug}.md`:

```markdown
---
name: {Beat Name}
slug: {slug}
active: true
schedule: {every-run | daily | weekly}
description: {The user's one-line description}
tags: []
sources: []
---

## Scope
{The user's one-line description}

## Research Methodology
When scanning this beat, research agents should:
- Use web search to find recent developments matching this beat's scope
- Check sources in tier order (highest credibility first) when sources are added
- Flag new material that differs from previously indexed content
- Look for connections to signals from other beats

## Notes
This beat was created during project initialisation with a quick description. To add specific sources, credibility tiers, and detailed methodology, run `/add-beat` to create a more detailed beat, or edit this file directly.
```

After writing each beat file, ask whether to add another:

**Question**: "Add another beat?"
- Options:
  - "Yes, add another beat" — description: "Describe another topic to monitor"
  - "No, I'm done adding beats" — description: "Continue with project setup"

Continue the loop until the user indicates they're done.

## Step 5: Git Commit

Stage all new files and commit with message:
```
Initialise Newsroom project scaffold

- Create full directory structure for editorial pipeline
- Generate PUBLICATION.md with editorial mission and cycle instructions
- Generate config.md with research settings and quality thresholds
- Generate brand guidelines and example author voice models (Steve, Sarah)
- Generate editorial calendar template and knowledge base index
- Create {N} initial research beats (if any were added)
```

If no beats were created, omit the beats line from the commit message.

## Step 6: Next Steps

After the commit, inform the user:

> **Sample voice models created.** Two example authors — Steve and Sarah — have been added to `voice-models/authors/`. These are generic templates. You should review and modify them to match your publication's tone of voice before running the editorial pipeline. Use `/add-author` to create new authors or edit the files in `voice-models/authors/` directly.
>
> **Next steps:**
> 1. Run `/add-beat` to define the topics and sources your engine will monitor
> 2. Run `/add-author` to create author voices that match your publication
> 3. Run `/research` to scan your beats for signals and start the editorial pipeline

</process>
