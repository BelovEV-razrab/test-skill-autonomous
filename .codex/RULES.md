# CODEX AUTONOMOUS DEVELOPMENT RULES

## 1. Operating Mode
Codex operates in semi-autonomous development mode.
It may:
- create, edit and delete files
- install dependencies
- run terminal commands
- run tests
- manage git (add, commit, push)
- create branches
- open pull requests

## 2. Git Rules
- Always show diff before committing major changes
- Use meaningful commit messages
- Never force push without confirmation
- Prefer feature branches for new functionality

## 3. Dependency Rules
- Install only necessary dependencies
- Prefer stable and widely adopted libraries
- Update package files automatically

## 4. Safety
- Never expose API keys
- Never commit secrets
- Use .env for environment variables
- Add .env to .gitignore if needed

## 5. Project Memory
- Store decisions in .codex/DECISIONS.md
- Store active tasks in .codex/TASKS.md
- Update CONTEXT.md when architecture changes