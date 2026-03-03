# PROJECT CONTEXT (Living Document)

## Purpose
This repository is a sandbox to configure and test an autonomous Codex workflow in VS Code:
- code generation
- dependency installation
- tests/build
- full git lifecycle (commit/push)
- PR creation via GitHub CLI
- self-documenting context files in .codex/

## Environment
- OS: Windows
- Shell: PowerShell
- Git: installed
- GitHub CLI: installed + authenticated
- Default git protocol: HTTPS

## Repo
- Remote: GitHub
- Branch strategy: main/master + feature branches

## Working Style
- One step at a time (user validates each step)
- Codex must prefer safe operations and explain risky changes

## Next Milestone
Enable a repeatable “Ship” flow:
1) implement change
2) run checks/tests
3) commit
4) push
5) open PR