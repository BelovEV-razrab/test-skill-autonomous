param(
  [Parameter(Mandatory=$true)][string]$Message,
  [Parameter(Mandatory=$false)][string]$Branch = "",
  [Parameter(Mandatory=$false)][string]$Base = ""   # optional override (main/master)
)

$ErrorActionPreference = "Stop"

function Exec([string]$cmd) {
  Write-Host "`n> $cmd" -ForegroundColor Cyan
  $out = & powershell -NoProfile -Command $cmd 2>&1
  $code = $LASTEXITCODE
  if ($code -ne 0) { throw "Command failed ($code): $cmd`n$out" }
  return $out
}

function TryExec([string]$cmd) {
  Write-Host "`n> $cmd" -ForegroundColor DarkCyan
  $out = & powershell -NoProfile -Command $cmd 2>&1
  return @{ Out = $out; Code = $LASTEXITCODE }
}

function FileAppend([string]$path, [string]$text) {
  if (!(Test-Path $path)) { New-Item $path -ItemType File -Force | Out-Null }
  Add-Content -Path $path -Value $text
}

function Get-JsonFile([string]$path) {
  if (!(Test-Path $path)) { return $null }
  try { return (Get-Content -Path $path -Raw | ConvertFrom-Json) }
  catch { throw "Failed to parse JSON: $path" }
}

function Require-NodeQualityGates {
    # QUALITY ENFORCEMENT v1.1 (Node):
    # - package.json -> scripts.test REQUIRED
    # - if scripts.lint exists -> MUST PASS
    # - if scripts.build exists -> MUST PASS
    # - if Prettier detected -> prettier --check . REQUIRED
  
    if (!(Test-Path "package.json")) { return }
  
    $pkg = Get-JsonFile "package.json"
    if ($null -eq $pkg) { throw "QUALITY GATE FAILED: package.json exists but could not be read." }
  
    $scripts = $pkg.scripts
  
    $hasTest = ($null -ne $scripts) -and ($null -ne $scripts.test) -and ($scripts.test.ToString().Trim().Length -gt 0)
    if (-not $hasTest) {
      throw "QUALITY GATE FAILED: package.json found but scripts.test is missing. Add a `"test`" script to package.json before shipping."
    }
  
    # Run test first (required)
    $t = TryExec "npm test"
    if ($t.Code -ne 0) {
      throw "QUALITY GATE FAILED: npm test failed. Fix tests before shipping."
    }
  
    # Lint if present
    $hasLint = ($null -ne $scripts) -and ($null -ne $scripts.lint) -and ($scripts.lint.ToString().Trim().Length -gt 0)
    if ($hasLint) {
      $l = TryExec "npm run lint"
      if ($l.Code -ne 0) { throw "QUALITY GATE FAILED: npm run lint failed. Fix lint before shipping." }
    }
  
    # Build if present
    $hasBuild = ($null -ne $scripts) -and ($null -ne $scripts.build) -and ($scripts.build.ToString().Trim().Length -gt 0)
    if ($hasBuild) {
      $b = TryExec "npm run build"
      if ($b.Code -ne 0) { throw "QUALITY GATE FAILED: npm run build failed. Fix build before shipping." }
    }
  
    # Prettier detect (config or dependency)
    $prettierConfigExists =
      (Test-Path ".prettierrc") -or (Test-Path ".prettierrc.json") -or (Test-Path ".prettierrc.yml") -or (Test-Path ".prettierrc.yaml") -or
      (Test-Path ".prettierrc.js") -or (Test-Path ".prettierrc.cjs") -or (Test-Path "prettier.config.js") -or (Test-Path "prettier.config.cjs")
  
    $deps = $pkg.dependencies
    $devDeps = $pkg.devDependencies
    $hasPrettierDep =
      (($null -ne $deps) -and ($null -ne $deps.prettier)) -or
      (($null -ne $devDeps) -and ($null -ne $devDeps.prettier))
  
    if ($prettierConfigExists -or $hasPrettierDep) {
      # Use npx so local prettier is preferred, but it still works if installed.
      $p = TryExec "npx prettier --check ."
      if ($p.Code -ne 0) { throw "QUALITY GATE FAILED: prettier --check failed. Run prettier to format before shipping." }
    }
  }

# Ensure in git repo
Exec "git rev-parse --is-inside-work-tree"

# Ensure gh auth
Exec "gh auth status"

# Ensure codex memory files exist
if (!(Test-Path ".codex")) { New-Item ".codex" -ItemType Directory | Out-Null }
$ctx = ".codex/CONTEXT.md"
$rules = ".codex/RULES.md"
$skills = ".codex/SKILLS.md"
$tasks = ".codex/TASKS.md"
$decisions = ".codex/DECISIONS.md"
foreach ($p in @($ctx,$rules,$skills,$tasks,$decisions)) {
  if (!(Test-Path $p)) { New-Item $p -ItemType File -Force | Out-Null }
}

# Detect default/base branch
$defaultBranch = (Exec "gh repo view --json defaultBranchRef --jq .defaultBranchRef.name").Trim()
if ([string]::IsNullOrWhiteSpace($Base)) { $Base = $defaultBranch }

# Determine branch: if not provided, create deterministic branch name
if ([string]::IsNullOrWhiteSpace($Branch)) {
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($Message.ToLower() -replace '[^a-z0-9]+','-').Trim('-')
  if ($safe.Length -gt 40) { $safe = $safe.Substring(0,40) }
  $Branch = "feat/$ts-$safe"
}

# Switch/create branch
$exists = (TryExec "git show-ref --verify --quiet refs/heads/$Branch").Code -eq 0
if ($exists) { Exec "git switch $Branch" }
else { Exec "git switch -c $Branch" }

# --- SECRET GUARDRAIL (hard fail) ---
$changedEnv = (& git status --porcelain) | Select-String -Pattern '\.env' -SimpleMatch
if ($changedEnv) { throw "Refusing to ship: .env changes detected. Commit only .env.example." }

$secretPatterns = @(
  'AKIA[0-9A-Z]{16}',
  'ghp_[A-Za-z0-9_]{20,}',
  'github_pat_[A-Za-z0-9_]{20,}',
  'sk-[A-Za-z0-9]{20,}',
  '-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----',
  'xox[baprs]-[A-Za-z0-9-]{10,}',
  'AIza[0-9A-Za-z\-_]{35}'
)
$diffText = (& git diff) -join "`n"
foreach ($p in $secretPatterns) {
  if ($diffText -match $p) { throw "Refusing to ship: possible secret detected in git diff (pattern: $p)." }
}

# --- AUTO CHECKS (best-effort) ---
if (Test-Path "package.json") {
  # === QUALITY GATES (pre-checks) ===
  Require-NodeQualityGates

  if (!(Test-Path "node_modules")) { Exec "npm install" }
  Require-NodeQualityGates
}
elseif (Test-Path "pubspec.yaml") {
  Exec "flutter pub get"
  $t = TryExec "flutter test"
  if ($t.Code -ne 0) {
    $a = TryExec "flutter analyze"
    if ($a.Code -ne 0) { throw "flutter test/analyze failed. Aborting ship." }
  }
}
elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
  Write-Host "`nPython project detected (no automatic venv actions by default)." -ForegroundColor Yellow
}

# Stage & commit
Exec "git add -A"
$status = (Exec "git status --porcelain").Trim()
if ([string]::IsNullOrWhiteSpace($status)) {
  Write-Host "`nNo changes to commit. Exiting." -ForegroundColor Yellow
  exit 0
}

Exec "git commit -m `"$Message`""
Exec "git push"

# Update memory files (append)
$now = (Get-Date).ToString("s")
FileAppend $tasks "`n- [$now] SHIPPED: $Message (branch: $Branch)"
FileAppend $decisions "`n- [$now] Ship decision: $Message (branch: $Branch)"

Exec "git add -A"
$memStatus = (Exec "git status --porcelain").Trim()
if (-not [string]::IsNullOrWhiteSpace($memStatus)) {
  Exec "git commit -m `"Update Codex memory after ship`""
  Exec "git push"
}

# --- PR CREATION (robust) ---
$pr = TryExec "gh pr create --fill --base $Base --head $Branch"
if ($pr.Code -eq 0) {
  Write-Host "`nPR created via gh." -ForegroundColor Green
  TryExec "gh pr view --web" | Out-Null
  exit 0
}

Write-Host "`nWARN: gh pr create failed. Falling back to web URL method." -ForegroundColor Yellow
$repoFull = (Exec "gh repo view --json nameWithOwner --jq .nameWithOwner").Trim()
$encodedHead = [System.Uri]::EscapeDataString($Branch)
$encodedBase = [System.Uri]::EscapeDataString($Base)
$url = "https://github.com/$repoFull/compare/$encodedBase...$encodedHead?expand=1"

Write-Host "`nOpen this URL to create PR:" -ForegroundColor Green
Write-Host $url
TryExec "start `"$url`"" | Out-Null
