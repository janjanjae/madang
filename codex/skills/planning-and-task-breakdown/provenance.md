# 출처 (Provenance)

마당 작성 스킬에 질문 → 기획서 → 코드 순서를 흡수했다. 원본 그대로가 아니라 개조판이다.

- 상류: https://github.com/mattpocock/skills (MIT, Copyright (c) 2026 Matt Pocock)
- `skills/productivity/grilling/SKILL.md` 기준 `7739eae` (2026-11-05 확인)
- `skills/engineering/to-spec/SKILL.md` 기준 `5c89081`
- `skills/engineering/to-tickets/SKILL.md` 기준 `9e2abf8`

채택:
- grilling: 답할 수 있는 결정만 라운드로 묻기(frontier) · 권장 답 함께 제시 · "응"이면 채택 · 사실은 에이전트가 찾고 결정은 사람이
- to-spec: 인터뷰를 반복하지 않고 합성 · 문제·사용자 스토리·구현 결정·테스트 결정·범위 밖 섹션
- to-tickets: 수직 슬라이스 · 막는 관계(blocked by) · 쪼갠 결과를 사람에게 확인

바꾼 것 (시간제한·폐쇄 환경):
- 끝날 때까지 묻는 대신 최대 2라운드·10분
- 서브에이전트 대신 직접 파일을 읽는다 (토큰)
- 요구사항 질문은 업무 담당자용 목록으로 분리 (Codex는 답을 모른다)
- 이슈 트래커 발행·라벨·`.scratch/` 대신 plan.md 한 곳 (외부 전송 금지, 중복 금지)
