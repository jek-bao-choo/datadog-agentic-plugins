# Datadog RFP/RFI Response Template

This is the output format reference. Follow the column definitions, category taxonomy, supportability values, and example table below when generating the RFP/RFI response.

---

## Column Definitions

| Column | Purpose | Guidance |
| :---- | :---- | :---- |
| **Category / Section / Area / Dimension / Domain** | Groups the requirement into a logical domain | Use values from the Category Taxonomy below. If a requirement spans multiple categories, pick the primary one. |
| **Prospect's Requirement / Inquiry / Question / Description / Framework** | The extracted requirement, quoted from the raw notes | Quote directly using `"..."` when possible. For technical stack items, include language, version, and framework. For infrastructure, include platform, version, and orchestrator details. If the notes are vague, extract what exists and flag specifics for clarification. |
| **Datadog's Supportability** | How well Datadog supports this requirement | Allowed values: `Yes`, `Partial`, `Comply`, `Clarification`. See Supportability Values section below. |
| **Datadog's Response / Remark / Comment** | Datadog's detailed response to the requirement | Must be sourced via the tiered search escalation defined in SKILL.md: Datadog docs/blog/trust/legal → Datadog GitHub → internal KB → OpenTelemetry. Explain how Datadog addresses the requirement. If the answer comes from OpenTelemetry, clearly state that native Datadog support is not available and describe the OTel-based approach. Never fabricate capabilities. |
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
> - All responses must be grounded in web search results — never fabricate capabilities or URLs
> - When in doubt about supportability, use "Clarification" rather than guessing "Yes" or "Partial"
> - Gaps and "Clarification" entries are valuable — they tell the sales team exactly what to discuss next
