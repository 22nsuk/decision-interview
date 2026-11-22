# Decision Interview

[English](README.en.md) · [변경 사항](CHANGELOG.md) · [평가 방법](evals/README.md)

계획을 검토하다 보면 이미 정한 내용을 다시 묻거나, 중요한 선택을 남겨둔 채 세부사항으로 흐를 수 있습니다.
“질문해줘”라는 요청만으로는 무엇부터 묻고 언제 마칠지 충분히 정해지지 않습니다.
Decision Interview는 결과를 바꿀 미결정 사항과 그 선행 조건을 찾아 질문하는 독립 스킬입니다.
대화에서 정한 조건을 보존하고, 다음 행동에 필요한 만큼 명확해지면 결정과 남은 쟁점을 정리합니다.

## 핵심 동작

- 현재 대화와 지정 자료를 먼저 확인하고, 조사할 사실과 사용자가 정할 선택을 구분합니다.
- 여러 안건의 순서와 의존 관계를 유지하며 기본적으로 한 번에 한 질문을 합니다.
- 목적 탐색에는 열린 질문을, 구체적인 선택에는 대안과 절충을, 중요한 가정에는 사례와 반례를 사용합니다.
- 선택 질문에는 가능한 경우 호스트의 선택 UI를 쓰며, 번호·짧은 키워드·직접 입력으로 답할 수 있게 합니다.
- 확인된 결정·사실·제안·불확실성을 구분하고, 수치·단위·금지 조건·예외·순서를 보존합니다.
- 결정 변경의 영향을 받는 선택만 다시 살피고, 조건 충돌이나 불분명한 위임 범위는 필요한 부분만 확인합니다.
- 반복해서 보류되는 질문은 근거 수집이나 다음 행동으로 연결합니다. 요약과 인계문에는 자격 증명을 넣지 않고 필요한 개인정보만 남깁니다.

고정 질문 수, 모호성 점수, 필수 보조 에이전트, MCP 서버, 자동 파일 저장을 요구하지 않습니다.
스킬 본문은 영문이며 대화는 사용자의 언어를 따릅니다.

## 사용 예시

아이디어나 계획에 관해 **질문을 통한 논의를 원할 때** 사용합니다.
일반적인 사실 질문, 코드 리뷰, 이미 명확한 수정 작업을 긴 인터뷰로 전환하지 않습니다.
다른 작업으로 바꾸거나 중단을 요청하면 인터뷰 모드를 종료합니다.

### 아이디어 구체화

```text
$decision-interview 개인용 독서 기록 도구를 만들고 싶어.
어떤 불편을 해결할지부터 질문으로 구체화해줘.
```

### 계획 검토

```text
$decision-interview 첨부한 데이터 이전 계획을 질문으로 검토해줘.
특히 중단 시간과 실패 시 복구 조건을 살펴보고, 구현은 아직 하지 마.
```

### 깊이와 재량 지정

```text
$decision-interview 이 계획에서 결과를 바꿀 중요한 선택만 물어봐줘.
UI 세부사항은 맡길게. 답을 모르면 보류할 수 있게 해줘.
```

### 결정 변경 — 진행 중인 인터뷰에서

```text
아까 오프라인 전용으로 정한 결정을 바꾸고 싶어. 온라인 연결을 허용할게.
그 결정에 의존하던 저장 방식은 다시 보고, CSV 내보내기 조건은 유지해줘.
```

### 시간 제한과 종료 — 진행 중인 인터뷰에서

```text
인터뷰가 너무 길어. 질문은 여기서 마치고 핵심 결정과 미해결 사항만 정리해줘.
미해결 사항 때문에 어떤 다음 작업이 막히는지도 알려줘.
```

Claude Code에서는 시작 명령의 `$decision-interview`를 `/decision-interview`로 바꿉니다.
명령어 없는 “질문으로 내 계획을 검토해줘”는 **자연어 선택을 허용한 호스트 설정**에서 사용할 수 있습니다.
설치만으로 모든 호스트가 이 요청에 스킬을 선택한다고 가정하지 않습니다.

## 설치

설치할 단위는 [skills/decision-interview](skills/decision-interview) 폴더 전체입니다.
스킬 본체는 [SKILL.md](skills/decision-interview/SKILL.md)이며,
`agents/openai.yaml`에는 Codex의 표시 정보와 호출 정책이 들어 있습니다.
사용할 때 실행 스크립트나 개발용 패키지를 설치할 필요는 없습니다.

| 환경 | 프로젝트 범위 | 사용자 범위 | 직접 호출 |
|---|---|---|---|
| Codex CLI / IDE | `.agents/skills/decision-interview/` | `~/.agents/skills/decision-interview/` | `$decision-interview` |
| Claude Code | `.claude/skills/decision-interview/` | `~/.claude/skills/decision-interview/` | `/decision-interview` |

저장소를 내려받은 뒤, **저장소 루트에서** 다음 새 설치 명령 중 하나를 실행합니다.
기본 목적지는 사용자 범위의 Codex 폴더입니다. Claude Code는 `.agents`를 `.claude`로,
프로젝트 설치는 목적지를 해당 프로젝트의 경로로 바꿉니다.
Windows 네이티브와 WSL을 함께 사용한다면 도구를 실행하는 쪽에 설치합니다.

### Bash — macOS / Linux / WSL

```bash
(
  set -eu
  skill_parent="$HOME/.agents/skills"
  skill_target="$skill_parent/decision-interview"
  test -f skills/decision-interview/SKILL.md
  mkdir -p "$skill_parent"
  if [ -e "$skill_target" ] || [ -L "$skill_target" ]; then
    printf 'Already exists: %s\n' "$skill_target" >&2
    exit 1
  fi
  mkdir "$skill_target"
  cp -R skills/decision-interview/. "$skill_target/"
)
```

### PowerShell — Windows

```powershell
$ErrorActionPreference = "Stop"
$skillSource = Join-Path (Get-Location) "skills/decision-interview"
$skillTarget = Join-Path $HOME ".agents/skills/decision-interview"
if (-not (Test-Path -LiteralPath (Join-Path $skillSource "SKILL.md"))) {
    throw "Run this from the repository root."
}
if (Test-Path -LiteralPath $skillTarget) {
    throw "Already exists: $skillTarget"
}
New-Item -ItemType Directory -Path (Split-Path -Parent $skillTarget) -Force | Out-Null
New-Item -ItemType Directory -Path $skillTarget -ErrorAction Stop | Out-Null
Get-ChildItem -LiteralPath $skillSource -Force |
    Copy-Item -Destination $skillTarget -Recurse -ErrorAction Stop
```

두 명령은 기존 설치 폴더가 있으면 중단합니다. 복사 중 오류가 나면 새 목적지의 상태를 확인한 뒤 재시도합니다.

### 복사 후 확인과 업데이트

- 목적지 바로 아래에 `SKILL.md`와 `agents/openai.yaml`이 있고 폴더가 이중으로 중첩되지 않았는지 확인합니다.
- 호스트의 스킬 목록에서 이름과 경로를 확인하고, 같은 이름의 다른 설치본이 선택되지 않는지 살핍니다.
- 아래 호출 정책을 확인한 뒤 직접 호출해 사용합니다. 목록에 보이는 것과 실제 선택·동작은 별도로 확인합니다.
- 업데이트 전 [CHANGELOG.md](CHANGELOG.md)와 설치본의 차이를 확인합니다. 직접 수정한 내용과 호출 정책을 보존할지 정한 뒤 백업하고 교체합니다. 새 설치 명령은 업데이트 시 덮어쓰기를 수행하지 않습니다.

## 호출 정책

| 환경·설정 | 명령어 없는 요청으로 선택 | 직접 호출 |
|---|---|---|
| Codex 배포 기본값: `allow_implicit_invocation: false` | 허용하지 않습니다 | 허용합니다 |
| Codex에서 설치본을 `true`로 변경한 경우 | description에 따른 선택을 허용합니다 | 허용합니다 |
| Claude Code 개인·프로젝트 스킬: `on` 또는 override 없음 | description에 따른 선택을 허용합니다 | 허용합니다 |
| Claude Code: `user-invocable-only` | 허용하지 않습니다 | 허용합니다 |

Codex의 설정은 [agents/openai.yaml](skills/decision-interview/agents/openai.yaml)에 있습니다.
자연어 선택을 원하면 **설치한 사본에서** 해당 값을 `true`로 바꿀 수 있습니다.
배포 기본값은 명시적 호출을 유지합니다.

Claude Code의 `/skills` 메뉴에서는 직접 호출 전용 상태를 **`user-only`**로 표시합니다.
실제로 `.claude/settings.local.json`에 저장되는 값은 다음과 같습니다.
기존 설정이 있다면 해당 항목을 병합하며 파일 전체를 덮어쓰지 않습니다.

```json
{
  "skillOverrides": {
    "decision-interview": "user-invocable-only"
  }
}
```

`name-only`는 이름만 노출하므로 description 선택 평가에 적합하지 않고, `off`는 스킬을 숨깁니다.
이 override 안내는 개인·프로젝트 스킬에 해당하며 플러그인 스킬에는 적용되지 않습니다.
설치 명령은 호스트 설정 파일을 변경하지 않습니다.

공식 참고: [Agent Skills 형식](https://agentskills.io/specification),
[Codex 스킬·호출 정책](https://learn.chatgpt.com/docs/build-skills),
[Claude Code 호출 제어](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings).
안내 기준일은 2026-11-22입니다.

## 인계와 다음 행동

인터뷰 결과는 기본적으로 대화에 남는 인계문입니다.
목표·범위, 결정과 이유, 사실과 제안, 정확한 제약, 미해결 사항과 해결 조건, 다음 행동과 기존 승인 범위를 담습니다.
API 키나 비밀번호는 제외하고, 개인정보는 다음 작업에 필요한 범위로 제한합니다.
파일 반영이 이미 요청됐다면 기존 명세에 반영할 수 있습니다.

다른 대화나 스킬로 넘길 때는 인계문과 접근 가능한 근거를 함께 제공하고 후속 작업의 범위를 적습니다.

```text
아래 인계문을 기준으로 계획을 작성해줘.
확정한 조건은 유지하고 미해결 항목은 가정으로 확정하지 마.
이번 단계는 계획 작성까지이며 구현이나 외부 게시 승인은 포함하지 않아.
[인계문]
```

이미 구현까지 승인한 작업이라면 필요한 결정이 갖춰진 범위에서 이어갑니다.
인계문을 받았다는 사실만으로 새로운 실행 권한이 생기지는 않습니다.
별도 스킬 이름이나 파일 저장을 필수로 요구하지 않습니다.

## 검증

개발용 검증에는 Python 3.11 이상과 Git이 필요합니다.
격리된 Python 환경에서 저장소 루트를 기준으로 실행합니다.

```text
python -m pip install -r requirements-dev.txt
skills-ref validate skills/decision-interview
python scripts/validate.py
python -m unittest discover -s tests
```

[GitHub Actions](.github/workflows/validate.yml)는 스킬 형식·Codex 메타데이터·평가 JSON 스키마와 검사 도구의 회귀 테스트를 실행하고,
로컬 링크와 외부 링크는 별도 작업으로 검사합니다.
외부 링크의 네트워크 실패는 구조 검증이나 모델 동작의 실패와 구분합니다.

[평가 안내](evals/README.md), [19개 사례](evals/cases.json),
[JSON Schema](evals/cases.schema.json)는 스킬 폴더 밖에 있습니다.
CI는 모델과 대화하거나 자연어 발동을 시험하지 않습니다.
실제 발동·조건 보존·질문 품질은 호스트별 대화 시험과 기록이 필요하며, 구조 검증만으로 성능 향상이나 권한 격리를 보장하지 않습니다.

## 설계 참고

질문 절차는 이 저장소의 범위에 맞게 새로 작성했습니다.
아래 프로젝트의 원칙을 참고했으며, 해당 프로젝트를 설치하거나 실행할 필요는 없습니다.

| 참고 자료 | 반영한 관점 |
|---|---|
| [Ouroboros interview](https://github.com/Q00/ouroboros/blob/efedf17ec1f8a12c95e2f44e74001a785917b17a/skills/interview/SKILL.md) · [Seed Closer](https://github.com/Q00/ouroboros/blob/efedf17ec1f8a12c95e2f44e74001a785917b17a/src/ouroboros/agents/seed-closer.md) | 사실과 선택의 구분, 중요한 미결정 사항, 실질적인 종료 판단 |
| [Symposium](https://github.com/Q00/Symposium/tree/60037854824e369b004703de30877a6c88530f60) | 단어의 의미와 범위, 해석 차이, 목표 재진술 |
| [Matt Pocock grilling](https://github.com/mattpocock/skills/blob/abeeaf95660ba9e8b7c753eb38f441ca707a8823/skills/productivity/grilling/SKILL.md) | 선행 결정에 따른 질문 순서 |
| [Superpowers brainstorming](https://github.com/obra/superpowers/blob/22f0b463e7a5e579904dd6211a520321035526f7/skills/brainstorming/SKILL.md) | 목적 발견과 선택 지원의 구분, 위임한 판단 존중 |
| [Spec Kit clarify](https://github.com/github/spec-kit/blob/a4d571229e164e440f8950cac034607bae7b7518/templates/commands/clarify.md) | 중요한 질문의 선별, 답변과 요구사항의 연결 |

참고 문서는 설계 출처이며 스킬 실행 중 읽어야 할 의존 파일이 아닙니다.
