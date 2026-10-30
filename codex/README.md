# codex/ — Codex CLI 어댑터

마당의 작업 습관을 **Codex CLI**에서 쓰기 위한 판. 마당 본체(탭 세션·커밋 게이트 훅·워커 오버레이)는 Claude Code 전용이라, 여기엔 도구와 무관하게 옮겨지는 부분만 담았다.

| 경로 | 내용 |
|---|---|
| `AGENTS.md` | 작업 공간 규칙 템플릿 — 과제별 칸(`<!-- 과제별 -->`)만 채워 쓴다 |
| `skills/planning-and-task-breakdown` | 문제 정의 → plan.md → 수직 슬라이스 태스크 |
| `skills/incremental-implementation` | 슬라이스 단위 구현 + 최소코드 사다리 (ponytail 5 반영) |
| `skills/debugging-and-error-recovery` | 재현 → 원인 → 수정 → 회귀 테스트 |
| `skills/verification-before-completion` | 증거 없는 완료 주장 금지 (superpowers 원본 그대로) |
| `team-lite.md` | 터미널 탭 2~3개로 나누는 탭 모드 라이트 |

## 설치 (작업 공간 루트에서)

```bash
git clone https://github.com/janjanjae/madang /tmp/madang \
  && mkdir -p .agents/skills \
  && cp -r /tmp/madang/codex/skills/* .agents/skills/ \
  && cp /tmp/madang/codex/AGENTS.md ./AGENTS.md
```

- 이미 `AGENTS.md`가 있으면 덮어쓰지 말고 필요한 절만 붙인다.
- 스킬 위치 `.agents/skills/`는 Codex 문서 기준 — **확인 필요**: Codex 버전에 따라 다를 수 있으니 `/skills`에 목록이 뜨는지 먼저 본다. 안 뜨면 `~/.agents/skills/`에도 복사해 본다.

## 사용

- `/skills` — 인식된 스킬 목록
- `$이름` — 스킬을 직접 불러 쓴다 (예: `$planning-and-task-breakdown`)
- 설명(description)이 맞는 상황이면 Codex가 스스로 불러 쓰기도 한다

출처·라이선스는 각 스킬의 `provenance.md`.
