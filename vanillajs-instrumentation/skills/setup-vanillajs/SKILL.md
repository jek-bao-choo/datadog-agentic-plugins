---
name: setup-vanillajs
description: Vite vanilla JavaScript app setup for a meter reading PoC
version_matrix:
  vite_version: [7.2]
---

# Setup Vanilla JS App

Set up a Vite-bundled vanilla JavaScript application for a meter reading proof-of-concept.

## Instructions

1. Initialize a new Vite project with the `vanilla` template.
2. Build a 3-page flow for meter reading submissions:
   - **Landing page** - Welcome screen with a "Submit Reading" call to action
   - **Enter Meter page** - Form to enter meter reading values
   - **Submitted page** - Confirmation screen showing the submitted reading
3. Design the app to be **mobile-responsive** (the primary use case is field workers on phones).
4. Apply a **utility company color theme** (e.g., blues, greens, professional palette).
5. Implement client-side routing or page transitions between the three views.
6. Verify the development server starts successfully with `npm run dev`.
