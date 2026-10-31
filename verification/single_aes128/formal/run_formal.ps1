<#
.SYNOPSIS  Run the formal proofs of the AES-128 IP with SymbiYosys (OSS CAD Suite).
.PARAMETER OssCad  Folder of the OSS CAD Suite (used when sby is not in PATH).
#>
param([string]$OssCad = 'C:\Tools\oss-cad-suite', [int]$TimeoutSec = 600)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command sby -ErrorAction SilentlyContinue)) { . (Join-Path $OssCad 'environment.ps1') 2>&1 | Out-Null }
Set-Location $PSScriptRoot
$bad = 0
foreach ($t in 'fv_sbox', 'fv_keysched', 'fv_ctrl') {
  $t0 = Get-Date
  $p = Start-Process sby -ArgumentList @('-f', "$t.sby") -RedirectStandardOutput "$t.log" -RedirectStandardError "$t.err" -PassThru -NoNewWindow
  if (-not $p.WaitForExit($TimeoutSec * 1000)) { try { $p.Kill() } catch {}; $r = 'TIMEOUT' }
  else { $r = ((Get-Content "$t.log" | Where-Object { $_ -match 'DONE \(' } | Select-Object -Last 1) -replace '^.*DONE \((\w+).*$', '$1') }
  if ($r -ne 'PASS') { $bad++ }
  "{0,-12} {1,-8} {2,4}s" -f $t, $r, [int]((Get-Date) - $t0).TotalSeconds
}
exit $(if ($bad) { 1 } else { 0 })
