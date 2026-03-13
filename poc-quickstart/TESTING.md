# Testing Guide — poc-quickstart

## Setup

Copy the `poc-quickstart/` folder to the test machine, then start Claude Code with:

```bash
claude --plugin-dir /path/to/poc-quickstart
```

---

## Test 1: SessionStart Hook — Auto Menu Display

**What to do:** Just start the session.

**Expected:**
- The 26-item Datadog PoC Quickstart menu displays automatically
- Items grouped by: Agent Setup, APM Instrumentation, Frontend Monitoring, Log Management, Cloud Integrations, Troubleshooting
- Shows "(Type "skip" to dismiss this menu.)" at the bottom

**Then:** Type `skip` to dismiss.

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Test 2: Command — Manual Menu

**What to do:** Type `/showing-menu`

**Expected:**
- Same menu displays again
- Clean format — one line per item, no internal action instructions shown

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Test 3: Menu Selection + MCP Prompt

**What to do:** Pick option `1` (Install the Agent on a host)

**Expected:**
- Asks: "Would you like me to connect to your Datadog account via MCP?"
- Say **no** — it should proceed in docs-only mode
- Asks follow-up questions (target OS, etc.)

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Test 4: Documentation Fetching

**What to do:** Continue the flow (say your OS, e.g., Linux)

**Expected:**
- Fetches `https://docs.datadoghq.com/llms.txt`
- Finds and fetches the Agent install page
- Walks you through installation steps using live docs

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Test 5: MCP Credential Flow

**What to do:** Pick another option (e.g., `23` — Troubleshoot the Agent). This time say **yes** to MCP.

**Expected:**
- Checks for `.env.datadog` in project root
- Since it doesn't exist, guides you to create it
- Asks for `DD_API_KEY`, `DD_APPLICATION_KEY`, `DD_SITE`
- Creates `.env.datadog` with `chmod 600`
- Verifies `.env.datadog` is in `.gitignore`

**Tip:** Use dummy values if you don't want real credentials — you're testing the flow.

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Test 6: TaskCompleted Hook — Documentation

**What to do:** Let a task reach completion.

**Expected:**
- Asks: "Would you like me to document the steps taken for this task to a PoC notes file?"
- Say **yes**
- Creates/appends to `./datadog-poc-notes.md` with:
  - Timestamp header
  - Tech stack (languages, versions, frameworks)
  - Steps taken
  - Problem (if any)
  - Solution
  - Limitations
- Each section: 1-3 bullet points, concise

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Test 7: SessionEnd Hook — Notes Review

**What to do:** End the session (`/exit` or Ctrl+C)

**Expected:**
- Asks: "Would you like me to review the PoC notes before ending this session?"
- Say **yes** — it reads `datadog-poc-notes.md` and suggests any missing info
- Say **no** — session ends cleanly

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Test 8: Security Verification

**What to do:** After all tests, run in terminal:

```bash
cat .gitignore | grep env.datadog
ls -la .env.datadog          # should show -rw------- permissions
git status                   # .env.datadog should NOT appear as untracked
```

**Result:** [ ] Pass / [ ] Fail / [ ] Partial

---

## Notes

Record any observations, errors, or suggestions here:

```




```
