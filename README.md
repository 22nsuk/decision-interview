# Decision Interview

모호한 아이디어를 구체화하거나 계획의 중요한 가정을 검토하는 독립 질문 스킬입니다.
결과를 바꿀 질문을 고르고, 대화에서 정한 조건을 보존하며, 다음 행동에 필요한 만큼 명확해지면 마칩니다.

## 핵심 동작

- 질문 전에 현재 대화와 지정 자료를 확인하고, 조사할 사실과 사용자가 정할 선택을 구분합니다.
- 중요한 미결정 사항을 선행 결정부터 다룹니다. 기본은 한 번에 한 질문입니다.
- 목적을 탐색할 때는 열린 질문을, 구체적인 선택에는 대안과 절충을, 중요한 가정에는 사례와 반례를 사용합니다.
- 확인된 결정·근거 있는 사실·모델의 제안·남은 불확실성을 구분합니다.
- 답변의 수치·단위·금지 조건·예외·순서를 보존하고, 결정이 바뀌면 영향을 받는 선택만 다시 봅니다.
- 사용자의 재량 위임과 기존 승인을 유지합니다. 인터뷰 자체가 추가 실행 권한을 만들지는 않습니다.
- 모르는 답을 강요하지 않고 조사·실험·보류로 연결합니다. 종료 시 진행 가능한 범위와 막힌 범위를 구분합니다.

고정 질문 수, 후보 개수 채우기, 모호성 점수, 필수 보조 에이전트, MCP 서버, 자동 파일 저장은 요구하지 않습니다.

## 사용할 때

아이디어나 계획에 관해 **질문을 통한 논의를 원할 때** 직접 호출합니다.
일반적인 사실 질문, 코드 리뷰, 이미 충분히 명확한 수정 작업을 인터뷰로 바꾸는 용도가 아닙니다.
다른 작업으로 전환하거나 중단을 요청하면 인터뷰 모드를 종료합니다.

스킬 본문은 영문으로 작성되어 있고, 대화는 사용자의 언어를 따르도록 지시합니다.

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
UI 세부사항은 맡길게. 답을 모르면 보류할 수 있게 하고,
마지막에는 결정과 미해결 사항을 간단히 정리해줘.
```

Claude Code에서는 같은 예시의 `$decision-interview`를 `/decision-interview`로 바꿉니다.

## 설치

설치할 단위는 [skills/decision-interview](skills/decision-interview) 폴더 전체입니다.
스킬 본체는 [SKILL.md](skills/decision-interview/SKILL.md) 하나이며,
`agents/openai.yaml`에는 Codex용 표시 정보와 호출 정책만 들어 있습니다.
다른 스킬 호출, 실행 스크립트, 패키지 설치가 필요하지 않습니다.

1. 저장소를 내려받거나 복제합니다.
2. `skills/decision-interview` 폴더를 사용할 도구의 스킬 위치로 복사합니다.
3. 같은 이름의 폴더가 이미 있으면 내용을 비교한 뒤 갱신합니다. 기존 폴더를 무조건 덮어쓰지 않습니다.
4. 도구의 스킬 목록에서 인식되는지 확인한 뒤 직접 호출합니다.

| 환경 | 프로젝트 범위의 복사 위치 | 사용자 범위의 복사 위치 | 호출 |
|---|---|---|---|
| Codex CLI / IDE | `.agents/skills/decision-interview/` | `~/.agents/skills/decision-interview/` | `$decision-interview` |
| Claude Code | `.claude/skills/decision-interview/` | `~/.claude/skills/decision-interview/` | `/decision-interview` |

위 경로의 기준은 **스킬을 사용할 프로젝트 또는 해당 도구를 실행하는 사용자 환경**입니다.
Windows 네이티브와 WSL을 함께 사용한다면 도구가 실행되는 쪽에 설치합니다.
다른 호스트는 해당 호스트의 Agent Skills 설치·호출 방법을 따릅니다.

### 호출 정책

Codex는 포함된 `agents/openai.yaml`의 `allow_implicit_invocation: false`를 통해 명시적 호출을 사용하도록 설정했습니다.
이 설정은 Codex용이며 다른 호스트가 적용한다고 가정하지 않습니다.

Claude Code에서 호스트 수준으로 직접 호출만 허용하려면 `/skills`에서 이 스킬을 `user-only`로 설정할 수 있습니다.
이는 사용자 설정이며 저장소가 자동으로 변경하지 않습니다. 그 밖의 호스트에서는 스킬의 명시적 인터뷰 요청 범위를 따르되, 강제 호출 제한 여부는 호스트 설정을 확인합니다.

공식 참고: [Agent Skills 형식](https://agentskills.io/specification),
[Codex 스킬 위치·호출 정책](https://learn.chatgpt.com/docs/build-skills),
[Claude Code 스킬·호출 제어](https://code.claude.com/docs/en/skills).
설치 안내는 2026-11-22의 공식 문서를 기준으로 작성했습니다.

## 결과와 한계

인터뷰 결과는 기본적으로 대화에 남는 간단한 인계문입니다.
목표와 범위, 중요한 결정과 이유, 제약과 완료 조건, 미해결 사항과 다음 행동을 담습니다.
파일 반영이 이미 요청된 경우에는 기존 명세에 반영할 수 있지만, 별도의 저장소나 외부 메모리를 자동 생성하지 않습니다.

이 저장소는 모델이 따를 지침을 제공합니다. 질문 품질, 문맥 유지, 호출 정책 준수는 실제 호스트와 모델에서도 확인해야 합니다.
스킬 설치나 구조 검증만으로 성능 향상·오작동 방지·권한 격리를 보장하지 않습니다.

## 검증

[evals/README.md](evals/README.md)에 평가 방법과 검증 범위를,
[evals/cases.json](evals/cases.json)에 발동 경계·결정 보존·중단·인계 사례를 둡니다.
평가 자료는 설치하는 스킬 폴더 밖에 있어 실행 지침에 포함되지 않습니다.

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
