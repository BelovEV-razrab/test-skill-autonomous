# PROJECT ARCHITECTURE

## Root Structure

.codex/
.github/
docs/
scripts/

## Automation

scripts/codex_plan.ps1
scripts/codex_ship.ps1
scripts/codex_bootstrap.ps1

## CI

.github/workflows/ci.yml
.github/workflows/policy.yml

## Governance

.github/PULL_REQUEST_TEMPLATE.md
.github/ISSUE_TEMPLATE/
.github/CODEOWNERS

## Purpose

Autonomous AI Engineering System built around Codex in VS Code.

Main loop:

PLAN → IMPLEMENT → TEST → SHIP → PR → CI → MERGE

## Snapshot

    [DIR]  .codex
    [DIR]  .github
    [DIR]  docs
    [DIR]  scripts
    [FILE] .editorconfig
    [FILE] .gitattributes
    [FILE] .gitignore
    [FILE] package-lock.json
    [FILE] package.json
    [FILE] .codex\ARCHITECTURE.md
    [FILE] .codex\CONTEXT.md
    [FILE] .codex\DECISIONS.md
    [FILE] .codex\ENGINEERING_PROTOCOL.md
    [FILE] .codex\RULES.md
    [FILE] .codex\SKILLS.md
    [FILE] .codex\TASKS.md
    [DIR]  .github\ISSUE_TEMPLATE
    [DIR]  .github\workflows
    [FILE] .github\CODEOWNERS
    [FILE] .github\PULL_REQUEST_TEMPLATE.md
    [FILE] .github\ISSUE_TEMPLATE\bug_report.yml
    [FILE] .github\ISSUE_TEMPLATE\feature_request.yml
    [FILE] .github\workflows\ci.yml
    [FILE] .github\workflows\policy.yml
    [FILE] docs\DECISION_GLOBAL_SKILLS.md
    [FILE] scripts\codex_arch.ps1
    [FILE] scripts\codex_bootstrap.ps1
    [FILE] scripts\codex_plan.ps1
    [FILE] scripts\codex_ship.ps1
