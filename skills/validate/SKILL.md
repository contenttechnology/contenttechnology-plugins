---
name: validate
description: Validate pitch memos by dispatching subagents to find supporting evidence, counter-evidence, scope assessment, and audience resonance.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Task, Glob, Grep, WebFetch, WebSearch
---

<objective>
Run validation on all pending pitch memos in `pipeline/pitches/`. For each pitch, dispatch parallel validation subagents that independently seek supporting evidence, counter-evidence, scope assessment, and audience resonance. Synthesise results and update the pitch memo with a validation report. This is the adversarial layer that prevents weak angles from reaching production.
</objective>

<process>

## Step 1: Load Pending Pitch Memos

Use Glob to find all pitch memos: `pipeline/pitches/*.md`

Read each pitch memo. Filter for those with `status: pending` in frontmatter — these have not yet been validated. Skip any with `status: validated`, `status: approved`, or `status: rejected`.

If no pending pitch memos are found, report "No pending pitch memos to validate. Run /newsroom:angle first." and exit.

Read `config.md` for quality thresholds (min sources for angle, max revision cycles).

## Step 2: Dispatch Validation Subagents

For each pending pitch memo, dispatch **four parallel validation subagents** using the Task tool (subagent_type: "general-purpose", model: "sonnet").

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

## Output Format
Return your findings as:

SUPPORTING_EVIDENCE_REPORT
strength: strong | moderate | weak
new_sources_found: {count}

### New Evidence Found
{For each piece of new evidence:}
- **Source**: {URL or description}
  **Tier**: {1-4}
  **Finding**: {what this evidence shows}
  **Relevance**: {how it strengthens the thesis}

### Assessment
{2-3 sentence assessment of how well the thesis is supported by available evidence}

### Gaps Remaining
{What evidence would further strengthen this but wasn't found}
END_REPORT
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

## Output Format
Return your findings as:

COUNTER_EVIDENCE_REPORT
threat_level: fatal | significant | manageable | minimal
counter_sources_found: {count}

### Counter-Evidence Found
{For each piece of counter-evidence:}
- **Source**: {URL or description}
  **Tier**: {1-4}
  **Finding**: {what this evidence shows}
  **Threat to thesis**: {how it weakens or contradicts the thesis}
  **Addressable**: {yes/no — can the piece acknowledge and address this?}

### Assessment
{2-3 sentence assessment of how the counter-evidence affects the thesis}

### Recommendation
{One of:}
- PROCEED: Counter-evidence is manageable and can be addressed in the piece
- REFINE: Thesis needs adjustment to account for counter-evidence (suggest refinement)
- KILL: Counter-evidence is too strong — thesis is fundamentally flawed
END_REPORT
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

## Output Format
Return your findings as:

SCOPE_REPORT
scope_assessment: appropriate | too-broad | too-narrow | geographic-mismatch
audience_fit: strong | adequate | weak

### Geographic Scope
{Is this national, regional, or local? Evidence for the assessment.}

### Audience Fit
{Does this match the target audience? Who would care and who wouldn't?}

### Scope Recommendations
{If adjustment needed, suggest how to refine the scope}

### Content Type Fit
{Is the recommended content type right for this scope and depth?}
END_REPORT
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

## Output Format
Return your findings as:

RESONANCE_REPORT
audience_awareness: high | moderate | low | none
predicted_reception: high-value | useful | marginal | redundant

### Current Discussion
{What the audience is already saying about this topic, if anything}

### Sentiment
{How the audience currently feels about this topic — is there an appetite for analysis?}

### Timeliness
{Is this ahead of the conversation, in the middle of it, or behind it?}

### Reception Prediction
{How would the target audience likely receive this piece?}
END_REPORT
```

Launch all four subagents in parallel for each pitch memo. If there are multiple pitch memos, process them sequentially (to manage cost) or in parallel if step budget allows.

## Step 3: Synthesise Validation Results

For each pitch memo, once all four subagent reports return:

### Synthesis Logic

1. **If counter-evidence threat_level is "fatal"**: Mark the pitch as `status: rejected` with the reason.

2. **If scope_assessment is "geographic-mismatch" AND audience_fit is "weak"**: Consider killing or flagging for significant revision.

3. **If supporting evidence strength is "weak" AND counter-evidence is "significant"**: The thesis doesn't have enough support. Kill or refine.

4. **If audience_awareness is "high" AND predicted_reception is "redundant"**: The audience has already seen this take. Kill unless our evidence is substantially stronger.

5. **Otherwise**: The angle survives validation. Compile the results.

### Thesis Refinement

If counter-evidence suggests refinement (recommendation: REFINE), update the thesis in the pitch memo to account for the nuance. Strong counter-evidence that adds complexity often makes for a better piece.

## Step 4: Update Pitch Memos

Edit each pitch memo to add a validation section and update the status:

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
{Key new evidence bullets}

### Counter-Evidence Assessment
- **Threat level**: {fatal/significant/manageable/minimal}
{Key counter-evidence bullets}
- **Addressability**: {How the piece can address counter-arguments}

### Scope Assessment
- **Scope**: {appropriate/too-broad/too-narrow}
- **Audience fit**: {strong/adequate/weak}
{Key scope notes}

### Audience Resonance
- **Audience awareness**: {high/moderate/low/none}
- **Predicted reception**: {high-value/useful/marginal/redundant}
{Key resonance notes}

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

Use Bash `mv` to move rejected pitch files from `pipeline/pitches/` to `pipeline/rejected/`.

## Step 5: Summary Output

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
```

## Step 6: Git Commit

Stage all modified pitch memos and any moved files:

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
