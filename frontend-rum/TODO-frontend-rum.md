# TODO — frontend-rum

> Combined from datadog-proof/javascript/ CLAUDE.md and TODO files.

---

## CLAUDE.md

# Javascript App Development

## About
This folder contains multiple standalone javascript apps

## Structure
- Shallow directories, avoid deep nesting
- Naming: `<frameworkName><frameworkVersion>__<foundationalFrameworkName_or_langName><foundationalFramework_or_langVersion>`
- Example: `nextjs15dot4__react19dot1`

## Preference
- Document steps in README.md

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

## 1a-TODO-JAVASCRIPT.md

## TASK:
* Background: The vanilla__vite7dot2__submitmeterreading project is a vanilla JS version where the dependencies used are in package.json
* Update the project vanilla__vite7dot2__submitmeterreading with the following requirements:
    * This project is a PoC for Submitting Meter Reading of a Utility company.
    * The web app project will be used by a mobile app as a WebView. This is not required for now. This is just extra information.
    * The web app project is a mobile-responsive page.
    * The landing page looks like ![](vanilla__vite7dot2__submitmeterreading/image1-submit-meter-reading.png)
        * The landing page will have a "Submit Meter Reading" button as seen in the image. Clicking that button will bring us to the next page with proper url routing for Entering Meter.
    * The second page of the web app project will look like ![](vanilla__vite7dot2__submitmeterreading/image4-submit-reading.png) for Entering Meter
        * The second page will have a "Submit Reading" button and clicking that button will bring us to the next page with proper url routing to Reading Submitted page. 
        * The button "Submit Reading" is used to send the the data to a mock backend.
            * Upon clicking the send button, it will trigger a REST HTTP POST to a temporary mock endpoint until I setup a proper backend app with another project. This project will not setup a backend app. The mock endpoint will randomly return text in the HTTP request body with lorem ipsum and a HTTP 2XX success status. The end goal is to interact with OpenAI API endpoint or Claude API endpoint.
    * The third page of the web app project will look like ![](vanilla__vite7dot2__submitmeterreading/image5-reading-submitted.png)
    * The colour theme of this web app will have utility & electricity grid company's feel.


## USE CONTEXT7
- use library id /websites/vite_dev for best practices reference when using Vite for development
- use library id /websites/vite_dev_guide for best practices reference when using Vite for development
<!-- - use library id /reactjs/react.dev?tokens=5000 to reference -->
<!-- - use library id /websites/vuejs_guide for best practices reference -->
<!-- - use library id /vitejs/vite?tokens=3000 for best practices reference -->
<!-- - use library id /vercel/next-learn for best practices reference
- use library id /vercel/next.js for best practices reference -->
<!-- - use library id /skolaczk/next-starter for best practices reference -->
<!-- - use library id /nextjs.org/docs for best practices reference -->
<!-- - use library id /microsoft/playwright the Playwright MCP to automate end-to-end testing through Claude Code browser interaction capabilities -->
<!-- - use library id /microsoft/playwright-mcp the Playwright MCP to automate end-to-end testing through Claude Code browser interaction capabilities -->
<!-- - use library id /shadcn-ui/ui -->
<!-- - use library id /tailwindlabs/tailwindcss.com -->


## Implementation should consider:
- **Documentation**: Include setup, deployment, verification, and cleanup steps in README.md
- **Git Ignore**: Create a .gitignore to avoid committing common Javascript files or output to Git repo if .gitignore doesn't exist
- **PII and Sensitive Data**: Do be mindful that I will be committing the Javascript project to a public Github repo so do NOT commit private key or secrets.
- **Simplicity**: Keep the Javascript project really simple

## OTHER CONSIDERATIONS:
- My computer is a Macbook
- Explain the steps you would take in clear, beginner-friendly language
- Write the research on performing the task
- Save the research to `2-RESEARCH.md`
---

## 1b-TODO-DATADOG

## TASK:
* I want to add Feature Flag to the entire Payee feature in the react19dot1__vite7dot1__sendmoney project.
* Below are the steps from Datadog's documentation https://docs.datadoghq.com/getting_started/feature_flags/ 
```
Step 1: Import and initialize the SDK
First, install @datadog/openfeature-browser, @openfeature/web-sdk, and @openfeature/core as dependencies in your project:

yarn add @datadog/openfeature-browser @openfeature/web-sdk @openfeature/core
Then, add the following to your project to initialize the SDK:

import { DatadogProvider } from '@datadog/openfeature-browser';
import { OpenFeature } from '@openfeature/web-sdk';

// Initialize the provider
const provider = new DatadogProvider({
   clientToken: '<CLIENT_TOKEN>',
   applicationId: '<APPLICATION_ID>',
   enableExposureLogging: true, // Can impact RUM costs if enabled
   site: 'datadoghq.com',
   env: '<YOUR_ENV>', // Same environment normally passed to the RUM SDK
   service: '<SERVICE_NAME>',
   version: '1.0.0',
});

// Set the provider
await OpenFeature.setProviderAndWait(provider);
Setting enableExposureLogging to true can impact RUM costs, as it sends exposure events to Datadog through RUM. You can disable it if you don't need to track feature exposure or guardrail metric status.
More information about OpenFeature SDK configuration options can be found in its documentation. For more information on creating client tokens and application IDs, see API and Application Keys.

Step 2: Create a feature flag
Use the feature flags creation UI to bootstrap your first feature flag. By default, the flag is disabled in all environments.

Step 3: Evaluate the flag and write feature code
In your application code, use the SDK to evaluate the flag and gate the new feature.

import { OpenFeature } from '@openfeature/web-sdk';

const client = OpenFeature.getClient();

// If applicable, set relevant attributes on the client's global context
// (e.g. org id, user email)
await OpenFeature.setContext({
   org: { id: 2 },
   user: { id: 'user-123', email: 'user@example.com' },
   targetingKey: 'user-123',
});

// This is what the SDK returns if the flag is disabled in
// the current environment
const fallback = false;

const showFeature = await client.getBooleanValue('show-new-feature', fallback);
if (showFeature) {
   // Feature code here
}
After you’ve completed this step, redeploy the application to pick up these changes. Additional usage examples can be found in the SDK’s documentation.

Step 4: Define targeting rules and enable the feature flag
Now that the application is ready to check the value of your flag, you can start adding targeting rules. Targeting rules enable you to define where or to whom to serve different variants of your feature.

Go to Feature Flags, select your flag, then find the Targeting Rules & Rollouts section. Select the environment whose rules you want to modify, and click Edit Targeting Rules.

Targeting Rules & Rollouts
Step 5: Publish the rules in your environments
After saving changes to the targeting rules, publish those rules by enabling your flag in the environment of your choice.

As a general best practice, changes should be rolled out in a Staging environment before rolling out in Production.
In the Targeting Rules & Rollouts section, toggle your selected environment to Enabled.

Publish targeting rules
The flag serves your targeting rules in this environment. You can continue to edit these targeting rules to control where the variants are served.

Step 6: Monitor your rollout
Monitor the feature rollout from the feature flag details page, which provides real-time exposure tracking and metrics such as error rate and page load time. As you incrementally release the feature with the flag, view the Real-Time Metric Overview panel in the Datadog UI to see how the feature impacts application performance.
```


## USE CONTEXT7
* use library id /datadog/browser-sdk
<!-- * use library id /datadog/dd-sdk-android-gradle-plugin -->

## OTHER CONSIDERATIONS:
* Append setup, deployment, verification, and cleanup steps in README-DATADOG-FEATURE-FLAG.md only after the above task is fully completed
* Explain the steps you would take in clear, beginner-friendly language
* Write the research on performing the task
* Save the research to `2-RESEARCH.md`
