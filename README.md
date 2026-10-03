# Humanize Korean for Pi

폐쇄망에서 사용하는 **Pi 코딩 에이전트용 한국어 윤문 스킬**입니다. AI 초안의 번역투·상투구·기계적인 문장 구조를 찾아 고치면서 사실, 수치, 인용과 글의 격식을 보존하도록 안내합니다.

## 준비할 것

- Pi 코딩 에이전트
- Python 3.12
- Pi에서 접근할 수 있는 폐쇄망 LLM

스킬과 Python 스크립트는 인터넷이나 pip 설치 없이 사용할 수 있습니다. **LLM이나 추론 서버는 포함되지 않습니다.** Pi에 사용할 모델을 먼저 설정해야 합니다.

## 설치

[v2.4.1 릴리스](https://github.com/doha-230/im-not-ai/releases/tag/v2.4.1)에서 [`pi-humanize-korean-v2.4.1.zip`](https://github.com/doha-230/im-not-ai/releases/download/v2.4.1/pi-humanize-korean-v2.4.1.zip)을 받아 폐쇄망 PC로 옮깁니다. Windows PowerShell에서 ZIP이 있는 폴더로 이동해 실행합니다.

```powershell
Expand-Archive .\pi-humanize-korean-v2.4.1.zip -DestinationPath "$HOME\.pi\agent\skills" -Force
```

`$HOME\.pi\agent\skills\humanize-korean\SKILL.md`가 생기면 Pi에서 `/reload`하거나 다시 시작합니다. 프로젝트에만 설치하려면 압축을 프로젝트의 `.pi\skills` 폴더에 풉니다. 자세한 내용은 [INSTALL.txt](INSTALL.txt)에 있습니다.

## 사용

```text
/skill:humanize-korean draft.txt
```

또는 Pi에 “이 한국어 글의 AI 티를 자연스럽게 고쳐줘”라고 요청합니다. 스킬은 원문의 상태에 따라 `light`, `standard`, `heavy` 경로를 선택하고, 윤문 뒤 Python 검증 게이트를 실행합니다. 변경률 30% 이상은 경고, 50% 이상은 결과 채택을 중단합니다.

기본 경로는 **Pi에 설정된 모델**을 사용합니다. 이미 OpenAI 호환 로컬 서버를 운영한다면 [단일 호출 실행기](humanize-korean/scripts/local_runner.py)를 별도로 사용할 수 있습니다. 실행기는 지정한 서버로만 HTTP 요청을 보냅니다.

## 저장소 구성

- [humanize-korean/SKILL.md](humanize-korean/SKILL.md): Pi의 윤문 절차와 품질 원칙
- `humanize-korean/scripts/`: 입력 점수 산출, 청크 재조립, 사후 검증, 선택적 로컬 서버 실행
- `humanize-korean/skills/humanize-korean/references/`: 윤문 규칙, 진단 규칙, 지표와 역할 지침
- [INSTALL.txt](INSTALL.txt): 압축 파일 설치 안내

현재 `main`은 Pi 스킬과 설치 안내만 담고 있습니다. 이전 릴리스와 Git 이력은 보관되어 있습니다. 라이선스는 [MIT](humanize-korean/LICENSE)입니다.
