#Requires -Version 5.1
<#
.SYNOPSIS
  Python 설치 없이 실행되는 Windows 포터블 exe 를 만듭니다 (PyInstaller).

.DESCRIPTION
  추론 서버·GGUF/모델 파일은 만들지도, 넣지도 않습니다. 번들에는 러너 코드와
  룰북(`quick-rules.md`)·결정적 검증 스크립트만 들어갑니다. 사용자는 별도로
  돌고 있는 OpenAI 호환 서버를 exe 실행 시 `--api-base`/`--model` 로 가리킵니다.

  산출물
    -Mode onedir  → dist\<Name>\<Name>.exe (+ _internal\ 에 러너 자산)
    -Mode onefile → dist\<Name>.exe (실행마다 임시 폴더로 풀림)

.EXAMPLE
  .\build-portable.ps1
  .\build-portable.ps1 -Mode onefile -Zip
#>
param(
  [ValidateSet("onedir", "onefile")][string] $Mode = "onedir",
  [string] $Name = "humanize-korean",
  [switch] $Zip,
  [switch] $SkipInstall,
  [switch] $SkipSmoke
)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  if (-not $SkipInstall) {
    Write-Host "[1/4] PyInstaller 설치/확인…" -ForegroundColor Cyan
    python -m pip install --upgrade --disable-pip-version-check pyinstaller
    if ($LASTEXITCODE -ne 0) { throw "pip install pyinstaller 실패 (exit $LASTEXITCODE)" }
  }

  Write-Host "[2/4] 번들 빌드… ($Mode)" -ForegroundColor Cyan
  # 러너가 실행 시점에 경로로 import 하는 헬퍼(console·verify_gates·checks·metrics*)는
  # 일부러 동결하지 않는다(--exclude-module). 동결하면 __file__ 이 평탄화돼
  # verify_gates 의 루트 유도(scripts/ 기준 ../)가 어긋나고, 저장소 경로에 묶인
  # baseline JSON 을 못 찾아 P1/P3 축이 조용히 죽는다. 대신 --add-data 로 원본 .py
  # 를 데이터로 넣어 소스 실행과 **같은 경로 유도**를 유지한다.
  $pyiArgs = @(
    "--noconfirm", "--clean", "--console",
    "--$Mode",
    "--name", $Name,
    "--exclude-module", "console",
    "--exclude-module", "verify_gates",
    "--exclude-module", "checks",
    "--exclude-module", "metrics",
    "--exclude-module", "metrics_v2",
    # 데이터로 넣은 게이트 스크립트의 import 는 PyInstaller 가 정적 분석하지
    # 못한다. 이들이 쓰는 표준 라이브러리는 명시적으로 동결해야 한다.
    "--hidden-import", "difflib",
    "--hidden-import", "statistics",
    "--hidden-import", "dataclasses",
    "--hidden-import", "math",
    "--hidden-import", "traceback",
    # 서버·모델은 넣지 않는다. 러너 코드와 룰북 등 참조 자산만 넣는다.
    "--add-data", "scripts:scripts",
    "--add-data", "skills/humanize-korean/references:skills/humanize-korean/references",
    "scripts/local_runner.py"
  )
  python -m PyInstaller @pyiArgs
  if ($LASTEXITCODE -ne 0) { throw "PyInstaller 실패 (exit $LASTEXITCODE)" }

  $dist   = Join-Path $root "dist"
  $target = if ($Mode -eq "onefile") { Join-Path $dist "${Name}.exe" } else { Join-Path $dist $Name }
  $exePath = if ($Mode -eq "onefile") { $target } else { Join-Path $target "${Name}.exe" }
  if (-not (Test-Path -LiteralPath $exePath)) { throw "산출물이 없습니다: $exePath" }

  if (-not $SkipSmoke) {
    Write-Host "[3/4] 스모크 — exe --help (동봉 자산 인식 확인)" -ForegroundColor Cyan
    & $exePath --help | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "스모크 실행 실패 (exit $LASTEXITCODE)" }
  }

  $readmePath = Join-Path $root "windows/README.md"
  $licensePath = Join-Path $root "LICENSE"
  if ($Mode -eq "onedir") {
    Copy-Item -LiteralPath $readmePath -Destination (Join-Path $target "README.md") -Force
    Copy-Item -LiteralPath $licensePath -Destination (Join-Path $target "LICENSE") -Force
  }

  if ($Zip) {
    Write-Host "[4/4] zip 묶기…" -ForegroundColor Cyan
    $zipPath = Join-Path $dist "${Name}-windows-${Mode}.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    $archiveItems = if ($Mode -eq "onefile") { @($target, $readmePath, $licensePath) } else { @($target) }
    Compress-Archive -Path $archiveItems -DestinationPath $zipPath
    Write-Host "생성: $zipPath" -ForegroundColor Green
  }

  Write-Host "완료: $exePath" -ForegroundColor Green
  Write-Host "서버·모델은 포함되지 않았습니다 — 실행 시 --api-base / --model 로 사용자 서버를 가리키세요." -ForegroundColor DarkGray
}
finally {
  Pop-Location
}
