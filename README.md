# 포켓몬 에이전트 팀 (pokemon-agent-team)

Claude Code(+ GitHub Copilot CLI)로 **"팀장 1 + 구현 팀원 N"** 멀티 세션 개발 팀을 운영하기 위한 설정 모음.
터미널 탭마다 페르소나를 가진 에이전트 세션을 띄우고, 파일 신호로 브리프·컨펌을 주고받는 **탭 모드** 협업 시스템이다.

## 로스터

| 이름 | 역할 | 인사 |
|---|---|---|
| 팀장 (`/teamleader`) | 오케스트레이터 — 브리프 배분, 보고 git 교차검증, 허브 문서(TASKS/PROGRESS) 단일 작성자 | — |
| 파이리 (`/pairi`) | 에이스 구현 + 에스컬레이션 디버깅 | 파이리~! |
| 메타몽 (`/metamong`) | 구현 메인 축 — 어떤 도메인이든 변신, 분신(메타몽1·2)으로 병렬 처리 | 메타몽... |
| 꼬부기 (`/kkobugi`) | UX/UI 프로토타이핑 — worktree 격리, 스크린샷 후보 제시 → 확정안만 메인 반영 | 꼬부기~ 꼬북꼬북! |
| 로토무도감 (`/rotomdex`) | 기술 해설 전담(읽기 전용) — 팀 문서를 감시하며 비개발자에게 쉽게 설명 + 학습 링크 | 로토무! 지지직— |

## 핵심 개념

- **탭 모드**: 사람이 터미널 탭을 열어 팀원 세션을 기동(사람 개입은 탭당 시작 프롬프트 1회). 브리프는 `.claude/team/briefs/{인스턴스}.md` 파일 폴링으로 자동 수령.
- **컨펌 신호 프로토콜**: 커밋 전 팀원이 `.claude/team/confirm/{인스턴스}.request.md`(CONFIRM/BLOCKED/DISCUSS) 작성 → 팀장이 백그라운드 감시로 감지·검증 → `reply.md`(APPROVE/FIX)로 응답.
- **기술 주체성**: 팀원은 공식문서로 브리프를 선검증하고, 세부 판단은 자율, 브리프와 충돌하면 `DISCUSS`로 논의.
- 상세 규칙: `claude/skills/teamleader/ways-of-working.md`

## 설치

```bash
git clone <this-repo> && cd pokemon-agent-team
./install.sh   # ~/.claude, ~/.copilot 에 심링크 생성 (기존 파일은 .bak 백업)
```

이후 `~/.claude/...`를 편집하면 그대로 이 레포의 워킹트리 변경이 된다 — 커밋만 하면 팀 시스템이 버전 관리된다.

## 구조

```
claude/
  agents/      # 팀원 페르소나 (pairi, metamong, kkobugi, rotomdex)
  skills/      # 세션 시작 스킬 + teamleader (roster/ways-of-working/model-guide/skill-guide)
  commands/    # 팀장 개인 커맨드 (kickoff, progress-check, jira-*)
copilot/
  skills/sync_claude_team/   # Claude → Copilot 단방향 설정 동기화 스킬
install.sh
```

## 상태

개인 운영 중(private). 회사·프로젝트 특화 문맥이 일부 문서(변경 이력·운영 메모)에 남아 있어, 공개 공유 전 sanitize 패스가 필요하다.
