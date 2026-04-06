# TODO — java-instrumentation

> Combined from datadog-proof/java/ CLAUDE.md and TODO files.

---

## CLAUDE.md

# Java App Development

## About
Multiple Java applications

## Structure
- Shallow directories, avoid deep nesting
- Naming: `<framework><framework_version>__<server><server_version>__<java><java_version>`
- Example: `springboot2dot7dot5__tomcat9dot0__openjdk8u422`, `springboot3dot1__jboss7dot4__corretto17u16`

## Tooling
- Use SDKMAN! CLI for Gradle, Maven, and Java version control and installation

## Workflow
1. **Research**: Create `2-RESEARCH.md` implementation plan
2. **Review**: Wait for user approval
3. **Plan**: Create detailed `3-PLAN.md` with atomic steps
4. **Implement**: Execute step-by-step, mark "(COMPLETED)"

## Guidelines
- Keep simple (Hello World level)
- Assume no prior dev knowledge
- Small, atomic steps
- Individual tests only
- Wait for explicit approval between phases
- Focus and independence per app
---

## 1a-TODO-JAVA.md

## TASKS:
* A folder named springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback contains a Java 17 web app using Spring Boot version 3.5.9 with embedded Tomcat version 10.1 that uses openjdk 17.0.17 that uses Maven
* Use SLF4J + Logback for logging implementation
* Create 3 API endpoints:
* First endpoint GET that returns some dummy data with 5 digits random number and writes to the log with every call. It logs to the console.
* Second endpoint POST that writes to the log with every call. It logs to the SyslogAppender.
* Third endpoint PUT that will return status code followed by writes to the log with every call. It logs to the FileAppender.
* Every endpoint will have a 30% chance of returning 2XX status code, 40% chance of returning a 4XX status code, and 30% chance of returning a 5XX status code. 
* Use Playwright Java MCP to test the Java app whenever viable.
* Document instructions on testing these three endpoints using curl commands to README.md
* Document instructions on running the app to README.md
* Document instructions on packaging the executable JAR file deployment as well as running it in a Linux Ubuntu machine details to README.md


## USE CONTEXT7
- use library /context7/gradle?tokens=5000
- use library /context7/spring_io-spring-boot
- use library /context7/tomcat_apache_tomcat-10_1-doc
- use library /openjdk/jdk?tokens=5000
- use library /microsoft/playwright-java for testing the java app


## Implementation should consider:
- **README.md**: Include setup, deployment, verification, and cleanup steps
- **Git Ignore**: Create a .gitignore to avoid committing common Java files or output to Git repo
- **Simplicity**: Keep the Java project really simple
- **PII and Sensitive Data**: Do be mindful that I will be committing the Java project to a public Github repo so do NOT commit private key or secrets.
- **Version compatability**: Ensure versions compatibility across tech stack

## OTHER CONSIDERATIONS:
- Run the project on MacOS bash terminal
- Explain the steps you would take in clear, beginner-friendly language
- Write the research on performing the task
- Save the research to `2-RESEARCH.md`

<!-- #### Alternatives to Apache Tomcat (as traditional deployment):
1. **Embedded Servers (with Spring Boot)**:
   - Jetty (lightweight, embeddable)
   - Undertow (high-performance, non-blocking)

2. **Standalone Servers**:
   - Apache Tomcat (traditional deployment)
   - Eclipse Jetty
   - WildFly (full Java EE)
   - GlassFish (Oracle's Java EE reference)
   - Oracle WebLogic
   - Red Hat JBoss Enterprise Application Platform
   - IBM WebSphere

3. **Container/Cloud Deployment**:
   - Docker containers
   - Kubernetes deployments
   - Cloud platforms (AWS, Azure, Google Cloud) -->
---

## 1b-TODO-DATADOG.md

## OVERACHING OBJECTIVES:
* Instrument my java app with dd-trace-java and datadog agent.
* Instrument my java app so that it will dynamically collect more error logs when there is an error.

## BACKGROUND:
* A folder named springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback contains a Java 17 web app using Spring Boot version 3.5.9 with embedded Tomcat version 10.1 that uses openjdk 17.0.17 that uses Maven and SLF4J + Logback for logging implementation

## TASKS:
* Update the ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md file to include a section call "Datadog dd-trace-java" on steps to add dd-trace-java to the running .jar java app in MacOS and Linux Ubuntu OS. 
* Add instructions to ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md on log linking - by using the dd-trace-java SDK to inject trace_id and span_id into your logs, Datadog's backend can automatically surface all logs related to a specific error event.
* Add instructions to ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md on Dynamic Instrumentation for Java using dd-trace-java SDK - by adding "Log Probes" to the running application without redeploying code. The conditions are for a probe to turn up the volume of logging based on an error.
* Explain the architecture and components interaction of dynamic instrumentation and how log probe work to fulfil my objective to the ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md
* Add instructions to ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md on how to use Datadog Agent level filtering by configuring in a Linux Ubuntu environment the datadog.yaml and setting the Datadog Agent to send more of ERROR and CRITICAL logs. Also send more of "Info" logs during an incident.
* Add instructions to ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md on how to manually trigger "more logs" when you catch an exception in Java, you can use the Datadog SDK dd-trace-java to add "Tags" or "Baggage" to the current span. This makes the "lesser" logs much more valuable during an error.
* Explain how Datadog can automatically prioritise the logs ingestion that are part of an "Error Trace." in the ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md
* Document instructions on testing the above tasks to ./springboot3dot5dot9__tomcat10dot1__openjdk17dot0dot17__logback/README.md
* When adding instructions, please make sure that the instructions are simple and concise - don't bloat the instructions but over explaining.

## Documentation Reference
* https://docs.datadoghq.com/tracing/trace_collection/dynamic_instrumentation/enabling/java/?tab=curl for adding dynamic instrumentation
* https://docs.datadoghq.com/tracing/trace_collection/library_config/java/
* https://docs.datadoghq.com/tracing/trace_collection/dynamic_instrumentation/ for creating a probe, creating log probes, creating metric probes, creating span probes, and creating span tag probes
* https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/java/?tab=maven for trace spans and logs correlation


## USE CONTEXT7
* use library /datadog/dd-trace-java for automatic instrumentation and dynamic instrumentation
<!-- * use library /datadog/datadog-api-client-java when prompts indicates that Datadog API Client Java is needed -->
* use library /datadog/datadog-agent when instructions are need for setting up Datadog Agent
<!-- * use library /open-telemetry/opentelemetry-java for reference to OpenTelemetry Java API for custom instrumentation -->


## Implementation should consider:
* **README.md**: Include setup, deployment, verification, and cleanup steps
* **Git Ignore**: Create a .gitignore to avoid committing common Java files or output to Git repo
* **Simplicity**: Keep the Java project really simple
* **PII and Sensitive Data**: Do be mindful that I will be committing the Java project to a public Github repo so do NOT commit private key or secrets.
* **Version compatability**: Ensure versions compatibility across tech stack

## OTHER CONSIDERATIONS:
* Run the project on MacOS bash terminal
* Explain the steps you would take in clear, beginner-friendly language
* Write the research on performing the task
* Keep the Datadog Instrumentation steps simple
* Save the research to `2-RESEARCH.md`
---

## 1a-TODO-JAVA.md

## TASKS:
* Create an endpoint called /payload-to-spantags of this Java Springboot app, enable GET request by accepting a payload. 
* The payload is a JSON key value pair.
* After which, add the payload key value pair as custom spans tag using the OpenTelemetry API for Java https://docs.datadoghq.com/opentelemetry/instrument/dd_sdks/api_support/?platform=traces&prog_lang=java 
* Return 200 HTTP status if the operation is successful otherwise return error status.
* Use Playwright Java MCP to test the Java app whenever viable.


## USE CONTEXT7
- use library /context7/gradle?tokens=5000
- use library /context7/spring_io-spring-boot
<!-- - use library /context7/tomcat_apache_tomcat-10_1-doc -->
- use library /openjdk/jdk?tokens=5000
- use library /microsoft/playwright-java for testing the java app


## Implementation should consider:
- **README.md**: Include setup, deployment, verification, and cleanup steps
- **Git Ignore**: Create a .gitignore to avoid committing common Java files or output to Git repo
- **Simplicity**: Keep the Java project really simple
- **PII and Sensitive Data**: Do be mindful that I will be committing the Java project to a public Github repo so do NOT commit private key or secrets.
- **Version compatability**: Ensure versions compatibility across tech stack

## OTHER CONSIDERATIONS:
- Run the project on MacOS bash terminal
- Explain the steps you would take in clear, beginner-friendly language
- Write the research on performing the task
- Save the research to `2-RESEARCH.md`
