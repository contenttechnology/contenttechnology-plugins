# Newsroom

```
█▀▀▄ █▀▀ █░░░█ █▀▀ █▀▀█ █▀▀█ █▀▀█ █▀▄▀█
█░░█ █▀▀ █▄█▄█ ▀▀█ █▄▄▀ █░░█ █░░█ █░▀░█
▀░░▀ ▀▀▀ ░▀░▀░ ▀▀▀ ▀░▀▀ ▀▀▀▀ ▀▀▀▀ ▀░░░▀
```

**Editorial intelligence on autopilot.**

Newsroom is an autonomous editorial pipeline built as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin. It researches, writes, and quality-checks articles — then hands polished drafts to a human for final review. No human touches the writing until it's ready.

---

## How It Works

Newsroom runs a six-stage pipeline. Each stage is a Claude Code skill that can run independently or as part of a fully automated cycle.

```
Research  →  Angle  →  Validate  →  Editorial  →  Produce  →  Quality  →  Human Review
```

**1. Research** — Scans your configured beats (topic areas) for new signals from web sources, filings, feeds, and forums. Only processes genuinely new content via change detection.

**2. Angle** — Reads the knowledge base and identifies convergent patterns across signals. Constructs falsifiable theses, not topic summaries. Single-source angles are killed automatically.

**3. Validate** — Stress-tests each angle with four parallel subagents: supporting evidence, counter-evidence (adversarial), scope validation, and audience resonance. Weak angles are killed or refined.

**4. Editorial** — Acts as editorial director. Evaluates surviving angles against value threshold, source strength, editorial mix, campaign fit, and redundancy. Assigns an author and writing style to approved angles.

**5. Produce** — Writes drafts using a three-layer voice model: brand guidelines, author personality, and style modifier. Each article sounds like it was written by a specific person, not a machine.

**6. Quality** — Assesses drafts against seven criteria: insight density, source fidelity, thesis delivery, AI-tell scan, voice match, novelty, and readability. Drafts get up to two revision cycles before being killed.

Articles that pass land in `pipeline/review/` for a human to approve, revise, or kill.

---

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured

### Install the Plugin

```bash
claude plugin add newsroom
```

### Initialise a Project

Create a new directory for your publication, then run the init skill:

```bash
mkdir my-publication && cd my-publication
git init
claude
```

Inside Claude Code, run:

```
/init
```

The init skill walks you through an interactive setup:
1. Define your editorial mission — industry, audience, goals, publication name
2. Generates your `PUBLICATION.md` (editorial brain), `config.md` (settings), and brand guidelines
3. Creates two example authors with full voice models
4. Builds the complete folder structure
5. Optionally creates your first research beats
6. Commits everything to git

You now have a working newsroom.

### Add Your First Beat

Beats are the topics your newsroom monitors. Each beat has its own sources and schedule.

```
/add-beat
```

You'll define the beat's scope, add sources (URLs, feeds, databases), set check frequency, and assign credibility tiers.

### Add an Author

Each author has a distinct voice — personality, vocabulary, rhythm, and style variations.

```
/add-author
```

The skill interviews you about the author's personality, then generates a baseline voice model and style modifiers (deep-analysis, commentary, regulatory, humorous).

### Run the Pipeline

Run the full autonomous cycle:

```
/run
```

This executes research through quality gate with zero human interaction and outputs articles ready for review. You can also run individual stages:

```
/research
/angle
/validate
/editorial
/produce
/quality
```

### Review Drafts

```
/review
```

An interactive session where you read quality-approved drafts and decide: **approve** (publish), **revise** (send back with feedback), or **kill** (reject with reasoning). Every decision is logged and committed to git.

---

## All Skills

### Setup (run as needed)

| Skill | What it does |
|---|---|
| `init` | Create a new newsroom project — folder structure, editorial mission, config, example authors, and first beats |
| `add-author` | Interactively create a new author voice model with baseline personality and style modifiers |
| `add-beat` | Define a new research beat with sources, schedule, scope, and methodology |
| `add-campaign` | Launch an editorial campaign — seasonal, event-driven, thematic, or rapid response |

### Pipeline (run autonomously or manually)

| Skill | What it does |
|---|---|
| `research` | Scan all active beats for new signals. Dispatches parallel subagents per beat, produces signal reports, updates the knowledge base |
| `angle` | Scan the knowledge base for convergent patterns. Applies quality filters (So What?, Synthesis, Novelty, Durability). Writes pitch memos |
| `validate` | Validate pitch memos with four parallel subagents: supporting evidence, counter-evidence, scope, and audience resonance |
| `editorial` | Evaluate validated pitches. Make approve/kill/hold decisions. Assign authors and styles. Write production briefs |
| `produce` | Write article drafts from production briefs using the three-layer voice model (brand + author + style) |
| `quality` | Assess drafts against seven criteria. Pass, revise (up to 2 cycles), or kill |
| `run` | Execute the full pipeline end-to-end with zero human interaction. Designed for cron |

### Human Interaction

| Skill | What it does |
|---|---|
| `review` | Interactive review session — read drafts, approve, revise with feedback, or kill with reasoning |
| `rush` | Rapid response for breaking news — compressed pipeline, abbreviated validation, draft ready in a single session |

---

## Project Structure

After init, your project looks like this:

```
my-publication/
├── PUBLICATION.md                       # Editorial mission and cycle instructions
├── config.md                       # Research modes, budgets, quality thresholds
├── editorial-calendar.md           # Publication schedule and content mix
├── voice-models/
│   ├── brand-guidelines.md         # Global voice constraints
│   └── authors/
│       └── {name}/
│           ├── baseline.md         # Author personality and voice
│           └── style-*.md          # Style modifiers per content type
├── knowledge-base/
│   ├── signals/                    # Signal reports from research
│   ├── sources/                    # Drop files here — auto-indexed as Tier 1
│   ├── index.json                  # Metadata index (processed URLs, signal tags)
│   └── archive/                    # Decayed signals
├── beats/                          # Beat configs (scope, sources, schedule)
├── campaigns/
│   ├── active/                     # Current campaign briefs
│   └── archive/                    # Completed campaigns
├── pipeline/
│   ├── pitches/                    # Angle pitch memos
│   ├── approved/                   # Production briefs
│   ├── drafts/                     # Drafts in progress
│   ├── review/                     # Ready for human review
│   ├── published/                  # Approved final articles
│   └── rejected/                   # Killed with reasoning
└── metrics/                        # Cycle logs and health metrics
```

The filesystem is the shared state. Every signal, pitch, brief, draft, and editorial decision is a file in the repo — fully version-controlled and inspectable.

---

## Key Concepts

### Signals

Raw intelligence extracted from research. Stored as markdown with YAML frontmatter tracking source tier, confidence, angle potential, and cross-references to related signals. Signals are never deleted — they compound over time as new connections emerge.

### Three-Layer Voice Model

Every article is produced through three composable layers:

1. **Brand Guidelines** — Hard constraints: prohibited language, audience assumptions, editorial ethics
2. **Author Baseline** — Core personality: vocabulary, sentence rhythm, perspective, opening/closing style
3. **Style Modifier** — Content-type adjustments: deep-analysis is measured and data-led; commentary is sharp and opinionated

Two authors writing about the same topic produce noticeably different pieces.

### Quality Gate (7 Criteria)

| Criterion | What it checks |
|---|---|
| Insight density | Every section adds new information — no filler |
| Source fidelity | All claims traceable to sources |
| Thesis delivery | Piece delivers its promised thesis without drift |
| AI-tell scan | No hedging, false balance, empty transitions, or formulaic structure |
| Voice match | Reads authentically as the assigned author |
| Novelty | Reader learns something they couldn't easily find elsewhere |
| Readability | A busy professional would read past the first 200 words |

### Source Tiers

| Tier | Examples | Usage |
|---|---|---|
| 1 (Gold) | SEC filings, earnings transcripts, government data, human-submitted sources | Can anchor a thesis |
| 2 (Strong) | Industry publications, market data providers | Strong supporting evidence |
| 3 (Context) | News articles, analyst commentary | Colour and context only |
| 4 (Signal) | Social media, forums, vendor marketing | Sentiment indicators — must be validated |

---

## Design Principles

- **Synthesis over summarisation** — Every piece combines multiple sources. Single-source articles are killed.
- **Angle-first** — Content starts with a falsifiable thesis, not a topic. _"Remote work policies are hollowing out mid-tier commercial real estate"_ is an angle. _"Office vacancy rates in 2024"_ is not.
- **Ruthless quality gates** — Most signals are unusable. Most angles are killed. This is by design.
- **Human time for judgment, not labour** — Reviewers assess quality and strategic fit. They never fix grammar or restructure articles.
- **Compounding knowledge** — The knowledge base gets smarter over time. Old signals resurface when new connections emerge.
- **Git-native** — Every editorial decision is a commit. The full chain from signal to publication is reconstructable.

---

## Contributing a Source

Drop any file or note into `knowledge-base/sources/` at any time. It will be automatically indexed as Tier 1 (highest credibility) and prioritised by the angle agent on the next run. Useful for internal data, conference notes, or articles your team has identified.

---

## License

Proprietary. All rights reserved.
