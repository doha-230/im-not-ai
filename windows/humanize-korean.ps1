#Requires -Version 5.1
<#
.SYNOPSIS
  Humanize KR 러너 실행기 — 이미 돌고 있는 OpenAI 호환 서버에 붙어 한글을 윤문합니다.

.DESCRIPTION
  추론 서버와 GGUF/모델 파일은 이 패키지에 들어 있지 않습니다. 사용자가 이미
  띄워 둔 OpenAI 호환 `/chat/completions` 서버를 `--api-base`(또는
  `OPENAI_BASE_URL`)와 `--model`(또는 `OPENAI_MODEL`)로 가리키면 됩니다.

  이 실행기는 **Python 3.10+ 가 설치된 소스 체크아웃**용입니다. Python 없이
  쓰려면 `windows\build-portable.ps1` 로 exe 를 만들어 그 exe 를 직접 실행하세요
  (그 exe 는 러너 자체라 인자 체계가 동일합니다).

.EXAMPLE
  .\humanize-korean.ps1 draft.txt -o final.md --api-base http://127.0.0.1:1234/v1 --model my-local-model

.EXAMPLE
  $env:OPENAI_BASE_URL = 'http://127.0.0.1:8000/v1'
  $env:OPENAI_MODEL = 'Qwen3-14B'
  .\humanize-korean.ps1 draft.txt
#>

# 주의: param() 블록을 두지 않는다. 넘겨줄 인자는 러너의 것(-o, --api-base …)
# 이므로, 스크립트가 자기 파라미터로 바인딩하려 들면 "이름과 일치하는 파라미터가
# 없습니다"로 죽는다. param() 없는 스크립트는 전달받은 토큰을 $args 로 그대로 받는다.
$ErrorActionPreference = "Stop"

# 한국어 Windows 콘솔(cp949)에서 한글이 깨지지 않도록 출력 인코딩을 UTF-8 로 맞춘다.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
try { $OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$root   = Split-Path -Parent $PSScriptRoot          # windows\ → 리포 루트
$runner = Join-Path $root "scripts\local_runner.py"

if (-not (Test-Path -LiteralPath $runner)) {
    Write-Host "러너를 찾을 수 없습니다: $runner" -ForegroundColor Red
    Write-Host "이 스크립트는 리포지터리의 windows\ 안에 있어야 합니다." -ForegroundColor DarkGray
    exit 3
}

# ── 실행기 선택 ─────────────────────────────────────────────────────
$pythonExe    = $null
$pythonPrefix = @()
$py = Get-Command py -ErrorAction SilentlyContinue
if ($py) { $pythonExe = $py.Source; $pythonPrefix = @("-3") }
else {
    foreach ($name in @("python", "python3")) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) { $pythonExe = $found.Source; break }
    }
}
if (-not $pythonExe) {
    Write-Host "Python 3 을 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "  · 소스 실행: https://www.python.org 에서 Python 3.10+ 설치" -ForegroundColor DarkGray
    Write-Host "    (설치 화면에서 'Add python.exe to PATH' 체크)" -ForegroundColor DarkGray
    Write-Host "  · 또는 windows\build-portable.ps1 로 Python이 필요 없는 exe 를 만드세요." -ForegroundColor DarkGray
    exit 3
}

# ── 서버 접속 기본값 ────────────────────────────────────────────────
# 서버·모델은 사용자 몫이다. 여기서는 흔한 로컬 서버 기본 포트만 안내하고,
# 모델명은 서버마다 달라 추측하지 않고 명시 요구한다.
$rawArgs  = ($args -join " ")
$hasBase  = $rawArgs -match '(^|\s)--api-base(=|\s|$)'
$hasModel = $rawArgs -match '(^|\s)--model(=|\s|$)'
$wantsHelp = ($args -contains "--help") -or ($args -contains "-h")

if (-not $wantsHelp -and -not $hasBase -and [string]::IsNullOrWhiteSpace($env:OPENAI_BASE_URL)) {
    $env:OPENAI_BASE_URL = "http://127.0.0.1:1234/v1"
    Write-Host "[기본값] OPENAI_BASE_URL=$($env:OPENAI_BASE_URL) — 다르면 --api-base 로 지정하세요." -ForegroundColor DarkGray
    Write-Host "         (LM Studio 1234 · vLLM 8000 /v1 · llama.cpp server 8080 /v1 · Ollama 11434 /v1)" -ForegroundColor DarkGray
}
if (-not $wantsHelp -and -not $hasModel -and [string]::IsNullOrWhiteSpace($env:OPENAI_MODEL)) {
    Write-Host "모델명이 없습니다. --model 또는 OPENAI_MODEL 로 서버가 인식하는 모델 id 를 지정하세요." -ForegroundColor Red
    Write-Host "  예: .\humanize-korean.ps1 draft.txt --model Qwen3-14B" -ForegroundColor DarkGray
    exit 2
}

Push-Location $root
try {
    & $pythonExe @pythonPrefix $runner @args
    $code = $LASTEXITCODE
} finally {
    Pop-Location
}
if ($null -eq $code) { $code = 1 }
exit $code
