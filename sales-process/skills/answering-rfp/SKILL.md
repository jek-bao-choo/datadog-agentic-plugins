---
name: answering-rfp
description: >
  Transforms raw sales notes into a structured RFP/RFI response table with Datadog supportability assessments,
  web-search-grounded responses, documentation URLs, and demo links — output follows a mandatory template in
  reference files that CANNOT be reproduced without this skill.

  IMPORTANT: Always use this skill for ANY RFP, RFI, vendor questionnaire, compliance questionnaire, prospect
  requirements, or technical capability mapping about Datadog. The exact table format this skill provides is required.

  Triggers: user pastes sales notes, meeting notes, emails, or requirements wanting an RFP/RFI table; mentions RFP,
  RFI, vendor assessment, or compliance questionnaire; asks about Datadog supportability for a prospect's tech stack;
  wants to organize prospect requirements into a structured response; needs Datadog capability mapping.
---

# Answering RFP Skill

You help sales teams transform raw, unstructured notes from various sources into a structured RFP/RFI response table. The output strictly follows the template in `references/rfp-output-template.md`.

## The #1 rule: Never fabricate, always quote

This is the most important instruction in this entire skill. The sales team's trust in these documents depends on it:

1. **If a requirement is mentioned in the input, quote it directly using `"..."`** — use the prospect's exact words, not your paraphrase. Attribution matters: always include who said it, via what channel, and when. Format as: `Jane Doe 1 (SE lead, Slack thread March 15): "their frontend is React 18"`. This tells the sales team how reliable the information is and who to follow up with.
2. **Do NOT hallucinate, assume, or infer anything that was not explicitly mentioned** — if the notes don't say it, you don't know it. It doesn't matter how reasonable an inference seems. A plausible guess written with confidence is worse than a gap, because the sales team will act on it as if it were real.
3. **If a requirement is not covered in the input, do not guess** — flag it for clarification with the customer or prospect. Set supportability to "Clarification" and write a specific question in the response column.

These three rules override everything else. If you're ever unsure whether something was stated or inferred, treat it as a gap. The whole point of this document is to give the sales team an honest, research-grounded map of what the prospect needs and how Datadog addresses it. Fabricated information — even well-intentioned — can lead to embarrassing conversations with prospects and misaligned deal strategies.

## Why this matters

Sales notes come from many sources — hallway conversations, Slack threads, emails, call summaries, CRM comments, requirement documents, vendor questionnaires — and they're rarely organized into a structured format. The prospect's functional requirements, non-functional requirements, technical stack details, and compliance questions are scattered across these notes.

Your job is to sift through the noise, extract every distinct requirement, research Datadog's ability to address it, and produce a clean RFP/RFI table that the sales team can hand to the prospect or use to prepare their response.

## Workflow

### Step 1: Receive and acknowledge the notes

When the user provides unorganized sales notes (pasted text, a file, or multiple messages), acknowledge what you've received and confirm you'll begin processing.

If the notes mention a company or account name, extract it for the output filename. If no account name can be identified from the notes, use `unnamed` as the account name — don't ask the user, just proceed.

### Step 2: Enter planning mode

Enter plan mode using the `EnterPlanMode` tool. This lets the user see and approve your approach before you produce the final table.

In your plan, do the following:

1. **Read the template** — Read `references/rfp-output-template.md` (located relative to this skill file) to understand the column definitions, category taxonomy, supportability values, and example output format.

2. **Extract and categorize** — Go through the raw notes and identify every distinct requirement, mapping each to a category from the taxonomy. Organize your findings by category, showing:
   - The quoted requirement from the notes
   - The proposed category
   - An initial supportability assessment
   - Any notes on what needs research

3. **Extract technical stack details** — Follow the extraction rules in the "Extracting Technical Stack Details" section below. Pay special attention to versions, rendering modes (SSR/CSR/SSG/ISR), and compilation modes (NativeAOT, GraalVM).

4. **Identify gaps and ambiguities** — For requirements that are vague, contradictory, or missing critical details, note them explicitly and propose clarification questions.

5. **Propose the account name and filename** — Based on the notes, propose: `rfp-response-[account-name]-[ISO8601-timestamp].md` where account-name is kebab-cased and the timestamp is the current date/time.

Present this plan clearly, category by category, so the user can see exactly what will go into the output table. End by asking: **"Does this plan look good? Should I adjust anything before generating the final RFP response?"**

### Step 3: Wait for approval

Do not proceed until the user explicitly approves the plan. If they request changes, update the plan accordingly and ask for approval again.

### Step 4: Generate the output document

Once approved, exit plan mode using `ExitPlanMode`, then produce the markdown file.

For each requirement row:
1. **Research** — Follow the tiered search escalation below to find Datadog's response and supporting URLs
2. **Populate the table** — Fill in all 6 columns following the format in `references/rfp-output-template.md`
3. **Find demo URLs** — Use https://github.com/ChromeDevTools/chrome-devtools-mcp to discover relevant pages on `https://demo.datadoghq.com/`

The output must:
- Follow the column structure of `references/rfp-output-template.md` **exactly** — same columns, same order, same formatting
- **Quote directly** from the notes using `"..."` for the Prospect's Requirement column
- **Never hallucinate, assume, or infer** anything not explicitly stated in the notes
- For ambiguous requirements, set supportability to "Clarification" and write a specific question
- Remove the example rows from the template — those are guidance for you, not part of the output
- Remove the instruction blocks from the template — those are guidance for you, not part of the output
- **Save the file as `rfp-response-[account-name]-[ISO8601-timestamp].md`** — use the account name from Step 1 (kebab-cased), or `unnamed` if no account name was identified
- **End with a "Clarification Summary" section** after the table. Collect all clarification questions from the "Clarification" rows into a numbered, prioritized list. This gives the sales team a ready-made agenda for their next call with the prospect. Prioritize by business impact — contradictions and blockers first, then missing technical details. Example format:

```
## Clarification Summary — Questions for Next Call

1. **[Highest priority topic]** — [specific question from the table row]
2. **[Next priority topic]** — [specific question]
...
```

## Tiered search escalation

When researching Datadog's response and finding URLs for each requirement, follow this escalation. Move to the next tier only when the previous tier yields no relevant results:

### Tier 1 — Datadog Official Docs & Content (`datadoghq.com`)

Search first using queries like: `site:datadoghq.com [technology or topic]`

URL priority within this tier:
1. `docs.datadoghq.com` — technical documentation (highest priority)
2. `www.datadoghq.com/blog/` — blog posts with deeper explanations
3. `trust.datadoghq.com` — security and compliance questions
4. `www.datadoghq.com/legal/` — legal, DPA, and policy questions

### Tier 2 — Datadog GitHub Repositories (`github.com/DataDog/`)

If Tier 1 does not confirm supportability, search Datadog's GitHub repositories for technical capabilities, supported versions, framework compatibility, and compilation mode support. Key repositories:
- `github.com/DataDog/datadog-agent` — infrastructure monitoring (Agent capabilities, supported integrations)
- `github.com/DataDog/dd-trace-{language}` — APM tracing libraries (dd-trace-java, dd-trace-py, dd-trace-dotnet, dd-trace-rb, dd-trace-go, dd-trace-js)
- `github.com/DataDog/browser-sdk` — Browser RUM and Logs SDK
- `github.com/DataDog/dd-sdk-ios` and `github.com/DataDog/dd-sdk-android` — mobile RUM SDKs
- `github.com/DataDog/dd-sdk-reactnative` — React Native SDK
- For other capabilities, search `github.com/DataDog/` + technology keyword

### Tier 3 — Datadog Internal Knowledge Base

If Tier 1 and Tier 2 are exhausted, consult Datadog's internal knowledge base or resources for additional supportability information.

### Tier 4 — OpenTelemetry (`opentelemetry.io` and `github.com/open-telemetry/`)

If Tiers 1–3 yield no native Datadog support, search OpenTelemetry as a fallback. Datadog supports OTLP ingestion, so OpenTelemetry instrumentation can bridge the gap for technologies without native Datadog libraries. Search:
- `opentelemetry.io` — official OpenTelemetry documentation
- `github.com/open-telemetry/opentelemetry.io` — OpenTelemetry documentation source
- `github.com/open-telemetry/` + language or technology keyword

When using OpenTelemetry as the answer, set supportability to "Partial" and clearly state in the response that native Datadog instrumentation is not available but the technology can be monitored via OpenTelemetry with Datadog's OTLP ingestion.

### Terminate Search

If even OpenTelemetry does not support the technology, stop searching. Set supportability to "Clarification" and note in the response column that neither native Datadog nor OpenTelemetry instrumentation was found, and recommend discussing with Datadog's sales engineering team.

### General Rules

- The response column content should be based on what you find in these sources. Quote or closely paraphrase the documentation.
- **Never fabricate or guess URLs.** A broken link is worse than `NA`.
- If no relevant URL is found at any tier, write `NA` for the URL column.

## Extracting Technical Stack Details

Raw sales notes often mention technologies in passing or in lists. Follow these rules when extracting them:

- **Programming languages** — Always capture the language name AND version if mentioned. Example: ".NET 8", "Java 17", "Python 3.11". If no version is mentioned, extract as-is (e.g., "Java") and note in the response that the version was not specified.
- **Frameworks** — Capture framework AND version. Example: "Spring Boot 3.2", "React 18", "Next.js 14", "FastAPI 0.100".
- **Infrastructure** — Capture platform, version, and configuration details. Example: "Kubernetes 1.28 on EKS", "AWS Lambda with Node.js 20 runtime".
- **Databases** — Capture database type and version. Example: "PostgreSQL 15", "MongoDB 7.0", "Redis 7".
- **Rendering and execution modes** — For frontend frameworks, capture the rendering mode if mentioned or probe for it. This affects which Datadog instrumentation applies. Common modes: Server-Side Rendering (SSR), Client-Side Rendering (CSR), Static Site Generation (SSG), Incremental Static Regeneration (ISR). Example: "Next.js 14 with SSR" vs "Next.js as a static site (SSG)". If the rendering mode is not mentioned, flag it for clarification — SSR requires server-side APM tracing while CSR/SSG only needs Browser RUM.
- **Compilation and runtime modes** — For backend and infrastructure technologies, capture compilation or runtime modes that affect observability and tracer compatibility. Examples: ".NET 8 with NativeAOT" (ahead-of-time compilation may limit dynamic instrumentation), "Java with GraalVM native-image" (affects dd-trace-java compatibility), "AWS Lambda with SnapStart" (affects cold start instrumentation), "Lambda with Provisioned Concurrency". If not mentioned, flag for clarification — these modes can significantly affect Datadog's instrumentation approach.
- **One technology per row** — Do not combine multiple technologies into a single row. If the notes say "React, with an ongoing transition from Flutter to React Native", create separate rows for React (web), Flutter (current mobile), and React Native (target mobile).
- **Version matters** — If the notes specify a version, include it. Datadog's support can vary by version. If no version is given, note this and mention the supported version range in the response.

## Handling Ambiguous or Incomplete Requirements

- **Vague requirements** (e.g., "need good monitoring") — Still create a row. Set supportability to "Clarification" and write a specific question in the response column (e.g., "What specific systems or services need monitoring? What metrics matter most?").
- **Contradictory requirements** (e.g., "must be fully on-premise" and later "cloud-first approach") — Create rows for both, flag the contradiction in the response column, and set both to "Clarification".
- **Missing technical details** (e.g., "need Kubernetes support" without version or provider) — Extract what exists, set supportability based on what is known (likely "Yes" for general K8s support), and note in the response that specific version/provider details should be confirmed.
- **Out-of-scope requirements** (e.g., "need a new CRM system") — Still capture with "Clarification" supportability and a response noting this appears outside Datadog's scope but should be discussed for context.
- **Duplicate or overlapping requirements** from different sources — Create one row, quote both sources with attribution, and reconcile if consistent or flag if contradictory.

## Important principles

- **Direct quotes over paraphrasing.** When notes say something relevant, quote the exact words and attribute them. The original voice matters — it tells the reader what language the prospect actually uses and whether the information is first-hand or second-hand.
- **Gaps are valuable — fabrication is dangerous.** An RFP response with 10 honest "Clarification" rows is far more useful than one that looks complete but contains 5 plausible-sounding fabrications. Gaps tell the sales team exactly what to discuss next. Fabrications lead to embarrassing conversations when the sales rep references something the prospect never said.
- **Contradictions should surface, not hide.** If two sources said conflicting things, show both with direct quotes and flag the conflict. Do not pick a side. Let the user decide which is accurate.
- **The template is the contract.** Don't add extra columns, don't skip columns, don't reorder. The sales team relies on a consistent format across all RFP response documents.
- **"Comply" is not "Yes".** Use "Comply" for compliance, legal, regulatory, and policy questions where Datadog meets the standard (SOC 2, ISO 27001, GDPR, FedRAMP, DPA, etc.). Use "Yes" for functional and technical capabilities. This distinction matters because it tells the sales team which rows are about meeting a standard vs providing a feature. Never use "Yes" for compliance questions — even if Datadog fully meets the requirement, "Comply" is the correct supportability value.
- **One requirement, one row.** Each distinct requirement, technology, or question gets its own row. Do not combine React and React Native into one row. If two people said contradictory things, create separate rows for each statement (not one combined row). If a requirement has both a technical and a compliance dimension, create separate rows. More granular rows are always better than lumped rows — they're easier for the sales team to act on individually.
- **When in doubt, it's a "Clarification".** If you're unsure whether something was explicitly stated or you're connecting dots from separate pieces of information, treat it as a gap. It's always better to under-claim than over-claim.
- **Proactively flag technical gaps the prospect didn't ask about.** If a technology is mentioned without a rendering mode (e.g., Next.js without SSR/CSR), compilation mode (e.g., .NET without specifying NativeAOT), or version — create the row with the information given but add a note flagging what's missing and why it matters for Datadog's instrumentation. The sales team benefits from knowing what questions to ask even if the prospect didn't raise the issue.
- **Research is mandatory, not optional.** Every response must be grounded in actual Datadog documentation, GitHub repos, or OpenTelemetry docs found via web search. Never write a response based solely on your training data — always verify via the tiered search escalation.
