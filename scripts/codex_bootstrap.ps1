param(
  [Parameter(Mandatory=$false)][string]$RepoName = "",
  [Parameter(Mandatory=$false)][ValidateSet("public","private")][string]$Visibility = "private",
  [Parameter(Mandatory=$false)][switch]$CreateGithubRepo
)

$ErrorActionPreference = "Stop"

function Exec([string]$cmd) {
  Write-Host "`n> $cmd" -ForegroundColor Cyan
  $out = & powershell -NoProfile -Command $cmd 2>&1
  $code = $LASTEXITCODE
  if ($code -ne 0) { throw "Command failed ($code): $cmd`n$out" }
  return $out
}

Write-Host "`n=== CODEX BOOTSTRAP ===" -ForegroundColor Green

# Ensure tools
Exec "git --version"
Exec "gh --version"
Exec "gh auth status"

# Ensure git repo
$inside = (& git rev-parse --is-inside-work-tree 2>$null)
if ($LASTEXITCODE -ne 0) {
  Exec "git init"
}

# Create directories
if (!(Test-Path ".codex")) { New-Item ".codex" -ItemType Directory | Out-Null }
if (!(Test-Path "scripts")) { New-Item "scripts" -ItemType Directory | Out-Null }

# Create codex memory files
$files = @(
  ".codex/CONTEXT.md",
  ".codex/RULES.md",
  ".codex/SKILLS.md",
  ".codex/TASKS.md",
  ".codex/DECISIONS.md"
)
foreach ($f in $files) {
  if (!(Test-Path $f)) { New-Item $f -ItemType File | Out-Null }
}

# Seed RULES if empty
$rulesPath = ".codex/RULES.md"
if ((Get-Item $rulesPath).Length -eq 0) {
@"
# CODEX AUTONOMOUS DEVELOPMENT RULES

## Operating Mode
Codex may create/edit/delete files, install deps, run terminal commands, run tests, manage git, create branches, push, and open PRs.

## Safety
- Never commit secrets (.env is ignored; commit only .env.example)
- Prefer safe commands and explain risky operations

## Git
- No force-push
- Feature branches for changes
- Meaningful commits

## Memory
- Update .codex/TASKS.md and .codex/DECISIONS.md after ships
"@ | Set-Content -Encoding UTF8 $rulesPath
}

# Seed CONTEXT if empty
$ctxPath = ".codex/CONTEXT.md"
if ((Get-Item $ctxPath).Length -eq 0) {
@"
# PROJECT CONTEXT (Living Document)

## Purpose
Autonomous Codex-enabled repository.

## Environment
- OS: Windows
- Shell: PowerShell
- Git + GitHub CLI authenticated

## Workflow
- One command ship (tests/build -> commit -> push -> PR)
- Codex keeps project memory in .codex/
"@ | Set-Content -Encoding UTF8 $ctxPath
}

# Ensure .gitignore exists and has safe defaults
$gitignore = ".gitignore"
if (!(Test-Path $gitignore)) { New-Item $gitignore -ItemType File | Out-Null }
$gi = Get-Content $gitignore -Raw
$need = @(
  "# Secrets",
  ".env",
  ".env.*",
  "!.env.example"
)
foreach ($line in $need) {
  if ($gi -notmatch [regex]::Escape($line)) { Add-Content $gitignore $line }
}

# Ensure ship script exists
$ship = "scripts/codex_ship.ps1"
if (!(Test-Path $ship)) {
  throw "scripts/codex_ship.ps1 not found. Copy it from your template repo first."
}

# Optionally create GitHub repo and set origin
if ($CreateGithubRepo) {
  if ([string]::IsNullOrWhiteSpace($RepoName)) {
    $RepoName = (Split-Path (Get-Location) -Leaf)
  }

  # Check if origin already exists
  $remotes = (& git remote) -join "`n"
  if ($remotes -match "origin") {
    Write-Host "`nOrigin already exists. Skipping repo create." -ForegroundColor Yellow
  } else {
    $visFlag = if ($Visibility -eq "public") { "--public" } else { "--private" }
    Exec "gh repo create $RepoName $visFlag --source=. --remote=origin"
    Write-Host "`nGitHub repo created and origin set." -ForegroundColor Green
  }
}

Write-Host "`nBootstrap complete." -ForegroundColor Green
Write-Host "Next: run .\scripts\codex_ship.ps1 -Message `"Your change`"" -ForegroundColor Green