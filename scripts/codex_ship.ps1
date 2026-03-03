param(
  [Parameter(Mandatory=$true)][string]$Message,
  [Parameter(Mandatory=$false)][string]$Branch = ""
)

$ErrorActionPreference = "Stop"

function Exec($cmd) {
  Write-Host "`n> $cmd" -ForegroundColor Cyan
  iex $cmd
}

# Ensure git repo
Exec "git rev-parse --is-inside-work-tree | Out-Null"

# Ensure gh auth
Exec "gh auth status | Out-Null"

# Determine current branch
$currentBranch = (git branch --show-current).Trim()
if ([string]::IsNullOrWhiteSpace($currentBranch)) { $currentBranch = "master" }

# Create/switch branch if requested
if (-not [string]::IsNullOrWhiteSpace($Branch)) {
  $exists = (git branch --list $Branch).Length -gt 0
  if ($exists) {
    Exec "git switch $Branch"
  } else {
    Exec "git switch -c $Branch"
  }
  $currentBranch = $Branch
}

# Show status
Exec "git status"

# Add all changes
Exec "git add -A"

# If nothing to commit, exit
$status = (git status --porcelain)
if ([string]::IsNullOrWhiteSpace($status)) {
  Write-Host "`nNo changes to commit. Exiting." -ForegroundColor Yellow
  exit 0
}

# Commit
Exec "git commit -m `"$Message`""

# Push (set upstream if needed)
try {
  Exec "git push"
} catch {
  Exec "git push -u origin $currentBranch"
}

# Create PR (only if not default branch)
$defaultBranch = (gh repo view --json defaultBranchRef --jq .defaultBranchRef.name).Trim()
if ($currentBranch -ne $defaultBranch) {
  # If PR already exists, do nothing
  $existing = ""
  try {
    $existing = (gh pr view --json number --jq .number) 2>$null
  } catch { }

  if ([string]::IsNullOrWhiteSpace($existing)) {
    Exec "gh pr create --fill"
    Exec "gh pr view --web"
  } else {
    Write-Host "`nPR already exists for this branch (#$existing). Opening..." -ForegroundColor Green
    Exec "gh pr view --web"
  }
} else {
  Write-Host "`nOn default branch '$defaultBranch' — PR not created." -ForegroundColor Yellow
}