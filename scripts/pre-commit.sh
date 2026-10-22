#!/bin/sh
# Block commits that leak credentials or employer-identifying PII.
# Requires .pii-blocklist.local.txt at repo root for employer terms (gitignored).
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/security-scan.ps1" -Staged
exit $?
