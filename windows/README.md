# Humanize KR — Windows 포터블 (사용자 LLM 서버 연결)

폐쇄망/오프라인 환경에서, **이미 돌고 있는 OpenAI 호환 LLM 서버**에 붙어 한글
AI 티를 윤문하는 실행 경로입니다.

> **추론 서버와 GGUF/모델은 이 패키지에 포함되지 않습니다.**
> llama.cpp server·vLLM·LM Studio·Ollama 등 무엇이든 `/chat/completions` 를
> 제공하면 됩니다. 이 러너는 그 HTTP API 에 붙는 클라이언트일 뿐입니다.

---

## 1. 서버 요구 사항

아래 두 가지만 만족하면 됩니다.

- `POST {base}/v1/chat/completions` (또는 `{base}/chat/completions`) 응답
- 응답 본문의 `choices[0].message.content` 에 텍스트

`{base}` 예시:

| 서버 | `--api-base` 예 |
|---|---|
| LM Studio | `http://127.0.0.1:1234/v1` |
| vLLM | `http://127.0.0.1:8000/v1` |
| llama.cpp server | `http://127.0.0.1:8080/v1` |
| Ollama | `http://127.0.0.1:11434/v1` |

`--model` 에는 **서버가 인식하는 모델 id** 를 넣습니다(서버마다 다르므로 추측하지 않음).

---

## 2. 쓰는 법 (둘 중 하나)

### A. Python 이 있는 환경 — `humanize-korean.ps1`

```powershell
cd windows
.\humanize-korean.ps1 draft.txt -o final.md --api-base http://127.0.0.1:1234/v1 --model my-local-model
```

또는 환경변수로 고정:

```powershell
$env:OPENAI_BASE_URL = 'http://127.0.0.1:8000/v1'
$env:OPENAI_MODEL    = 'Qwen3-14B'
.\humanize-korean.ps1 draft.txt
```

`humanize-korean.bat` 은 `cmd.exe`에서 쓰는 래퍼입니다(인자는 그대로 전달).

### B. Python 이 없는 환경 — 포터블 exe

빌드 PC(Python + 인터넷)에서 한 번:

```powershell
cd windows
.\build-portable.ps1 -Zip
```

산출물: `dist\humanize-korean\humanize-korean.exe` (+ `README.md`·`LICENSE`, `-Zip` 이면 zip).
이 폴더를 폐쇄망 PC로 복사한 뒤:

```powershell
.\humanize-korean.exe draft.txt -o final.md --api-base http://127.0.0.1:1234/v1 --model my-local-model
```

exe 는 러너 자체라 인자 체계가 `.ps1` 경로와 완전히 같습니다.

---

## 3. 옵션

| 옵션 | 설명 |
|---|---|
| `input` (위치) | UTF-8 입력 파일 (필수) |
| `-o`, `--output` | 출력 경로 (기본: `<입력명>.humanized.md`) |
| `--api-base` | 서버 URL (또는 `OPENAI_BASE_URL`) |
| `--model` | 모델명 (또는 `OPENAI_MODEL`) |
| `--api-key-env` | 키를 읽을 환경변수 이름 (기본 `OPENAI_API_KEY`; 로컬 서버면 생략 가능) |
| `--genre` | `essay`·`column`·`report`·`blog`·`abstract`·`public` (기본 `essay`) |
| `--rules` | 룰북 경로 (기본: 동봉 `quick-rules.md`) |
| `--timeout` | 요청 제한 시간(초, 기본 600) |
| `--skip-gate` | 결정적 검증 게이트 생략 (비권장) |

---

## 4. 결과와 검증 (출력 위치)

윤문 본문은 출력 파일에 저장됩니다. 콘솔에는 저장 경로와 검증 결과가 표시됩니다. 마지막에 `scripts/verify_gates.py`
게이트가 **같은 프로세스에서** 돌아 종료 코드를 냅니다.

| 코드 | 의미 |
|---|---|
| `0` | 수렴 (전 축 통과) |
| `1` | 경고 (변경률 30~50% / 목표 미달 / 대구 전멸 / golden 실패 / 서법 감소) |
| `2` | 중단 (변경률 ≥ 50%) — 윤문본 채택 금지 |
| `3` | 실행 오류 (파일 없음·서버 연결 실패·게이트 로드 실패) |

---

## 5. 문제 해결

- **`Python 3 을 찾을 수 없습니다`** — python.org 에서 3.10+ 설치(설치 시 *Add python.exe to PATH* 체크) 또는 `build-portable.ps1` 로 exe 생성.
- **`API returned HTTP 404`** — `--api-base` 가 `/v1` 까지 포함됐는지 확인(`/v1/chat/completions` 로 조립됩니다).
- **`Could not reach API server`** — 서버가 떠 있는지, 방화벽/포트가 맞는지 확인.
- **`모델명이 없습니다`** — `--model`(또는 `OPENAI_MODEL`)은 서버가 아는 id 여야 합니다.
- **인코딩** — 러너는 파일을 항상 UTF-8 로 읽고 씁니다. 콘솔 한글 깨짐은
  `chcp 65001` 로 해결됩니다(`.bat` 은 자동 적용).
