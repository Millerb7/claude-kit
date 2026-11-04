# Install claude-kit into ~/.claude/. Backs up anything it would overwrite.
$ErrorActionPreference = 'Stop'
$src   = $PSScriptRoot
$dest  = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

New-Item -ItemType Directory -Force -Path (Join-Path $dest 'agents')   | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dest 'commands') | Out-Null

$settings = Join-Path $dest 'settings.json'
if (Test-Path $settings) {
    Copy-Item $settings "$settings.bak-$stamp"
    Write-Host "backed up existing settings.json -> settings.json.bak-$stamp"
}
Copy-Item (Join-Path $src 'settings.json') $settings -Force
Write-Host "installed $settings"

Get-ChildItem (Join-Path $src 'agents') -Filter *.md | ForEach-Object {
    $target = Join-Path $dest "agents\$($_.Name)"
    if (Test-Path $target) { Copy-Item $target "$target.bak-$stamp" }
    Copy-Item $_.FullName $target -Force
    Write-Host "installed $target"
}

Get-ChildItem (Join-Path $src 'commands') -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
    $target = Join-Path $dest "commands\$($_.Name)"
    if (Test-Path $target) { Copy-Item $target "$target.bak-$stamp" }
    Copy-Item $_.FullName $target -Force
    Write-Host "installed $target"
}

Write-Host ""
Write-Host "Done. HOME=$HOME  DEST=$dest"
Write-Host "Copy CLAUDE.template.md into a repo as CLAUDE.md and fill it in."
Write-Host "If a sandbox ignores ~/.claude, launch with: claude --settings $settings"
