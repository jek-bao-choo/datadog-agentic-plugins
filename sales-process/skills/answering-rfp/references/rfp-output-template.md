# Datadog RFP/RFI Response Template

> **Core Instructions — these override everything else:**
>
> 1. **Never fabricate, always quote.** If a requirement is mentioned in the raw notes, quote the prospect's exact words using `"..."` in the Prospect's Requirement column. Attribution matters — note who said it and in what context. A plausible guess written with confidence is worse than a gap, because the sales team will act on it as if it were real.
> 2. **Do NOT hallucinate, assume, or infer** anything that was not explicitly mentioned in the input. If the notes don't say it, you don't know it — no matter how reasonable an inference seems.
> 3. **Web search is mandatory** for the "Datadog's Response / Remark / Comment" and "Datadog's Doc / Blog / Trust / Legal URL" columns. Responses must be grounded in actual Datadog documentation, blog posts, trust pages, or legal pages found via web search. Never fabricate URLs or capabilities.
> 4. **Demo URLs** must always use the `https://demo.datadoghq.com/` base. Write `NA` if no relevant demo page exists. Access `https://demo.datadoghq.com/` via https://github.com/ChromeDevTools/chrome-devtools-mcp.
> 5. **When in doubt, flag for clarification** — assign "Clarification" supportability and write a specific question. Gaps are valuable; fabrication is dangerous.

---

## Workflow

Follow these steps to transform raw sales notes into the RFP/RFI response table:

1. **Receive raw notes** — Accept messy, unstructured input (meeting notes, emails, Slack threads, CRM data, requirement documents, call transcripts). The notes are often uncategorised and scattered.
2. **Extract requirements** — Read through all notes and identify every distinct functional requirement, non-functional requirement, technical stack detail, infrastructure detail, and inquiry or question. Each becomes its own row in the output table.
3. **Categorize** — Assign each extracted requirement to the appropriate category from the Category Taxonomy below.
4. **Determine supportability** — Evaluate each requirement against Datadog's capabilities and assign one of the four allowed Supportability Values below.
5. **Research and respond** — Follow the tiered search escalation in the Web Search Guidance section below: start with Datadog official docs (`datadoghq.com`), then Datadog GitHub repos (`github.com/DataDog/`), then Datadog internal knowledge base, then OpenTelemetry (`opentelemetry.io` / `github.com/open-telemetry/`) as a fallback. Write the response column based on what you find. Never fabricate information.
6. **Find URLs** — Populate the URL column from whichever tier yielded the answer — URLs may come from `datadoghq.com`, `github.com/DataDog/`, Datadog internal KB, or `opentelemetry.io` / `github.com/open-telemetry/`. Populate Demo URLs from `demo.datadoghq.com` — use https://github.com/ChromeDevTools/chrome-devtools-mcp to discover relevant demo pages.
7. **Output the table** — Produce the final markdown table following the exact column format defined below.

---

## Column Definitions

| Column | Purpose | Guidance |
| :---- | :---- | :---- |
| **Category / Section / Area / Dimension / Domain** | Groups the requirement into a logical domain | Use values from the Category Taxonomy below. If a requirement spans multiple categories, pick the primary one. |
| **Prospect's Requirement / Inquiry / Question / Description / Framework** | The extracted requirement, quoted from the raw notes | Quote directly using `"..."` when possible. For technical stack items, include language, version, and framework. For infrastructure, include platform, version, and orchestrator details. If the notes are vague, extract what exists and flag specifics for clarification. |
| **Datadog's Supportability** | How well Datadog supports this requirement | Allowed values: `Yes`, `Partial`, `Comply`, `Clarification`. See Supportability Values section below. |
| **Datadog's Response / Remark / Comment** | Datadog's detailed response to the requirement | Must be sourced via the tiered search escalation (see Web Search Guidance below): Datadog docs/blog/trust/legal → Datadog GitHub → internal KB → OpenTelemetry. Explain how Datadog addresses the requirement. If the answer comes from OpenTelemetry, clearly state that native Datadog support is not available and describe the OTel-based approach. Never fabricate capabilities. |
| **Datadog's Doc / Blog / Trust / Legal URL** | Supporting URL from the source that confirmed supportability | Must be a real URL found via web search. May come from `datadoghq.com` (docs, blog, trust, legal), `github.com/DataDog/`, Datadog internal KB, or `opentelemetry.io` / `github.com/open-telemetry/` depending on which tier yielded the answer. Write `NA` if no relevant URL is found. Never fabricate URLs. |
| **Datadog's Demo URLs** | Link to relevant Datadog demo environment page | Must start with `https://demo.datadoghq.com/`. Use https://github.com/ChromeDevTools/chrome-devtools-mcp to discover relevant demo pages. Write `NA` if no relevant demo page exists. |

---

## Category Taxonomy

Use these categories to classify each extracted requirement. If a requirement does not fit any category, use "Other".

| Category | Description | Example Requirements |
| :---- | :---- | :---- |
| **Observability** | End-to-end visibility, monitoring, APM, metrics, logs, traces, alerting | "Need unified view across all services" |
| **Integration & Extensibility** | CI/CD pipeline integration, DevOps toolchain, API access, webhooks, third-party integrations | "Must integrate with Jenkins and GitLab" |
| **Frontend Technical Stack** | Frontend frameworks, languages, versions, mobile SDKs | "React 18", "Next.js 14", "Flutter", "React Native" |
| **Backend Technical Stack** | Backend languages, frameworks, versions, runtime environments | ".NET 8", "Java Spring Boot 3.x", "Python FastAPI" |
| **Infrastructure Platform Technical Stack** | Cloud providers, container orchestration, serverless, infrastructure details | "AWS Lambda", "Kubernetes 1.28 on EKS" |
| **Database & Data Store Technical Stack** | Databases, caches, message queues, versions | "PostgreSQL 15", "Redis 7", "Kafka 3.6" |
| **Data Storage Location** | Data residency, on-premise requirements, cloud regions, data sovereignty | "Data must stay in EU", "On-premise storage preferred" |
| **Security & Compliance** | Security certifications, compliance frameworks, audit requirements, encryption | "Need SOC 2 Type II compliance" |
| **Lawfulness** | Legal, regulatory, AI ethics, data processing laws | "Does the AI have potential to violate laws?" |
| **Data Protection Laws & Regulations** | Specific data protection regulations, DPAs, privacy frameworks | "Need a Data Processing Addendum" |
| **Platform & Architecture Support** | Backup, disaster recovery, high availability, specific architecture patterns | "Backup integration with Cohesity DataProtect" |
| **Performance & Scalability** | Performance requirements, SLAs, throughput, latency targets | "Must handle 10M events per second" |
| **User Management & Access Control** | SSO, RBAC, multi-tenancy, identity providers | "Need SAML SSO with Okta" |
| **Cost & Licensing** | Pricing model, licensing terms, cost optimization | "Need per-host pricing model" |
| **Other** | Requirements that do not fit the above categories | Note in the response column suggesting a more specific category |

---

## Supportability Values

Each requirement must be assigned exactly one of these four values:

- **Yes** — Datadog fully supports this requirement out of the box or with standard configuration. Use when Datadog documentation or blog posts confirm full support.
- **Partial** — Datadog addresses this requirement but with limitations, workarounds, or only partial coverage. Always explain what is supported and what is not in the response column.
- **Comply** — The requirement is a compliance, legal, or policy question and Datadog meets the standard. Use for regulatory, certification, or legal questions.
- **Clarification** — The requirement is ambiguous, incomplete, or requires a deeper conversation with the prospect to understand what they actually need. Always write a specific clarification question in the response column.

**Decision tree:**

1. Is it a compliance/legal/policy question and Datadog meets it? → **Comply**
2. Is the requirement clear and Datadog fully supports it? → **Yes**
3. Is the requirement clear but Datadog only partially supports it? → **Partial**
4. Is the requirement unclear, ambiguous, or missing critical detail? → **Clarification**

---

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

---

## Web Search Guidance

The response column and URL column must be grounded in real content found via web search. Follow this tiered search escalation — move to the next tier only when the previous tier yields no relevant results:

### Tier 1 — Datadog Official Docs & Content (`datadoghq.com`)

Search first using queries like: `site:datadoghq.com [technology or topic]`

URL priority within this tier:
1. `docs.datadoghq.com` — technical documentation (highest priority)
2. `www.datadoghq.com/blog/` — blog posts with deeper explanations
3. `trust.datadoghq.com` — security and compliance questions
4. `www.datadoghq.com/legal/` — legal, DPA, and policy questions

### Tier 2 — Datadog GitHub Repositories (`github.com/DataDog/`)

If Tier 1 does not confirm supportability, search Datadog's GitHub repositories for technical capabilities, supported versions, framework compatibility, and compilation mode support (e.g., NativeAOT, GraalVM). Key repositories:
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
- `github.com/open-telemetry/` + language or technology keyword — for specific OTel SDKs and instrumentation libraries

When using OpenTelemetry as the answer, set supportability to "Partial" and clearly state in the response that native Datadog instrumentation is not available but the technology can be monitored via OpenTelemetry with Datadog's OTLP ingestion.

### Terminate Search

If even OpenTelemetry does not support the technology, stop searching. Set supportability to "Clarification" and note in the response column that neither native Datadog nor OpenTelemetry instrumentation was found, and recommend discussing with Datadog's sales engineering team.

### General Rules

- The response column content should be based on what you find in these sources. Quote or closely paraphrase the documentation.
- **Never fabricate or guess URLs.** A broken link is worse than `NA`.
- If no relevant URL is found at any tier, write `NA` for the URL column.

---

## Handling Ambiguous or Incomplete Requirements

- **Vague requirements** (e.g., "need good monitoring") — Still create a row. Set supportability to "Clarification" and write a specific question in the response column (e.g., "What specific systems or services need monitoring? What metrics matter most?").
- **Contradictory requirements** (e.g., "must be fully on-premise" and later "cloud-first approach") — Create rows for both, flag the contradiction in the response column, and set both to "Clarification".
- **Missing technical details** (e.g., "need Kubernetes support" without version or provider) — Extract what exists, set supportability based on what is known (likely "Yes" for general K8s support), and note in the response that specific version/provider details should be confirmed.
- **Out-of-scope requirements** (e.g., "need a new CRM system") — Still capture with "Clarification" supportability and a response noting this appears outside Datadog's scope but should be discussed for context.
- **Duplicate or overlapping requirements** from different sources — Create one row, quote both sources with attribution, and reconcile if consistent or flag if contradictory.

---

## Example Output Table

> **The rows below demonstrate the expected output format and level of detail.
> Remove this example block and replace with actual output when generating a real RFP response.
> Use these as a reference for tone, detail level, URL format, and how each column should be populated.**

| Category / Section / Area / Dimension / Domain | Prospect's Requirement / Inquiry / Question / Description / Framework | Datadog's Supportability | Datadog's Response / Remark / Comment | Datadog's Doc / Blog / Trust / Legal URL | Datadog's Demo URLs |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Observability | End-to-end visibility across applications, infrastructure, and services. | Yes | End-to-end application monitoring in Datadog eliminates visibility gaps and unifies insights across your frontend and backend monitoring. Datadog's trace view gives you detailed request data and correlated information in a single pane of glass. In addition to the flame graph—which shows you the full path of each request—the trace view displays the corresponding metrics, logs, and other data you need to understand the context of the request so you can efficiently investigate performance problems like errors and latency. End-to-end visibility means having a unified view of applications, infrastructure, and services so you can: Trace requests across the entire stack. Correlate metrics, logs, and traces in one place. Quickly identify performance issues, dependencies, and root causes. It's about seeing everything from code to infrastructure to user impact in one continuous picture. | [https://www.datadoghq.com/blog/end-to-end-application-monitoring/](https://www.datadoghq.com/blog/end-to-end-application-monitoring/) | [https://demo.datadoghq.com/software?env=prod\&fromUser=true\&graphType=waterfall\&shouldShowLegend=true\&traceQuery=\&view=map](https://demo.datadoghq.com/software?env=prod&fromUser=true&graphType=waterfall&shouldShowLegend=true&traceQuery=&view=map) |
| Integration & Extensibility | CI/CD pipeline integration and DevOps toolchain compatibility. | Yes | Datadog integrates with a wide range of CI/CD and DevOps tools, including Jenkins, GitLab, and CircleCI. This allows you to monitor the performance of your deployment pipelines and correlate application performance with code changes. | [https://docs.datadoghq.com/continuous\_integration/](https://docs.datadoghq.com/continuous_integration/) | [https://demo.datadoghq.com/ci/pipelines/health](https://demo.datadoghq.com/ci/pipelines/health) |
| Platform & Architecture Support | Backup and disaster recovery integration with Cohesity DataProtect, Helios, and SmartFiles. | Clarification | Further discussion is recommended to align on the specific outcome. | NA | NA |
| Data Storage Location | Preference for data to be stored on-premise | Partial | Logs can be stored on-premise or a customer's own cloud environment (Bring Your Own Cloud). Metrics and traces are sanitized before being stored in Datadog's backend systems, which adhere to rigorous compliance and trust standards such as SOC 2 and others. These data centers are located across the US, Europe, Japan, and Australia. Additionally, PrivateLink and VPC Peering can be established to ensure secure and reliable connectivity. | [https://docs.datadoghq.com/cloudprem/](https://docs.datadoghq.com/cloudprem/) | [https://demo.datadoghq.com/cloudprem](https://demo.datadoghq.com/cloudprem) |
| Lawfulness | Does the Datadog AI have any potential to violate laws and regulations? | Comply | Datadog is committed to lawful and ethical operations. We provide a platform that helps customers meet their own compliance obligations. Our platform itself undergoes rigorous, independent third-party audits and certifications (e.g., SOC 2, ISO 27001, HIPAA, PCI DSS), demonstrating our adherence to global security and privacy standards. | [https://trust.datadoghq.com/](https://trust.datadoghq.com/) | NA |
| Data Protection Laws & Regulations | Are processes, procedures, and technical measures implemented to ensure personal data is processed per applicable laws and regulations and for the purpose declared to the data subject? | Yes | Please refer to Datadog's Data Processing Addendum | [https://www.datadoghq.com/legal/data-processing-addendum/](https://www.datadoghq.com/legal/data-processing-addendum/) | NA |
| Frontend Technical Stack | The frontend development is primarily in React, with an ongoing transition from Flutter to React Native. | Yes | Datadog fully supports that stack end-to-end: React web apps: Supported via Browser RUM and the React integration, including route tracking, errors, and performance. React Native (target mobile): Supported via the React Native RUM SDK with similar capabilities (RUM, crash/error reporting, network, Session Replay). | [https://docs.datadoghq.com/real\_user\_monitoring/application\_monitoring/react\_native/](https://docs.datadoghq.com/real_user_monitoring/application_monitoring/react_native/) | [https://demo.datadoghq.com/rum/performance-monitoring](https://demo.datadoghq.com/rum/performance-monitoring) |
| Frontend Technical Stack | The informational sites are built on NextJS. | Yes | Datadog supports Next.js informational sites: Supported with Browser RUM (client- and server-side rendering) and correlation to backend traces; docs explicitly call out Next.js as a first-class framework. | [https://docs.datadoghq.com/real\_user\_monitoring/guide/monitor-your-nextjs-app-with-rum/](https://docs.datadoghq.com/real_user_monitoring/guide/monitor-your-nextjs-app-with-rum/) | [https://demo.datadoghq.com/rum/performance-monitoring](https://demo.datadoghq.com/rum/performance-monitoring) |
| Backend Technical Stack | The backend services are a mix, predominantly featuring .NET 8 | Yes | Datadog supports .NET (including .NET 8/9): Fully supported by Datadog APM with automatic instrumentation for ASP.NET Core and related frameworks. | [https://docs.datadoghq.com/tracing/trace\_collection/dd\_libraries/dotnet-core/?tab=windows](https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/dotnet-core/?tab=windows) | [https://demo.datadoghq.com/software?query=language%3Adotnet\&env=prod\&fromUser=true\&graphType=waterfall\&lens=Ownership\&shouldShowLegend=true\&traceQuery=\&start=1774231563566\&end=1774235163566](https://demo.datadoghq.com/software?query=language%3Adotnet&env=prod&fromUser=true&graphType=waterfall&lens=Ownership&shouldShowLegend=true&traceQuery=&start=1774231563566&end=1774235163566) |
| Backend Technical Stack | Java Springboot for tasks requiring extensive CPU calculations, | Yes | Datadog supports Java Spring Boot: Fully supported via the Java tracer (dd-trace-java) and Spring Boot/Spring MVC integrations. | [https://docs.datadoghq.com/tracing/trace\_collection/compatibility/java/?tab=graalvm](https://docs.datadoghq.com/tracing/trace_collection/compatibility/java/?tab=graalvm) | [https://demo.datadoghq.com/software?query=language%3Ajvm\&env=prod\&fromUser=true\&graphType=waterfall\&lens=Ownership\&shouldShowLegend=true\&traceQuery=\&start=1774231563566\&end=1774235163566](https://demo.datadoghq.com/software?query=language%3Ajvm&env=prod&fromUser=true&graphType=waterfall&lens=Ownership&shouldShowLegend=true&traceQuery=&start=1774231563566&end=1774235163566) |
| Infrastructure Platform Technical Stack | Primarily utilising a serverless architecture \- AWS Lambda | Yes | Datadog has first-class serverless monitoring for AWS Lambda (metrics, logs, traces, enhanced Lambda metrics, and the Lambda extension). | [https://docs.datadoghq.com/serverless/aws\_lambda/](https://docs.datadoghq.com/serverless/aws_lambda/) | [https://demo.datadoghq.com/serverless](https://demo.datadoghq.com/serverless) |

---

> **Reminder — Critical Instructions:**
> - If a requirement is mentioned in the input, quote it directly using `"..."`
> - Do NOT hallucinate, assume, or infer anything that was not explicitly mentioned
> - If a requirement is not covered in the input, do not guess — flag it for clarification with the customer or prospect
> - Each distinct requirement, technology, or question gets its own row
> - All responses must be grounded in web search results from `datadoghq.com` — never fabricate capabilities or URLs
> - When in doubt about supportability, use "Clarification" rather than guessing "Yes" or "Partial"
> - Gaps and "Clarification" entries are valuable — they tell the sales team exactly what to discuss next
