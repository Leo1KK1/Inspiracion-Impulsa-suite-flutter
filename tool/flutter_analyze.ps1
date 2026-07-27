[CmdletBinding()]
param(
  [switch]$NoPub
)

$ErrorActionPreference = 'Stop'

$projectPath = Split-Path -Parent $PSScriptRoot
$projectName = Split-Path -Leaf $projectPath
$projectParent = Split-Path -Parent $projectPath
$flutterCommand = (Get-Command flutter.bat -ErrorAction Stop).Source
$mappedDrive = $null

foreach ($letter in 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P') {
  $candidate = "${letter}:"
  if (-not (Test-Path "${candidate}\")) {
    $mappedDrive = $candidate
    break
  }
}

if ($null -eq $mappedDrive) {
  throw 'No hay una letra de unidad temporal disponible entre I: y P:.'
}

try {
  & subst.exe $mappedDrive $projectParent
  if ($LASTEXITCODE -ne 0) {
    throw "No fue posible crear la unidad temporal $mappedDrive."
  }

  Push-Location "${mappedDrive}\${projectName}"
  try {
    $arguments = @('analyze')
    if ($NoPub) {
      $arguments += '--no-pub'
    }
    & $flutterCommand @arguments
    $analysisExitCode = $LASTEXITCODE
  }
  finally {
    Pop-Location
  }
}
finally {
  if ($null -ne $mappedDrive) {
    & subst.exe $mappedDrive /D
  }
}

exit $analysisExitCode
