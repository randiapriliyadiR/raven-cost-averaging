# Compile Raven Cost Averaging.mq5 via MetaEditor.
# Exit 0 only when compile succeeds with 0 errors and .ex5 is produced.
# Usage: .\compile.ps1

$ErrorActionPreference = "Stop"

$MetaEditor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
$Mql5Root   = "C:\Users\randi\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
$Src        = Join-Path $PSScriptRoot "Raven Cost Averaging.mq5"
$Ex5        = Join-Path $PSScriptRoot "Raven Cost Averaging.ex5"
$Log        = Join-Path $PSScriptRoot "Raven Cost Averaging.log"

if (-not (Test-Path $MetaEditor)) {
  Write-Error "MetaEditor not found: $MetaEditor"
  exit 1
}
if (-not (Test-Path $Src)) {
  Write-Error "Source not found: $Src"
  exit 1
}

Remove-Item $Log -ErrorAction SilentlyContinue
$before = if (Test-Path $Ex5) { (Get-Item $Ex5).LastWriteTimeUtc } else { [datetime]::MinValue }

Write-Host "Compiling: $Src"
$p = Start-Process -FilePath $MetaEditor -ArgumentList @(
  "/compile:`"$Src`"",
  "/include:`"$Mql5Root`"",
  "/log"
) -PassThru -Wait

Start-Sleep -Milliseconds 500

if (-not (Test-Path $Log)) {
  Write-Error "Compile log not found. MetaEditor exit=$($p.ExitCode)"
  exit 1
}

$logText = Get-Content $Log -Raw -Encoding Unicode
Write-Host $logText

if ($logText -notmatch "Result:\s*0 errors") {
  Write-Error "Compile failed - fix errors before commit."
  exit 1
}

if (-not (Test-Path $Ex5)) {
  Write-Error "Compile reported success but .ex5 missing."
  exit 1
}

$after = (Get-Item $Ex5).LastWriteTimeUtc
if ($after -le $before) {
  Write-Error "Compile did not refresh .ex5 timestamp."
  exit 1
}

$ex5Len = (Get-Item $Ex5).Length
Write-Host ("COMPILE OK -> {0} ({1} bytes)" -f $Ex5, $ex5Len)
exit 0
