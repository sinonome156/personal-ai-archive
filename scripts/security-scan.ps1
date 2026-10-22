# security-scan.ps1 - scan repo files for leaked credentials and employer-identifying PII.
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/security-scan.ps1            # scan all tracked files
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/security-scan.ps1 -Staged    # scan staged files (pre-commit)
# Exit code 1 if any hit -> blocks the commit.
# ASCII-only logic. Real blocklist terms live in .pii-blocklist.local.txt (gitignored, never committed).
param(
  [switch]$Staged,
  [string]$RepoRoot = (Get-Location).Path
)
$ErrorActionPreference = 'Stop'
Set-Location $RepoRoot

if ($Staged) {
  $files = git diff --cached --name-only --diff-filter=ACM
} else {
  $files = git ls-files
}
$files = $files | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }

# built-in credential / secret signatures (do NOT require user data)
$secretRegex = @(
  'gho_[A-Za-z0-9]{10,}',
  'ghp_[A-Za-z0-9]{10,}',
  'ghu_[A-Za-z0-9]{10,}',
  'ghs_[A-Za-z0-9]{10,}',
  'github_pat_[A-Za-z0-9_]{10,}',
  'AKIA[0-9A-Z]{16}',
  '-----BEGIN [A-Z ]*PRIVATE KEY-----',
  'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{6,}',
  '(?i)(passwor[d]|passwd|secret|client[_-]?secret|api[_-]?key|access[_-]?token|auth[_-]?token|private[_-]?key)\s*[:=]\s*[\x27\x22]?[A-Za-z0-9._\-]{12,}',
  '\b\d{17}[\dXx]\b',            # CN national ID
  '\b\d{16,19}\b'                # bank card length range (may false-positive; tune per repo)
)

# user/employer terms from the LOCAL gitignored blocklist (if present)
$blockTerms = @()
$blockFile = Join-Path $RepoRoot '.pii-blocklist.local.txt'
if (Test-Path -LiteralPath $blockFile) {
  $blockTerms = Get-Content -LiteralPath $blockFile -Encoding UTF8 |
    Where-Object { $_ -and (-not $_.StartsWith('#')) }
}
Write-Output ('scanning ' + $files.Count + ' file(s); ' + $blockTerms.Count + ' local PII term(s) loaded')

$hits = @()
foreach ($f in $files) {
  $lines = Get-Content -LiteralPath $f -Encoding UTF8
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = [string]$lines[$i]
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    foreach ($rx in $secretRegex) {
      if ($line -match $rx) { $hits += ('SECRET  ' + $f + ':' + ($i+1) + '  ~ ' + $rx) }
    }
    foreach ($t in $blockTerms) {
      if ($line -like ('*' + $t + '*')) { $hits += ('PII     ' + $f + ':' + ($i+1) + '  term=' + $t) }
    }
  }
}

if ($hits.Count -gt 0) {
  $hits | Select-Object -Unique | ForEach-Object { Write-Output ('BLOCKED: ' + $_) }
  Write-Output ('scan FAILED: ' + ($hits | Select-Object -Unique).Count + ' unique hit(s). Generalize or remove before commit.')
  exit 1
}
Write-Output 'scan OK: no credential / PII hits'
exit 0
