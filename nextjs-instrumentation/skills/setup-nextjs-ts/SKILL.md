---
name: setup-nextjs-ts
description: Next.js 15.4 TypeScript App Router project setup
version_matrix:
  nextjs_version: [15.4]
---

# Setup Next.js TypeScript Project

Set up a Next.js 15.4 project using TypeScript with the App Router.

## Instructions

1. Initialize a new Next.js 15.4 project with TypeScript enabled.
2. Use the App Router (not Pages Router).
3. Configure `tsconfig.json` with strict mode.
4. Set up the project structure following Next.js App Router conventions:
   - `app/layout.tsx` - Root layout
   - `app/page.tsx` - Home page
   - `app/globals.css` - Global styles
5. Verify the development server starts successfully with `npm run dev`.
