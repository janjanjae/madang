# 워크트리 셋업 체크리스트

> `ways-of-working.md`에서 분리(2026-08-13). **새 워크트리를 만들 때** 읽는다.

> 워크트리는 git 체크아웃이라 **gitignored 파일이 딸려오지 않는다.** 생성 직후 반드시 아래를 수행.

1. **env 복사**(Next.js/Nest는 `.env.local`을 읽는데 gitignore라 워크트리에 없음 → dev 서버 오동작, 예: 로그인 테스트버튼 사라짐). **앱이 늘면 이 목록도 늘어난다 — 프로젝트별 실제 앱 구성을 확인할 것**({app-repo}는 2026-08-04 PROJ-720으로 `apps/llm` 신설되어 3종):
   ```
   cp {repo}/{app-dir}/apps/web/.env.local  {wt}/{app-dir}/apps/web/.env.local
   cp {repo}/{app-dir}/apps/api/.env.local  {wt}/{app-dir}/apps/api/.env.local
   cp {repo}/{app-dir}/apps/llm/.env.local  {wt}/{app-dir}/apps/llm/.env.local
   ```
   - ⚠️ **Redis 등 공유 백킹서비스를 쓰는 프로젝트는 키 네임스페이스를 워크트리별로 분리**해야 병렬 기동이 서로 간섭하지 않는다({app-repo}: `REDIS_PREFIX=local:{ticket}`, api·llm 양쪽 동일 값). 프로젝트별 상세 절차는 `{프로젝트}/.claude/team/agents/_local-runtime.md`에 두고 팀원 애든덤에서 참조시킨다.
2. 🔴 **`storage/` 복사 — 2026-08-25 실사고로 추가.** 업로드·생성 파일 실체가 **워크트리 로컬**에 있는데 **DB는 공유**다. 트리를 바꿔 서버를 띄우면 **DB엔 파일 기록이 있는데 실체가 없어** 파일트리가 비어 보이고 `404: 스토리지와 체크포인트 모두에 파일이 존재하지 않습니다`가 뜬다.
   ```
   rsync -a --ignore-existing {기존트리}/{app-dir}/apps/api/storage/ {새트리}/{app-dir}/apps/api/storage/
   ```
   - **증상이 코드 회귀처럼 보인다** — 실제로 2026-08-25 스모크에서 *"파일트리가 안 보인다"* + *"Agent 전환이 막힌다"*로 나타났고, 후자는 파일을 못 읽어 `suggestion` 생성이 실패해 `execution`이 정리되지 않은 2차 증상이었다. **트리를 옮긴 직후의 이상은 storage부터 의심해라.**
   - 스모크 트리를 바꿀 때마다 필요하다. `--ignore-existing`이라 기존 파일은 안 덮는다.

3. **`.claude/team`**(briefs/confirm/reports)도 gitignore → 워크트리에 없음. **메인 트리 절대경로**로 접근(`/{repo}/.claude/team/...`). request/reply/report는 메인 트리 쪽에 쓴다.
4. **node_modules — 프로젝트 레이아웃에 따라 다르다. 확인하고 브리프에 명시할 것.**
   - `node_modules`가 **레포 루트**에 있으면: 워크트리를 `.claude/worktrees/`(레포 하위)에 두면 Node 모듈 해석이 위로 올라가 루트 것을 공유 → install 불필요.
   - `node_modules`가 **하위 디렉토리**에 있으면({app-repo}: `{app-dir}/` 하위): 위로 해석이 안 올라가 **워크트리마다 `pnpm install` 필요**. (2026-08-09 실측 — 기존 "루트 공유" 서술이 이 레이아웃에서 틀렸다.)
5. **Docker/Postgres·포트 공유** — 로컬 Postgres(5432)는 하나만 기동(`docker-compose up -d`, Docker 데몬 먼저). dev 서버는 메인 트리 것과 포트 겹치면 종료 후 하나만.
6. Node 버전 = `.nvmrc`(22) 준수(`nvm use 22`).

> 팀장은 워크트리 배분 시 브리프에 "wt-{ticket} 생성 + 위 셋업"을 명시. 워커 페르소나 스킬도 이 체크리스트를 참조한다.
