---
name: planning-and-task-breakdown
description: Breaks work into ordered, verifiable tasks and writes plan.md. Use when you have a spec or clear requirements and need to break work into implementable tasks, when a task feels too large or vague to start, when you need to estimate scope, or when parallel work is possible.
---

# Planning and Task Breakdown

## Overview

작업을 인수 기준이 분명한 작고 검증 가능한 태스크로 쪼갠다. 각 태스크는 한 번의 집중된 작업으로 구현·테스트·확인할 수 있을 만큼 작아야 한다.

## When to Use

- 요구사항이 있고 구현 단위로 쪼개야 할 때
- 태스크가 너무 크거나 모호하게 느껴질 때
- 구현 순서가 분명하지 않을 때
- 여러 터미널·세션에 나눠 병렬로 할 수 있는지 판단할 때

**When NOT to use:** 명확한 단일 파일 변경, 요구사항에 이미 태스크가 명확할 때.

## The Planning Process

### Step 0: 문제 정의 (코드보다 먼저)

- 요구사항·README·안내 문서를 **끝까지** 읽는다.
- 필수 제출물·필수 기능 vs 선택 기능을 목록으로 가른다.
- 애매한 점은 추측으로 메우지 말고 **모아서 한 번에** 질문한다. 답을 못 받으면 가정으로 적고 진행한다.

### Step 1: 읽기 전용 단계

코드 작성 전:
- 요구사항과 관련 코드 읽기, 기존 패턴·컨벤션 파악
- 컴포넌트 간 의존성 매핑
- 위험 요소와 미확인 사항 기록

**계획 단계에서 코드를 쓰지 않는다.** 출력물은 plan.md.

### Step 2: 의존성 그래프

```
데이터 모델 / 스키마
    └── 저장·비즈니스 로직
            └── API (라우트·입력 검증)
                    └── 화면 (API 호출·표시)
```
구현 순서는 그래프의 아래에서 위로.

### Step 3: 수직 슬라이싱

```
✗ 수평: Task 1 전체 DB → Task 2 전체 API → Task 3 전체 UI
✓ 수직: Task 1 항목 생성(모델+API+화면) → Task 2 목록·필터 → Task 3 요약 통계
```
첫 슬라이스는 **끝까지 동작하는 가장 얇은 경로**(walking skeleton) — 일찍 돌아가는 걸 보여주고 위험을 앞당겨 드러낸다.

### Step 4: 태스크 양식

```markdown
## Task N: [짧은 제목]
**Description:** 이 태스크가 달성하는 것 한 단락
**Acceptance criteria:**
- [ ] 구체적이고 테스트 가능한 조건
**Verification:**
- [ ] 테스트 통과: <AGENTS.md의 테스트 명령>
- [ ] 직접 확인: <브라우저·curl로 볼 것>
**Dependencies:** Task 번호 또는 None
**Estimated scope:** XS(1파일) / S(1-2) / M(3-5) / L(5-8) / XL(8+ → 더 쪼갤 것)
```

### Step 5: 순서·체크포인트

- 의존성 순서대로, 각 태스크 후 시스템은 동작 상태
- 고위험 태스크를 앞에 (빨리 실패)
- 2-3개 태스크마다 체크포인트: 테스트 통과·빌드 클린·핵심 흐름 동작
- **시간 상자가 있으면** 태스크마다 대략의 시간을 붙이고, 필수 범위가 먼저 끝나도록 선택 기능은 뒤로

## plan.md 템플릿

```markdown
# plan: [과제 이름]

## 문제 정의
- 누구의 어떤 문제를 푸나 (한두 줄)
- 필수 범위 / 선택 범위 / 이번에 안 하는 것

## 가정
- [확인 못 한 것을 어떻게 가정했나]

## 아키텍처 결정
- [결정 + 근거 한 줄]

## 태스크
- [ ] Task 1: ... (검증: ...)
- [ ] Task 2: ...
### 체크포인트: 핵심 흐름 동작

## 검증 방법
- 테스트 명령 / 직접 확인할 시나리오 / 엣지 케이스

## 위험
| 위험 | 영향 | 완화 |

## 결정 로그 (작업하며 추가)
- HH:MM 무엇을 왜 바꿨나

## 남은 한계
- 시간 안에 못 한 것·알려진 문제
```

## Red Flags

- 태스크 목록 없이 구현 시작
- 인수 기준·검증 단계 없는 태스크
- 모든 태스크가 XL
- 체크포인트 없음, 의존성 순서 무시
- 애매한 요구사항을 묻지도 적지도 않고 추측으로 구현

## Verification

구현 시작 전:
- [ ] 문제 정의·필수/선택 범위가 plan.md에 있다
- [ ] 모든 태스크에 인수 기준과 검증 단계가 있다
- [ ] 의존성 순서가 맞다, 태스크당 파일 5개 이하
- [ ] 체크포인트가 있다
