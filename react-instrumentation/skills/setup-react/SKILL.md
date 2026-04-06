---
name: setup-react
description: >-
  Use this skill whenever the user needs to build and run a React application for Datadog
  instrumentation. Triggers on mentions of React app setup, React 19 project, Vite React
  project, sendmoney app, or frontend app development for Datadog testing.
version: 0.1.0
version_matrix:
  react: [19.1]
  vite: [7.1]
---

# React 19.1 + Vite 7.1 Application Setup

Build and run a React 19.1 sendmoney proof-of-concept application with Vite 7.1.

## Prerequisites

- Node.js 18+ installed
- npm available on PATH

## Instructions

The reference application is a mobile-responsive sendmoney app located in `references/`.

### 1. Install dependencies

```bash
npm install
```

### 2. Start the development server

```bash
npm run dev
```

The app will start on `http://localhost:5173` by default.

### 3. Build for production

```bash
npm run build
npm run preview
```

## Reference Files

Key files in `references/`:

- `package.json` — Dependencies including React 19.1, Vite 7.1
- `vite.config.js` — Vite configuration with React plugin
- `src/main.jsx` — Application entry point
- `src/App.jsx` — Main application component
- `src/components/` — SendMoneyForm, PayeesList, AddPayeeModal, ResultPage, ScamAlertModal
- `src/services/mockApi.js` — Mock API for transaction simulation
- `src/hooks/useFeatureFlag.js` — Custom hook for feature flag integration
- `src/datadog-rum.js` — Datadog RUM initialization
- `src/datadog-feature-flags.js` — Datadog Feature Flags configuration

## Validation

```bash
# Install and start dev server
npm install && npm run dev

# Verify the app loads at http://localhost:5173
# Verify the sendmoney form renders
# Verify mock API endpoints respond (transaction submission)
```

- App loads without console errors
- SendMoney form is interactive
- Transaction flow completes end-to-end with mock API

## Troubleshooting

### npm install fails
**Cause:** Node.js version too old or network issue.
**Fix:** Ensure Node.js 18+ is installed (`node --version`). Clear npm cache with `npm cache clean --force`.

### Vite dev server fails to start
**Cause:** Port 5173 already in use or missing dependencies.
**Fix:** Kill the process on port 5173 or run with `--port 3000`. Re-run `npm install`.

### Blank page in browser
**Cause:** Build error or missing React plugin.
**Fix:** Check terminal for errors. Ensure `@vitejs/plugin-react` is in devDependencies.
