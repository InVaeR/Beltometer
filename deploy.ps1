$src = Split-Path -Parent $MyInvocation.MyCommand.Path
$dst = "$env:APPDATA\Factorio\mods\Beltometer"

if (Test-Path -LiteralPath $dst) {
  Remove-Item -LiteralPath $dst -Recurse -Force
}

New-Item -ItemType Directory -Path $dst -Force | Out-Null

Get-ChildItem -LiteralPath $src -Exclude '.git','.gitignore','deploy.ps1' | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $dst -Recurse -Force
}

Write-Host "Deployed to $dst"
