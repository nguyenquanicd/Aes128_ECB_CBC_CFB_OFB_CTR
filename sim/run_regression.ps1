<#
.SYNOPSIS
  Regression of the AES-128 IP with Icarus Verilog (OSS CAD Suite) on Windows PowerShell.

.DESCRIPTION
  Builds the RTL (rtl/filelist.f) with every testbench of tb/ and simpleTestcase/ and runs them,
  including the golden-vector scenarios of vectors/ with several stress options.
  A run passes when its output contains "TEST_RESULT: PASS". The script exits with 1 if anything failed.

.PARAMETER OssCad
  Folder of the OSS CAD Suite (only used when iverilog is not already in PATH).
.PARAMETER Quick
  Skip the long vector file and the long random round-trip run.
.PARAMETER Only
  Run only the tests whose name matches this wildcard (e.g. "vec_nist*").
.PARAMETER TimeoutSec
  Wall-clock limit of one simulation (default 600 s).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File sim\run_regression.ps1 -Quick
#>
param(
  [string]$OssCad = 'C:\Tools\oss-cad-suite',
  [switch]$Quick,
  [string]$Only = '*',
  [int]$TimeoutSec = 600
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

if (-not (Get-Command iverilog -ErrorAction SilentlyContinue)) {
  $envps1 = Join-Path $OssCad 'environment.ps1'
  if (-not (Test-Path $envps1)) { throw "iverilog not found. Install the OSS CAD Suite or pass -OssCad <folder>." }
  . $envps1 2>&1 | Out-Null
}

$build = Join-Path $root 'sim\build'
New-Item -ItemType Directory -Force -Path $build | Out-Null

$results = New-Object System.Collections.ArrayList

function Invoke-Native([string]$exe, [string[]]$arguments, [string]$log) {
  # Windows PowerShell 5.1 turns native stderr into errors, so run through Start-Process and files.
  $p = Start-Process -FilePath $exe -ArgumentList $arguments -RedirectStandardOutput "$log.out" `
         -RedirectStandardError "$log.err" -PassThru -NoNewWindow
  if (-not $p.WaitForExit($TimeoutSec * 1000)) { try { $p.Kill() } catch {}; return $false }
  return $true
}

function Build-Tb([string]$top, [string[]]$sources, [string[]]$extra = @()) {
  $vvp = Join-Path $build "$top.vvp"
  $args_ = @('-g2012', '-Wall', '-Wno-timescale', '-Itb', '-Itb\ref', '-Isimple') + $extra + @('-s', $top, '-o', $vvp, '-c', 'rtl/filelist.f') + $sources
  $ok = Invoke-Native 'iverilog' $args_ (Join-Path $build "compile_$top")
  $errs = @(Get-Content (Join-Path $build "compile_$top.err") -ErrorAction SilentlyContinue |
            Where-Object { $_ -and $_ -notmatch 'constant selects in always_\*|the process will be sensitive|^\s*:' })
  if (-not $ok -or -not (Test-Path $vvp) -or ($errs | Where-Object { $_ -match 'error' })) {
    Write-Host "  COMPILE FAILED: $top" -ForegroundColor Red
    $errs | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" }
    return $null
  }
  return $vvp
}

function Run-Test([string]$name, [string]$vvp, [string[]]$plusargs = @()) {
  if ($name -notlike $Only) { return }
  $log = Join-Path $build ("run_" + ($name -replace '[^A-Za-z0-9_.-]', '_'))
  $t0 = Get-Date
  $done = Invoke-Native 'vvp' (@($vvp) + $plusargs) $log
  $sec = [int]((Get-Date) - $t0).TotalSeconds
  $out = @(Get-Content "$log.out" -ErrorAction SilentlyContinue)
  $res = $out | Where-Object { $_ -match '^TEST_RESULT:' } | Select-Object -Last 1
  $sum = $out | Where-Object { $_ -match '^SUMMARY' } | Select-Object -Last 1
  $status = 'FAIL'
  if (-not $done) { $status = 'TIMEOUT' } elseif ($res -match 'TEST_RESULT: PASS') { $status = 'PASS' }
  $short = if ($sum) { ($sum -replace '^SUMMARY [^:]*: ', '') } else { '' }
  [void]$results.Add([pscustomobject]@{ Test = $name; Status = $status; Sec = $sec; Detail = $short })
  $color = if ($status -eq 'PASS') { 'Green' } else { 'Red' }
  Write-Host ("  {0,-34} {1,-8} {2,4}s  {3}" -f $name, $status, $sec, $short) -ForegroundColor $color
  if ($status -ne 'PASS') { $out | Where-Object { $_ -match '^(FAIL|TIMEOUT|\[CHK\])' } | Select-Object -First 6 | ForEach-Object { Write-Host "      $_" } }
}

Write-Host "== AES-128 regression ($root) =="
Write-Host "-- build"
$chk = 'checker\aes128_protocol_checker.sv'
$prim  = Build-Tb 'tb_aes128_prim'       @('tb\tb_aes128_prim.sv')
$proto = Build-Tb 'tb_aes128_protocol'   @($chk, 'tb\tb_aes128_protocol.sv')
$rt    = Build-Tb 'tb_aes128_roundtrip'  @($chk, 'tb\tb_aes128_roundtrip.sv')
$vec   = Build-Tb 'tb_aes128_vec'        @($chk, 'tb\tb_aes128_vec.sv')
$simple = @{}
foreach ($m in 'ecb', 'cbc', 'cfb_cipher', 'cfb_decipher', 'ofb', 'ctr') {
  $simple[$m] = Build-Tb "tb_aes128_$m" @($chk, "simpleTestcase\tb_aes128_$m.sv") @('-IsimpleTestcase')
}

Write-Host "-- directed / unit"
if ($prim)  { Run-Test 'prim'      $prim }
if ($proto) { Run-Test 'protocol'  $proto }
Write-Host "-- constrained-random round trip"
if ($rt) {
  Run-Test 'roundtrip_seed1' $rt @('+N=300', '+SEED=1')
  Run-Test 'roundtrip_seed2' $rt @('+N=300', '+SEED=2')
  if (-not $Quick) { Run-Test 'roundtrip_seed3_long' $rt @('+N=1500', '+SEED=3') }
}
Write-Host "-- golden vectors"
if ($vec) {
  $files = 'nist', 'walk', 'patterns', 'cfb_segments', 'rand_s1', 'rand_s2', 'rand_s3', 'gap1', 'b2b', 'chain0', 'multikey'
  foreach ($f in $files) { Run-Test "vec_$f" $vec @("+VEC=vectors/$f.hex") }
  Write-Host "-- golden vectors + stress options"
  Run-Test 'vec_nist_junk'          $vec @('+VEC=vectors/nist.hex', '+JUNK=1')
  Run-Test 'vec_rand_s1_scr_all'    $vec @('+VEC=vectors/rand_s1.hex', '+SCR=31', '+JUNK=1')
  Run-Test 'vec_rand_s2_early_chain' $vec @('+VEC=vectors/rand_s2.hex', '+EARLY=3')
  Run-Test 'vec_rand_s3_stray_start' $vec @('+VEC=vectors/rand_s3.hex', '+MID=5')
  Run-Test 'vec_b2b_junk'           $vec @('+VEC=vectors/b2b.hex', '+JUNK=1')
  Run-Test 'vec_cfb_segments_cov'   $vec @('+VEC=vectors/cfb_segments.hex', '+COVCHK=0')
  if (-not $Quick) {
    Run-Test 'vec_long'             $vec @('+VEC=vectors/long.hex', '+COVCHK=1')
    Run-Test 'vec_long_all_stress'  $vec @('+VEC=vectors/long.hex', '+JUNK=1', '+SCR=31', '+EARLY=2', '+COVCHK=1')
  }
}
Write-Host "-- simpleTestcase (readable NIST examples)"
foreach ($m in 'ecb', 'cbc', 'cfb_cipher', 'cfb_decipher', 'ofb', 'ctr') {
  if ($simple[$m]) { Run-Test "simple_$m" $simple[$m] }
}

$bad = @($results | Where-Object { $_.Status -ne 'PASS' })
$compileFail = @($prim, $proto, $rt, $vec) + @($simple.Values) | Where-Object { -not $_ }
Write-Host ""
Write-Host ("== {0} tests, {1} passed, {2} failed, {3} testbench(es) did not compile ==" -f $results.Count, ($results.Count - $bad.Count), $bad.Count, @($compileFail).Count)
if ($bad.Count -gt 0 -or @($compileFail).Count -gt 0) { exit 1 }
exit 0
