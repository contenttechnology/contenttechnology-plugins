---
name: validate
description: Validate pitch memos by dispatching subagents to find supporting evidence, counter-evidence, scope assessment, and audience resonance.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, WebFetch, WebSearch
---

<objective>
Run validation on all pending pitch memos in `pipeline/010_pitches/`. For each pitch, dispatch parallel validation subagents that independently seek supporting evidence, counter-evidence, scope assessment, and audience resonance. Subagents write detailed reports to files and return only a compact summary to the parent context. Synthesise results and update the pitch memo with a validation report. This is the adversarial layer that prevents weak angles from reaching production.
</objective>

<process>

## Step 1: Load Pending Pitch Memos

Use Glob to find all pitch memos: `pipeline/010_pitches/*.md`

Read each pitch memo. Filter for those with `status: pending` in frontmatter — these have not yet been validated. Skip any with `status: validated`, `status: approved`, or `status: rejected`.

If no pending pitch memos are found, report "No pending pitch memos to validate. Run /angle first." and exit.

Read `config.md` for quality thresholds (min sources for angle, max revision cycles).

For each pending pitch, create a validation output directory using Bash:
```
mkdir -p pipeline/validation/{pitch-id}
```

## Step 2: Validate Each Pitch (Sequential)

**Critical: Process one pitch at a time.** For each pending pitch, complete the FULL cycle — dispatch 4 agents, wait for results, synthesise, update the pitch memo — before moving on to the next pitch. Do NOT launch agents for multiple pitches at once. This prevents context window exhaustion.

For each pending pitch memo, dispatch **four parallel validation subagents** using the Task tool (subagent_type: "general-purpose", model: "sonnet").

**Critical: File-based output pattern** — Each subagent MUST write its full detailed report to a file and return ONLY a compact summary line to the parent. This keeps the parent context lean. The detailed reports are available in `pipeline/validation/{pitch-id}/` for deep dives.

### Subagent 1: Supporting Evidence

```
You are a validation agent tasked with finding SUPPORTING evidence for an editorial thesis.

## Thesis to Validate
{Paste the thesis from the pitch memo}

## Known Supporting Evidence
{Paste the supporting evidence section from the pitch memo}

## Evidence Gaps
{Paste the gaps section from the source map}

## Your Task
Search for additional data, reports, or commentary that SUPPORTS this thesis. You are looking for:
1. Additional data points that strengthen the argument
2. Expert commentary or analysis that reaches similar conclusions
3. Historical precedent that supports the predicted outcome
4. Quantitative data that backs qualitative claims

Use WebSearch and WebFetch to find new evidence. Search for:
- The specific companies, regulations, or trends mentioned
- Industry data sources and reports
- Recent news coverage of the topic
- Expert analysis and commentary

**Search budget**: Make 3-5 WebSearch attempts max. If searches return no relevant results, stop searching and report what you found (even if nothing). Finding zero new sources is a valid and informative result — do not keep searching indefinitely.

## Output Instructions
Write your FULL detailed report to the file: pipeline/validation/{pitch-id}/supporting-evidence.md

The file should contain:

# Supporting Evidence Report — {pitch-id}

strength: {strong | moderate | weak}
new_sources_found: {count}

## New Evidence Found
{For each piece of new evidence:}
- **Source**: {URL or description}
  **Tier**: {1-4}
  **Finding**: {what this evidence shows}
  **Relevance**: {how it strengthens the thesis}

## Assessment
{2-3 sentence assessment of how well the thesis is supported by available evidence}

## Gaps Remaining
{What evidence would further strengthen this but wasn't found}

---

After writing the file, return ONLY this single summary line as your final response (nothing else):

SUPPORTING: strength={strong|moderate|weak} new_sources={count} — {one sentence assessment}
```

### Subagent 2: Counter-Evidence

```
You are a validation agent tasked with finding COUNTER-EVIDENCE against an editorial thesis. Your job is adversarial — you are actively trying to disprove or weaken this thesis.

## Thesis to Challenge
{Paste the thesis from the pitch memo}

## Your Task
Search for data, reports, expert opinions, or arguments that CONTRADICT or WEAKEN this thesis. You are looking for:
1. Data that directly contradicts the claims
2. Alternative explanations for the same observations
3. Expert commentary that reaches opposite conclusions
4. Historical cases where similar predictions were wrong
5. Methodological problems with the underlying data

Use WebSearch and WebFetch to find counter-evidence. Search for:
- Counter-arguments to the specific thesis
- Alternative interpretations of the same data
- Critics of the sources or methodology
- Competing narratives about the same topic

Be thorough and genuinely adversarial. Finding strong counter-evidence is VALUABLE — it either kills a weak angle (saving production effort) or adds nuance that improves the final piece.

**Search budget**: Make 3-5 WebSearch attempts max. If searches return no relevant counter-evidence, that itself is a finding — report threat_level "minimal" and move on. Do not keep searching indefinitely.

## Output Instructions
Write your FULL detailed report to the file: pipeline/validation/{pitch-id}/counter-evidence.md

The file should contain:

# Counter-Evidence Report — {pitch-id}

threat_level: {fatal | significant | manageable | minimal}
counter_sources_found: {count}
recommendation: {PROCEED | REFINE | KILL}

## Counter-Evidence Found
{For each piece of counter-evidence:}
- **Source**: {URL or description}
  **Tier**: {1-4}
  **Finding**: {what this evidence shows}
  **Threat to thesis**: {how it weakens or contradicts the thesis}
  **Addressable**: {yes/no — can the piece acknowledge and address this?}

## Assessment
{2-3 sentence assessment of how the counter-evidence affects the thesis}

## Recommendation
- PROCEED: Counter-evidence is manageable and can be addressed in the piece
- REFINE: Thesis needs adjustment to account for counter-evidence (suggest refinement)
- KILL: Counter-evidence is too strong — thesis is fundamentally flawed

{If REFINE, include a suggested refined thesis}

---

After writing the file, return ONLY the following as your final response (nothing else):

COUNTER: threat={fatal|significant|manageable|minimal} sources={count} recommendation={PROCEED|REFINE|KILL} — {one sentence assessment}

If your recommendation is REFINE, add a second line:
REFINED_THESIS: {the suggested refined thesis in a single sentence}

If your recommendation is KILL, add a second line:
KILL_REASON: {one sentence reason}
```

### Subagent 3: Scope Validation

```
You are a validation agent assessing the SCOPE of an editorial angle — whether it's too broad, too narrow, appropriately national/regional, and correctly targeted.

## Thesis
{Paste the thesis}

## Target Audience
{Paste from recommended treatment section}

## Your Task
Assess whether this angle is scoped correctly:
1. Is this a national trend or regional phenomenon being presented as national?
2. Is it too broad (trying to cover too much) or too narrow (insufficient audience)?
3. Does the scope match the target audience?
4. Is the content type appropriate for the scope?
5. Are there sub-segments of the audience this would not apply to?

Use WebSearch to check geographic scope, market size, and applicability.

**Search budget**: Make 2-3 WebSearch attempts max. If you can assess scope from the thesis and existing evidence alone, you may skip searching entirely. Do not keep searching indefinitely.

## Output Instructions
Write your FULL detailed report to the file: pipeline/validation/{pitch-id}/scope.md

The file should contain:

# Scope Report — {pitch-id}

scope_assessment: {appropriate | too-broad | too-narrow | geographic-mismatch}
audience_fit: {strong | adequate | weak}

## Geographic Scope
{Is this national, regional, or local? Evidence for the assessment.}

## Audience Fit
{Does this match the target audience? Who would care and who wouldn't?}

## Scope Recommendations
{If adjustment needed, suggest how to refine the scope}

## Content Type Fit
{Is the recommended content type right for this scope and depth?}

---

After writing the file, return ONLY this single summary line as your final response (nothing else):

SCOPE: assessment={appropriate|too-broad|too-narrow|geographic-mismatch} audience_fit={strong|adequate|weak} — {one sentence assessment}
```

### Subagent 4: Audience Resonance

```
You are a validation agent assessing AUDIENCE RESONANCE — whether the target audience is already aware of, discussing, or concerned about this topic.

## Thesis
{Paste the thesis}

## Target Audience
{Paste from recommended treatment section}

## Your Task
Determine how this thesis would land with the target audience:
1. Are industry professionals already discussing this topic?
2. What's the current sentiment — is the audience ahead of this angle or would it be news?
3. Are there industry forums, social media threads, or community discussions about this?
4. Would this be seen as timely insight or old news?

Use WebSearch to check industry forums, social media, trade publication comment sections, and community discussions.

**Search budget**: Make 3-5 WebSearch attempts max. If the topic is niche and searches return no relevant discussion, report awareness as "none" and move on. Absence of discussion is itself a valid data point — do not keep searching indefinitely.

## Output Instructions
Write your FULL detailed report to the file: pipeline/validation/{pitch-id}/resonance.md

The file should contain:

# Audience Resonance Report — {pitch-id}

audience_awareness: {high | moderate | low | none}
predicted_reception: {high-value | useful | marginal | redundant}

## Current Discussion
{What the audience is already saying about this topic, if anything}

## Sentiment
{How the audience currently feels about this topic — is there an appetite for analysis?}

## Timeliness
{Is this ahead of the conversation, in the middle of it, or behind it?}

## Reception Prediction
{How would the target audience likely receive this piece?}

---

After writing the file, return ONLY this single summary line as your final response (nothing else):

RESONANCE: awareness={high|moderate|low|none} reception={high-value|useful|marginal|redundant} — {one sentence assessment}
```

Launch all four subagents in parallel for the current pitch. Wait for all four to return before proceeding.

### Synthesise and Update (Same Pitch)

Once all four subagent summaries return for this pitch, parse the summary lines to extract the key metrics. Do NOT read the detailed report files — the summary lines contain everything needed for synthesis decisions.

**Synthesis Logic:**

1. **If counter-evidence threat_level is "fatal"**: Mark the pitch as `status: rejected` using the KILL_REASON from the summary.

2. **If scope_assessment is "geographic-mismatch" AND audience_fit is "weak"**: Reject the pitch.

3. **If supporting evidence strength is "weak" AND counter-evidence is "significant"**: The thesis doesn't have enough support. Reject.

4. **If audience_awareness is "high" AND predicted_reception is "redundant"**: The audience has already seen this take. Reject.

5. **Otherwise**: The angle survives validation.

**Thesis Refinement:** If counter-evidence recommendation is REFINE, use the REFINED_THESIS from the counter-evidence summary line. Do not read the detail file.

**Update the pitch memo immediately** before moving to the next pitch:

For surviving angles, update the frontmatter:
```yaml
status: validated
validated_date: {YYYY-MM-DD}
```

Append to the pitch memo body:

```markdown
## Validation Report
_Validated: {date}_

### Supporting Evidence Assessment
- **Strength**: {strong/moderate/weak}
- **New sources found**: {count}
- [Full report](../validation/{pitch-id}/supporting-evidence.md)

### Counter-Evidence Assessment
- **Threat level**: {fatal/significant/manageable/minimal}
- **Recommendation**: {PROCEED/REFINE/KILL}
- [Full report](../validation/{pitch-id}/counter-evidence.md)

### Scope Assessment
- **Scope**: {appropriate/too-broad/too-narrow}
- **Audience fit**: {strong/adequate/weak}
- [Full report](../validation/{pitch-id}/scope.md)

### Audience Resonance
- **Audience awareness**: {high/moderate/low/none}
- **Predicted reception**: {high-value/useful/marginal/redundant}
- [Full report](../validation/{pitch-id}/resonance.md)

### Validation Verdict
{2-3 sentence synthesis: why this angle should proceed, with what caveats}

### Refined Thesis
{If thesis was refined based on counter-evidence, state the updated thesis here. Otherwise: "Original thesis stands."}
```

For killed angles, update the frontmatter to `status: rejected` and move the file to `pipeline/rejected/`:
```yaml
status: rejected
rejected_date: {YYYY-MM-DD}
rejected_reason: {brief reason}
```

Use Bash `mv` to move rejected pitch files from `pipeline/010_pitches/` to `pipeline/rejected/`.

**Then move on to the next pending pitch and repeat Step 2.**

## Step 3: Summary Output

After all pitches have been processed:

```markdown
## Validation Summary — {date}

### Validated: {count}
{For each validated pitch:}
1. **{headline}** ({pitch-id})
   - Supporting evidence: {strength}
   - Counter-evidence: {threat level}
   - Audience resonance: {predicted reception}
   - Verdict: Proceed {with/without caveats}

### Rejected: {count}
{For each rejected pitch:}
1. **{headline}** ({pitch-id})
   - Reason: {why killed}

### Deferred: {count}
{Pitches that need more evidence before a decision}

Detailed reports: pipeline/validation/

### Next Step
Run `editorial` to evaluate validated pitches, assign authors, and produce production briefs.
```

## Step 4: Git Commit

Stage all modified pitch memos, validation report files, and any moved files:

```
Validate pitches: {N} validated, {M} rejected

Validated:
- {pitch-1 headline}
Rejected:
- {pitch-2 headline}: {reason}
```

## Error Handling

- If a validation subagent fails or returns unparseable output, note the failure in the validation report and proceed with available results. A pitch can be validated with 3 of 4 reports.
- If WebSearch/WebFetch fails consistently, note in the report that external validation was limited and flag for manual review.
- Never auto-approve a pitch that lacks counter-evidence search — the adversarial check is mandatory. If the counter-evidence subagent fails, flag the pitch for manual validation.

</process>
