#!/bin/zsh
set -euo pipefail

export HOME="/Users/lxz"
export LANG="zh_CN.UTF-8"
export LC_ALL="zh_CN.UTF-8"
export TZ="Asia/Shanghai"
export PATH="/Users/lxz/.nvm/versions/node/v22.22.1/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=20 -o StrictHostKeyChecking=accept-new"

BASE_DIR="/Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending"
ZOLA_DIR="/Users/lxz/.local/share/whoIsSpendingDaily/repos/zola-basic"
CODEX_BIN="/Users/lxz/.nvm/versions/node/v22.22.1/bin/codex"
LOG_DIR="/Users/lxz/Library/Logs/whoIsSpendingDaily"
DAY="$(date +%F)"
RUN_STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/daily-${DAY}-${RUN_STAMP}.log"
PROMPT_FILE="${LOG_DIR}/prompt-${DAY}-${RUN_STAMP}.md"
FINAL_FILE="${LOG_DIR}/final-${DAY}-${RUN_STAMP}.txt"
LOCK_DIR="/tmp/com.linxz.whoisspending.daily.lock"

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1

echo "== whoIsSpending daily automation =="
echo "started_at=$(date '+%F %T %Z')"
echo "day=$DAY"
echo "base_dir=$BASE_DIR"
echo "zola_dir=$ZOLA_DIR"
echo "codex=$CODEX_BIN"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  if [[ -f "$LOCK_DIR/pid" ]] && kill -0 "$(cat "$LOCK_DIR/pid")" 2>/dev/null; then
    echo "Another daily run is already active. Exiting."
    exit 0
  fi
  echo "Removing stale lock: $LOCK_DIR"
  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR"
fi
echo "$$" >"$LOCK_DIR/pid"
trap 'rm -rf "$LOCK_DIR" 2>/dev/null || true' EXIT

if [[ ! -x "$CODEX_BIN" ]]; then
  echo "Codex CLI not executable: $CODEX_BIN"
  exit 1
fi

cat >"$PROMPT_FILE" <<PROMPT
This is an unattended scheduled Codex run. Do not ask the user any questions. Do not wait for approval.

Current date: ${DAY}
Timezone: Asia/Shanghai

Goal:
Generate today's "谁在花钱日报" according to the existing requirements in this repository, then publish it to both GitHub repositories:
- whoIsSpending local repo: /Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending
- whoIsSpending remote: git@github.com:linxz-coder/whoIsSpending.git
- zola-basic local repo: /Users/lxz/.local/share/whoIsSpendingDaily/repos/zola-basic
- zola-basic remote: git@github.com:linxz-coder/zola-basic.git

Important automation requirements:
- This task is explicitly daily. Run even if an older README line suggests skipping weekends.
- Use live web search and cite/check current official or high-quality sources while drafting.
- Follow /Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending/README.txt and /Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending/新闻源清单.txt.
- Use the current month's de-duplication list when selecting items; avoid repeating "主体+事件+金额" unless there is a clear update.
- Default sections: 政府、国际政府与开发资金、投资机构、企业、富豪资本、平民消费、高薪职位。
- 高薪职位 must include China and international groups, with currency, monthly salary basis, and source/basis.
- 平民消费 must include hot categories, representative products, money flow, and domestic/international hot brand observations.

Required steps:
1. In /Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending, pull latest origin/main with fast-forward only.
2. In /Users/lxz/.local/share/whoIsSpendingDaily/repos/zola-basic, pull latest origin/main with fast-forward only.
3. Create or refresh /Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending/${DAY}/ with:
   - 谁在花钱_素材池_${DAY}.txt
   - 谁在花钱_日报_${DAY}.txt
   - 谁在花钱_发布版_${DAY}.txt
   - 生成指令.txt
4. Write the Zola Markdown article:
   - /Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending/${DAY}/github_sync_payload/content/blog/谁在花钱日报-${DAY}.md
   - /Users/lxz/.local/share/whoIsSpendingDaily/repos/whoIsSpending/github_sync_payload/content/blog/谁在花钱日报-${DAY}.md
   Use this front matter:
   +++
   title = "谁在花钱日报｜${DAY}"
   date = ${DAY}
   authors = ["小中"]

   [taxonomies]
   tags = ["日报", "商业", "投资", "高薪职位"]
   +++
5. Copy the Markdown article to /Users/lxz/.local/share/whoIsSpendingDaily/repos/zola-basic/content/blog/谁在花钱日报-${DAY}.md.
6. Run zola build in /Users/lxz/.local/share/whoIsSpendingDaily/repos/zola-basic if zola is available. If it creates or changes public/, do not commit public/.
7. Commit and push zola-basic first:
   - stage only content/blog/谁在花钱日报-${DAY}.md
   - commit message: Add who-spending report ${DAY}
   - push origin main
8. Commit and push whoIsSpending:
   - include today's dated directory, root github_sync_payload article, latest updates if you refresh latest, current month de-dup list if updated, and any relevant workflow files
   - do not commit .DS_Store or logs
   - commit message: Add who-spending daily archive ${DAY}
   - push origin main
9. If today's files already exist and no content changes are needed, do not create empty commits. Still ensure both repos are clean and up to date.
10. Keep unrelated local changes untouched. In zola-basic, ignore existing untracked public/.

Final response should summarize:
- whether today's report was generated or already current
- zola-basic commit hash if committed
- whoIsSpending commit hash if committed
- any failures that need manual attention
PROMPT

echo "prompt_file=$PROMPT_FILE"
echo "log_file=$LOG_FILE"
echo "final_file=$FINAL_FILE"

"$CODEX_BIN" \
  --disable apps \
  --search \
  --dangerously-bypass-approvals-and-sandbox \
  --dangerously-bypass-hook-trust \
  exec \
  --ignore-user-config \
  --ignore-rules \
  -C "$BASE_DIR" \
  --add-dir "$ZOLA_DIR" \
  -o "$FINAL_FILE" \
  - <"$PROMPT_FILE"

echo "finished_at=$(date '+%F %T %Z')"
if [[ -f "$FINAL_FILE" ]]; then
  echo "== codex final message =="
  cat "$FINAL_FILE"
fi
