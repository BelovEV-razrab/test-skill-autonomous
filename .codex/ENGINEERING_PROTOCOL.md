# AI-ENGINEERING PROTOCOL v1
Owner: Kuban
Purpose: Standardized autonomous development lifecycle for Codex in VS Code.

---

# OVERVIEW

This protocol defines the mandatory lifecycle for autonomous engineering.

All changes must follow:

CONTEXT → ANALYSIS → PLAN → IMPLEMENT → REVIEW → SHIP → LEARN

Codex must never skip phases.

---

# PHASE 0 — CONTEXT

Before starting any task, agent must:

- Read `.codex/CONTEXT.md`
- Read `.codex/RULES.md`
- Understand current milestone
- Identify project type (Node / Flutter / Python / other)

If context is unclear → STOP and request clarification.

---

# PHASE 1 — ANALYSIS

Agent must explicitly determine:

1. What files will be affected?
2. What dependencies may change?
3. Is this a breaking change?
4. Does this affect tests?
5. Does this affect architecture?
6. Does this introduce security risks?
7. Does this affect performance?

Output format:

[ANALYSIS]
- Affected files:
- Dependency impact:
- Breaking change risk:
- Test impact:
- Architecture impact:
- Security impact:
- Performance impact:

No implementation allowed before ANALYSIS is complete.

---

# PHASE 2 — PLAN

Agent must produce:

[PLAN]
1.
2.
3.

[RISKS]
-

[QUALITY CHECKS]
- tests required?
- lint required?
- build required?

[SHIP STRATEGY]
- branch name
- commit scope
- PR description summary

Plan must be approved (implicitly or explicitly) before implementation.

---

# PHASE 3 — IMPLEMENT

Rules:

- Minimal necessary change only
- No unrelated refactors
- Follow existing architecture
- Respect `.codex/RULES.md`
- Never expose secrets
- Never modify .env directly

All changes must be scoped.

---

# PHASE 4 — REVIEW

Before ship:

1. Re-run ANALYSIS mentally on diff
2. Ensure no secret leaks
3. Ensure no accidental large refactors
4. Ensure tests pass (if applicable)
5. Ensure lint/format pass (if applicable)

If quality fails → STOP.

---

# PHASE 5 — SHIP

Must use:

.\scripts\codex_ship.ps1 -Message "..."

Ship must:

- Create branch
- Run checks
- Commit
- Push
- Update memory
- Create PR

No direct push to main.

---

# PHASE 6 — LEARN

After ship:

- Update `.codex/TASKS.md`
- Update `.codex/DECISIONS.md`
- Update `.codex/CONTEXT.md` if architecture changed

System must retain memory.

---

# PROHIBITED

- Direct push to main
- Secret exposure
- Skipping PLAN phase
- Large refactor without explicit scope
- Silent dependency changes

---

# EVOLUTION

Future versions will include:

- Multi-agent orchestration
- Automated architecture analysis
- Release automation
- CI enforcement

Version: 1.0