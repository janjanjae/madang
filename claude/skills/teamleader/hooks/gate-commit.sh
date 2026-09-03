#!/usr/bin/env bash
# PreToolUse(Bash) — 커밋 게이트: 내 인스턴스의 APPROVE reply 또는 waiver 없이 git commit 차단
# 팀 규칙: 커밋 전 테스트+컨펌 필수 (ways-of-working "팀원 작업 규율")
#
# 🔴 훅 입력 JSON은 stdin으로 온다. 파이썬 코드를 heredoc(`python3 - <<PY`)으로 넘기면 heredoc이 stdin을
#    차지해 JSON이 밀려나고 매번 JSONDecodeError → exit 1(비차단) → 게이트가 조용히 무력화된다
#    (2026-07-28~09-02 실사고: 발화 6,900회 전부 실패, incidents.md 「훅」). 코드는 짝 .py 파일로 분리하고 stdin은 JSON에 남긴다(macOS bash 3.2는 $(cat <<PY …) 안의 긴 코드도 못 파싱한다).
# 통과 조건(순서대로):
#   1) 커밋 명령이 아니면 통과 (`git commit`, `git -C <dir> commit` 등 첫 서브커맨드가 commit인 경우만 검사)
#   2) 팀장이 만든 waiver: `.claude/team/confirm/commit-waiver`(전원) 또는 `commit-waiver-{인스턴스}`
#   3) 슥슥의 실험 커밋: 인스턴스가 sketcher*이고 메시지에 `[proto]` 포함 (정리 커밋은 APPROVE 필요)
#   4) `.claude/team/confirm/{인스턴스}.reply.md` 첫 줄이 APPROVE — 인스턴스는 transcript에서 추정
#      (자기 briefs/confirm/reports 파일 경로가 가장 많이 등장한 이름). 추정 실패 시에만 아무 APPROVE reply로 통과(구 동작).
# `.claude/team`은 메인 트리에만 있으므로(gitignore) 워크트리에서는 `git rev-parse --git-common-dir`로 메인 트리를 찾는다.
exec python3 "${0%.sh}.py"
