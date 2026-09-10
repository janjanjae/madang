#!/usr/bin/env bash
# 마당(madang) 팀 시스템 설치 — ~/.claude 에 심링크 생성 (~/.copilot은 있을 때만 함께)
# 기존 파일/디렉토리는 .bak 으로 백업 후 링크. 롤백 = .bak 을 원위치로 복원.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  # 심링크도 백업한다 (2026-09-05) — 자기 dotfiles를 여기에 링크해 둔 사람이
  # 경고 없이 링크를 잃던 결함. 단 이미 이 레포를 가리키면 그대로 둔다(재실행 무해).
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      echo "keep   : $dst (이미 이 레포를 가리킨다)"
      return 0
    fi
    mv "$dst" "$dst.bak"
    echo "backup: $dst -> $dst.bak (기존 링크 대상: $(readlink "$dst.bak"))"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak"
    echo "backup: $dst -> $dst.bak"
  fi
  ln -sfn "$src" "$dst"
  echo "linked : $dst -> $src"
}

# 팀원 페르소나 (subagent/teammate 공용 정의)
for f in solver builder sketcher narrator; do
  link "$REPO/claude/agents/$f.md" "$HOME/.claude/agents/$f.md"
done

# 스킬 (디렉토리 단위 링크) — 페르소나 + 팀장 커맨드(2026-07-27 E-1: commands/*.md → skills/*/SKILL.md 통합)
for d in teamleader solver builder sketcher narrator kickoff save-progress progress-check issue-capture issue-refine issue-cache skill-audit; do
  link "$REPO/claude/skills/$d" "$HOME/.claude/skills/$d"
done

# Copilot 동기화 스킬 (파일 단위 — .snapshots/ 는 로컬 상태라 레포에 포함하지 않음)
if [ -d "$HOME/.copilot" ]; then
  link "$REPO/copilot/skills/sync_claude_team/SKILL.md" "$HOME/.copilot/skills/sync_claude_team/SKILL.md"
  link "$REPO/copilot/skills/sync_claude_team/manifest.md" "$HOME/.copilot/skills/sync_claude_team/manifest.md"
else
  echo "skip   : ~/.copilot 없음 — Copilot 동기화 스킬 건너뜀"
fi

echo ""
echo "✅ 설치 완료. 이제 ~/.claude 쪽을 편집하면 곧 이 레포의 변경이 된다 (git diff로 확인, 커밋만 하면 이력화)."

# 커밋 규칙 훅·템플릿 (CONTRIBUTING.md, 2026-09-04) — 이 레포에만 적용
git -C "$REPO" config core.hooksPath .githooks
git -C "$REPO" config commit.template .gitmessage
echo "hooks  : core.hooksPath=.githooks, commit.template=.gitmessage"
