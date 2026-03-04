
param(
  [string]$Output = ".codex/ARCHITECTURE.md"
)

Write-Host "Generating project tree snapshot..."

# Build tree (exclude .git and node_modules)
$items = Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object {
    $_.FullName -notmatch '\.git' -and
    $_.FullName -notmatch 'node_modules'
}

$tree = $items | ForEach-Object {
    $rel = $_.FullName.Replace((Get-Location).Path + '\', '')
    $rel = $rel.Replace((Get-Location).Path + '/', '')
    if ($_.PSIsContainer) { "[DIR]  $rel" } else { "[FILE] $rel" }
}

$treeText = $tree -join "`n"

# Markdown snapshot section
# Markdown snapshot section (safe: no backticks)
$snapshot = "## Snapshot`n`n    " + ($treeText -replace "`n", "`n    ")

# Read existing architecture doc or create a base
if (Test-Path $Output) {
  $content = Get-Content $Output -Raw
} else {
  $content = "# PROJECT ARCHITECTURE`n"
}

# Replace or append snapshot section
if ($content -match '## Snapshot') {
  $content = [regex]::Replace($content, '## Snapshot[\s\S]*$', $snapshot)
} else {
  $content = $content + "`n" + $snapshot
}

Set-Content -Path $Output -Value $content -Encoding UTF8
Write-Host "Architecture snapshot updated in $Output"