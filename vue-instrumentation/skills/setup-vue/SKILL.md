---
name: setup-vue
description: >-
  Use this skill whenever the user needs to build and run a Vue.js application for Datadog
  instrumentation. Triggers on mentions of Vue app setup, Vue 3 project, Vite Vue project,
  tradestocks app, or frontend app development for Datadog testing.
version: 0.1.0
version_matrix:
  vue: [3.5]
  vite: [7.1]
---

# Vue 3.5 + Vite 7.1 Application Setup

Build and run a Vue 3.5 tradestocks proof-of-concept application with Vite 7.1.

## Prerequisites

- Node.js 18+ installed
- npm available on PATH

## Instructions

The reference application is a mobile-responsive trading stocks app located in `references/`.

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

- `package.json` — Dependencies including Vue 3.5, Vite 7.1
- `vite.config.js` — Vite configuration with Vue plugin
- `src/main.js` — Application entry point
- `src/App.vue` — Main application component
- `src/components/` — TradingForm, StockDropdown, QuantityInput, BuyButton, BackButton, ResultPage
- `src/composables/useStockData.js` — Composable for stock data management
- `src/composables/useTradingAPI.js` — Composable for trading API integration
- `src/style.css` — Application styles

## Validation

```bash
# Install and start dev server
npm install && npm run dev

# Verify the app loads at http://localhost:5173
# Verify the trading form renders with stock dropdown
# Verify buy flow completes end-to-end
```

- App loads without console errors
- Trading form is interactive with stock selection
- Buy transaction flow completes successfully

## Troubleshooting

### npm install fails
**Cause:** Node.js version too old or network issue.
**Fix:** Ensure Node.js 18+ is installed (`node --version`). Clear npm cache with `npm cache clean --force`.

### Vite dev server fails to start
**Cause:** Port 5173 already in use or missing dependencies.
**Fix:** Kill the process on port 5173 or run with `--port 3000`. Re-run `npm install`.

### Blank page in browser
**Cause:** Build error or missing Vue plugin.
**Fix:** Check terminal for errors. Ensure `@vitejs/plugin-vue` is in devDependencies.
