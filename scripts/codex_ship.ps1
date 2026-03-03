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
  if ($code -ne 0) {
    throw "Command failed ($code): $cmd`n$out"
  }
  return $out
}

function TryExec([string]$cmd) {
  Write-Host "`n> $cmd" -ForegroundColor DarkCyan
  $out = & powershell -NoProfile -Command $cmd 2>&1
  return @{ Out = $out; Code = $LASTEXITCODE }
}

function FileAppend([string]$path, [string]$text) {
  if (!(Test-Path $path)) { New-Item $path -ItemType File | Out-Null }
  Add-Content -Path $path -Value $text
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
  if (!(Test-Path $p)) { New-Item $p -ItemType File | Out-Null }
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
if ($exists) {
  Exec "git switch $Branch"
} else {
  Exec "git switch -c $Branch"
}

# --- AUTO CHECKS (best-effort) ---
# If package managers exist, run common checks. Failures stop shipping.
if (Test-Path "package.json") {
  # install deps only if node_modules missing
  if (!(Test-Path "node_modules")) { Exec "npm install" }
  # prefer test if exists
  $t = TryExec "npm test"
  if ($t.Code -ne 0) {
    # some projects have no tests; try build/lint before failing
    $b = TryExec "npm run build"
    if ($b.Code -ne 0) { throw "npm test and npm run build failed. Aborting ship." }
  }
}
elseif (Test-Path "pubspec.yaml") {
  Exec "flutter pub get"
  $t = TryExec "flutter test"
  if ($t.Code -ne 0) {
    # try analyze
    $a = TryExec "flutter analyze"
    if ($a.Code -ne 0) { throw "flutter test/analyze failed. Aborting ship." }
  }
}
elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
  # You can add project-specific checks here later.
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

# Push (autoSetupRemote=true already enabled globally)
Exec "git push"

# Update memory files (append)
$now = (Get-Date).ToString("s")
FileAppend $tasks "`n- [$now] SHIPPED: $Message (branch: $Branch)"
FileAppend $decisions "`n- [$now] Ship decision: $Message (branch: $Branch)"

Exec "git add -A"
# commit memory updates separately (keeps history clean)
$memStatus = (Exec "git status --porcelain").Trim()
if (-not [string]::IsNullOrWhiteSpace($memStatus)) {
  Exec "git commit -m `"Update Codex memory after ship`""
  Exec "git push"
}

# --- PR CREATION (robust) ---
# First try gh pr create (may fail on some networks)
$pr = TryExec "gh pr create --fill --base $Base --head $Branch"
if ($pr.Code -eq 0) {
  Write-Host "`nPR created via gh." -ForegroundColor Green
  TryExec "gh pr view --web" | Out-Null
  exit 0
}

Write-Host "`nWARN: gh pr create failed. Falling back to web URL method." -ForegroundColor Yellow

# Build compare URL (always works)
$repoFull = (Exec "gh repo view --json nameWithOwner --jq .nameWithOwner").Trim()
$encodedHead = [System.Uri]::EscapeDataString($Branch)
$encodedBase = [System.Uri]::EscapeDataString($Base)
$url = "https://github.com/$repoFull/compare/$encodedBase...$encodedHead?expand=1"

Write-Host "`nOpen this URL to create PR:" -ForegroundColor Green
Write-Host $url

# Try open browser automatically
TryExec "start `"$url`"" | Out-Null