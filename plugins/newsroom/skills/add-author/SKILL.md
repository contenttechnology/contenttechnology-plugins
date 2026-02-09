---
name: add-author
description: Interactive session to create a new author voice model with baseline personality and style modifiers.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, AskUserQuestion, Glob
---

<objective>
Walk the user through defining a new author voice model. Gather personality traits, writing style, vocabulary preferences, and content type variations through interactive questions. Produce a complete voice model with baseline and style modifier files.
</objective>

<process>

## Step 1: Get Author Name

Use AskUserQuestion to ask: "What is this author's name?" — This should be a first name that will be used as the directory name and referenced in editorial assignments. Provide a free-text input (use options like "Enter a name" with description prompting them to type a name).

Convert the name to lowercase for the directory slug. For example, "Marcus" becomes `voice-models/authors/marcus/`.

Check that `voice-models/authors/{name}/` does not already exist using Glob. If it does, inform the user and ask if they want to overwrite or choose a different name.

## Step 2: Gather Core Personality

Use AskUserQuestion to ask these questions (you can batch 2-3 at a time to reduce back-and-forth):

**Question 1 — Personality**: "Describe this author's personality in your own words. What kind of person are they? What's their background and perspective?"
- Provide 3-4 archetype options as starting points:
  - "Industry veteran — decades of experience, seen it all, data-driven"
  - "Rising analyst — sharp, modern, tech-forward perspective"
  - "Practitioner — runs operations, speaks from direct experience"
  - Other (let them describe freely)

**Question 2 — Tone**: "What is this author's default tone?"
- Options: "Direct and authoritative", "Conversational and approachable", "Analytical and measured", "Provocative and opinionated"

## Step 3: Gather Writing Style Details

**Question 3 — Openings**: "How does this author open their pieces?"
- Options: "With a specific data point or fact", "With a provocative question or claim", "With a concrete anecdote or scene", "With a direct statement of what changed"

**Question 4 — Closings**: "How does this author close their pieces?"
- Options: "With actionable implications — what to do next", "With a forward-looking question or prediction", "With a callback to the opening that reframes it", "With a crisp summary and takeaway"

## Step 4: Vocabulary and Language

**Question 5 — Vocabulary style**: "How does this author use language?"
- Options: "Precise technical terminology, explained when needed", "Plain language — avoids jargon wherever possible", "Industry insider language — assumes reader fluency", "Academic rigour — careful qualifications and citations"

**Question 6 — Language to avoid**: "What language or patterns should this author NEVER use?"
- Provide common options to select from (multiSelect: true):
  - "Corporate buzzwords (leverage, synergy, etc.)"
  - "Hedging language (it could be argued, some might say)"
  - "AI-sounding phrases (in today's landscape, let's dive in)"
  - "Exclamation marks and superlatives"

## Step 5: Writing Examples (Optional)

Ask: "Do you have 2-3 examples of writing that sounds like this author? You can paste excerpts or describe the style you're aiming for."
- Options: "Yes, I'll paste examples", "No, the description above is sufficient"

If they choose to provide examples, prompt them to paste text. Incorporate these as example passages in the baseline file.

## Step 6: Content Types / Styles

Use AskUserQuestion: "What content types will this author write? Select all that apply."
- multiSelect: true
- Options:
  - "Deep Analysis — long-form, data-heavy synthesis"
  - "Commentary — opinionated, shorter takes"
  - "Regulatory/Policy — formal analysis of regulatory changes"
  - "Humorous/Light — witty, lighter treatment of serious topics"

## Step 7: Style Modifier Details

For each content type selected in Step 6, ask a follow-up question:

"When {author name} writes {content type}, how does their voice shift from the baseline?"
- Provide relevant options for each type. For example:
  - Deep Analysis: "More measured and methodical" / "Same energy, just longer and more detailed" / "More formal and academic"
  - Commentary: "Sharper and more opinionated" / "More conversational, like talking to a friend" / "More provocative, willing to be contrarian"
  - Regulatory: "Much more formal and precise" / "Stays accessible but adds more structure" / "Expert mode — assumes reader has policy background"
  - Humorous: "Self-deprecating and observational" / "Dry wit and understatement" / "Playful with industry absurdities"

## Step 8: Write Baseline File

Create `voice-models/authors/{name}/baseline.md` using all gathered information. Structure it as:

```markdown
# {Name} — Author Baseline

## Core Personality
[2-3 paragraphs synthesising personality, background, and perspective from Step 2]

## Vocabulary Preferences
[From Step 4, structured as bullet points]

## Vocabulary Prohibitions
[From Step 4 language avoidance, as bullet points]

## Sentence Rhythm
[Inferred from tone and personality — describe structural tendencies]

## Perspective & Stance
[From personality and tone — what they believe, how they view the industry]

## Opening Style
[From Step 3]

## Closing Style
[From Step 3]

## Example Writing
[If provided in Step 5, include 2-3 representative passages]
```

## Step 9: Write Style Modifier Files

For each content type selected in Step 6, create `voice-models/authors/{name}/style-{type}.md`:

```markdown
# {Name} — Style Modifier: {Content Type}

## How the Voice Shifts
[From Step 7 — how this differs from baseline]

## Structure
[Recommended structure for this content type]

## Tone Adjustments
[Specific tone changes from baseline]

## Length & Pacing
[Appropriate length range and pacing notes for this type]
```

Use these slugs for style files:
- Deep Analysis → `style-deep-analysis.md`
- Commentary → `style-commentary.md`
- Regulatory/Policy → `style-regulatory.md`
- Humorous/Light → `style-humorous.md`

## Step 10: Validate Against Brand Guidelines

Read `voice-models/brand-guidelines.md` and check that the new author's voice model doesn't conflict with brand constraints. Specifically verify:
- No prohibited language appears in the author's vocabulary preferences
- The author's tone falls within brand voice constraints
- Editorial ethics are compatible

If conflicts are found, flag them to the user and adjust the voice model accordingly.

## Step 11: Git Commit

Stage all new files in `voice-models/authors/{name}/` and commit with message:
```
Add author voice model: {Name}

- Baseline personality and writing style
- Style modifiers: {list of styles created}
```

Inform the user that the author has been created and is ready for assignment in editorial briefs.

</process>
