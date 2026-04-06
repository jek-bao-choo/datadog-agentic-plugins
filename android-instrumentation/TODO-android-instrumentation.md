# TODO — android-instrumentation

> Combined from datadog-proof/kotlin/ CLAUDE.md and TODO files.

---

## CLAUDE.md

# Kotlin App Development

## About
Multiple Kotlin applications which could also be Android native apps developed using Kotlin and Gradle

## Guidelines
- Keep simple
- Assume no prior Kotlin dev knowledge
- Small, atomic steps
- Individual tests only
- Wait for explicit approval between phases
- Focus and independence per app

## My Tooling
- I use SDKMAN! CLI for Gradle, Maven, and Java version control and installation
- I use IntelliJ IDEA Community Edition to build the Kotlin project
- I use JAVA_HOME for building my gradle project

## My Workflow
1. **Research**: Create `2-RESEARCH.md` implementation plan
2. **Review**: Wait for user approval
3. **Plan**: Create detailed `3-PLAN.md` with atomic steps
4. **Implement**: Execute step-by-step, mark "(COMPLETED)"
---

## 1a-TODO-KOTLIN.md

## TASK:
* Created a kotlin android app in android8__api26__superapp folder
* Make the kotline android app look like the mockup ![](superapp-mockup.png).
    * Each of the icon in the mockup is a clickable button.
    * Each of the icon would then link to a webview app. I will provide the webview app. For now the webview app would be a placeholder.
* Suggest something if you think it can be improved.

## OTHER CONSIDERATION:
1. **WebView URLs**: Will point to actual websites (like example.com) - no local HTML files
2. **Service Integration**: Keep everything as simple placeholders - no real service integration
3. **Icons**: Use Material Icons (built-in Android icons)
4. **Color Scheme**: Use default Material 3 color preference
5. **Offline Support**: Not required for initial implementation


## USE CONTEXT7
* use library id /android/nowinandroid for Android design ideas and development best practices
* use library id /android/architecture-samples for different Android architectural approaches

## OTHER CONSIDERATIONS:
* Keep the solution as simple as possible
* Create or append setup, deployment, verification, and cleanup steps in README.md
* Explain the steps you would take in clear, beginner-friendly language
* Save the research to `2-RESEARCH.md`
---

## 1b-TODO-DATADOG.md

## TASK:
* Instrument an Android writtin in Kotlin application called android__api24__helloworld with datadog-sdk-android and datadog-sdk-android-gradle-plugin
* Datadog provided a sample Java code and instruct that I initialize the library in my application context as early as possible. Here is the Java code snippet provided by Datadog:
```java
class SampleApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Hard-coding credentials is not recommended and present security risks. We recommend that you secure your credentials via the step above.
        val applicationId = "<REDACTED_APPLICATION_ID>"
        val clientToken = "<REDACTED_CLIENT_TOKEN>"

        val environmentName = "test"
        val appVariantName = "jek-android7-api24-helloworld"

        val configuration = Configuration.Builder(
            clientToken = clientToken,
            env = environmentName,
            variant = appVariantName
        )
            .useSite(DatadogSite.US1)
            .build()
        Datadog.initialize(this, configuration, trackingConsent)

        
        val rumConfiguration = RumConfiguration.Builder(applicationId)
            .trackUserInteractions()
            .trackLongTasks(durationThreshold)
            .useViewTrackingStrategy(strategy)
            .setSessionSampleRate(100.0f)
            .build()
        Rum.enable(rumConfiguration)
    }
}
```
* Please take note that my application code is written in Kotlin, not Java. 
* Additionally, set the 
* Please research and write down a research plan on how to go about instrumenting and initiating my Android application written in Kotlin with Datadog SDK Android.

## USE CONTEXT7
* use library id /datadog/dd-sdk-android
* use library id /datadog/dd-sdk-android-gradle-plugin

## OTHER CONSIDERATIONS:
* Run the project on MacOS bash terminal
* Append setup, deployment, verification, and cleanup steps in README.md
* Explain the steps you would take in clear, beginner-friendly language
* Write the research on performing the task
* Save the research to `2-RESEARCH.md`
