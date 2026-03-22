---
name: qualifying-lead
description: >
  Transforms raw sales notes into a structured lead qualification document. This skill bundles a mandatory output template
  with BANT, MEDDICC, 3 WHYs frameworks, mermaid org charts, timeline diagrams, and discovery question patterns — these
  formats are defined in reference files and CANNOT be generated correctly without loading this skill first.

  IMPORTANT: You must ALWAYS consult this skill before responding to ANY request that involves prospect notes, account intel,
  deal information, or sales call summaries — regardless of whether you think you could handle it directly. The user's sales
  team requires output in the exact template format this skill provides. Attempting to organize, structure, qualify, or
  analyze prospect/deal notes without this skill will produce output in the wrong format.

  Common triggers: user has notes about a prospect from multiple people; user wants to qualify a lead; user mentions BANT,
  MEDDICC, or discovery call prep with prospect data; user pastes sales conversations, Slack threads, emails, or CRM data
  about a potential customer; user wants to make sense of scattered sales intel; user asks what questions to ask next based
  on gathered notes about a deal; user mentions pipeline review or forecast prep involving account notes.
---

# Qualifying Lead Skill

You help sales teams turn raw, unorganized notes from various colleagues into a structured lead qualification document. The output strictly follows the template in `references/lead-qualification-output-template.md`.

## The #1 rule: Never fabricate, always quote

This is the most important instruction in this entire skill. The sales team's trust in these documents depends on it:

1. **If a point is mentioned in the input, quote it directly using `"..."`** — use the person's exact words, not your paraphrase. Attribution matters: say who said it and in what context.
2. **Do NOT hallucinate, assume, or infer anything that was not explicitly mentioned** — if the notes don't say it, you don't know it. It doesn't matter how reasonable an inference seems. A plausible guess written with confidence is worse than a gap, because the sales team will act on it as if it were real.
3. **If a point is not covered in the input, do not fill it in** — flag it as a suggested question to frame for the discovery call. Write: *"Not mentioned — suggested discovery question: [your question]"*

These three rules override everything else. If you're ever unsure whether something was stated or inferred, treat it as a gap. The whole point of this document is to give the sales team an honest, quotable map of what they know and what they still need to find out. Fabricated information — even well-intentioned — can lead to embarrassing conversations with prospects and misaligned deal strategies.

## Why this matters

Sales notes come from many sources — hallway conversations, Slack threads, emails, call summaries, CRM comments — and they're rarely organized by framework. Your job is to sift through the noise, extract what's actually been said, and map it to the right sections of the qualification template.

## Workflow

### Step 1: Receive and acknowledge the notes

When the user provides unorganized sales notes (pasted text, a file, or multiple messages), acknowledge what you've received and confirm you'll begin processing.

If the notes mention a company or account name, extract it for the output filename. If no account name can be identified from the notes, use `unnamed` as the account name — don't ask the user, just proceed.

### Step 2: Enter planning mode

Enter plan mode using the `EnterPlanMode` tool. This is important because it lets the user see and approve your approach before you produce the final document.

In your plan, do the following:

1. **Read the template** — Read `references/lead-qualification-output-template.md` (located relative to this skill file) to understand every section and field.

2. **Extract and categorize** — Go through the raw notes and identify which pieces of information map to which sections of the template. Organize your findings as:
   - **BANT** (Budget, Authority, Need, Timeline)
   - **MEDDICC** (Metrics, Economic Buyer, Decision Criteria, Decision Process, Identify Pain, Champion, Competition)
   - **3 WHYs** (Why Datadog, Why Now, Why Do Anything)

3. **Identify gaps** — For each template field where the notes provide no information, note it as a gap. For each gap, draft a suggested discovery question that the sales team could ask in the next call.

4. **Flag ambiguities** — If notes contain contradictory information or unclear references (e.g., a name mentioned without a role, a budget figure that could be interpreted multiple ways), call these out explicitly.

5. **Propose the account name and filename** — Based on the notes, propose: `lead-qualification-[account-name]-[ISO8601-timestamp].md` where account-name is kebab-cased and the timestamp is the current date/time.

Present this plan clearly, section by section, so the user can see exactly what will go into each part of the output. End by asking: **"Does this plan look good? Should I adjust anything before generating the final document?"**

### Step 3: Wait for approval

Do not proceed until the user explicitly approves the plan. If they request changes, update the plan accordingly and ask for approval again.

### Step 4: Generate the output document

Once approved, exit plan mode using `ExitPlanMode`, then produce the markdown file.

The output must:
- Follow the structure of `references/lead-qualification-output-template.md` **exactly** — same headings, same order, same formatting
- **Quote directly** from the notes using `"..."` for every piece of information — attribute each quote to the person who said it and the context (e.g., "Mike Chen, VP Engineering, via Sarah's Slack message on March 15"). Never paraphrase when a direct quote is available.
- **Never hallucinate, assume, or infer** anything not explicitly stated in the notes. This is critical. If a field has no information, do not fill it with reasonable-sounding guesses. Even connecting dots between two separate statements counts as inference unless the notes explicitly make that connection.
- For fields with no information, write: *"Not mentioned — suggested discovery question: [your question]"* — the discovery question should be specific and actionable, something the sales team can ask verbatim in the next call.
- Include mermaid diagrams for Authority/Economic Buyer org charts and Timeline/Decision Process charts **only when** enough information exists in the notes to make them meaningful. Do not invent reporting relationships or timeline dates that weren't mentioned.
- Remove the example blocks from the template — those are guidance for you, not part of the output
- Remove the instruction blocks from the template — those are guidance for you, not part of the output

Save the file as: `dist/lead-qualification-[account-name]-[ISO8601-timestamp].md`
- Account name: kebab-case, lowercase (e.g., `acme-corp`). If no account name was found in the notes, use `unnamed`.
- Timestamp: format `YYYYMMDDTHHMMSS` (e.g., `20260323T143022`)
- Save into the `dist/` folder relative to the current working directory. Create the `dist/` directory if it doesn't exist.

### Important principles

- **Direct quotes over paraphrasing.** When notes say something relevant, quote the exact words and attribute them. "Mike said MTTR is over 2 hours" is better than "MTTR exceeds 2 hours." The original voice matters — it tells the reader how confident the source was, what language the prospect actually uses, and whether the information is first-hand or second-hand.
- **Gaps are valuable — fabrication is dangerous.** A qualification document with 15 honest gaps is far more useful than one that looks complete but contains 5 plausible-sounding fabrications. Gaps tell the sales team exactly what to ask next. Fabrications lead to embarrassing conversations when the sales rep references something the prospect never said.
- **Contradictions should surface, not hide.** If two colleagues said conflicting things (e.g., different budget numbers, different timelines), show both with direct quotes and flag the conflict explicitly. Do not pick a side or average the numbers. Let the user decide which is accurate.
- **The template is the contract.** Don't add extra sections, don't skip sections, don't reorder. The team relies on a consistent format across all qualification documents.
- **When in doubt, it's a gap.** If you're unsure whether something was explicitly stated or you're connecting dots from separate pieces of information, treat it as a gap with a discovery question. It's always better to under-claim than over-claim.
