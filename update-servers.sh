#!/bin/bash
# Update pipeline for this Mac and the fleet: bump → check → commit → push → deploy.
#
#   ./update-servers.sh             bump claude-code only (cheap — the daily run)
#   ./update-servers.sh --full      also update every flake input (re-downloads
#                                   most of the closure everywhere — weekly)
#   ./update-servers.sh --no-bump   deploy what is already committed
#   ./update-servers.sh kitkat ...  limit the deploy to these nodes
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mac_host="Nikitas-MacBook-Pro"

bump=claude
only_nodes=""
for arg in "$@"; do
  case "$arg" in
    --full) bump=full ;;
    --no-bump) bump=none ;;
    -h | --help)
      sed -n '2,8s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "unknown option: $arg" >&2
      exit 2
      ;;
    *) only_nodes="$only_nodes $arg" ;;
  esac
done

cd "$repo"
echo "🔄 Starting update pipeline..."

# Bail out if the working tree is dirty — the only thing committed here is the bump.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ $repo has uncommitted changes — refusing to run."
  exit 1
fi

echo "⬇️  Pulling latest..."
git pull --ff-only

case "$bump" in
  full)
    echo "📦 Updating every flake input and claude-code..."
    just bump
    just bump-claude
    ;;
  claude)
    echo "📦 Bumping claude-code..."
    just bump-claude
    ;;
  none) echo "ℹ️  --no-bump: deploying what is already committed." ;;
esac

# Gate, before anything is committed, pushed or deployed. The eval instantiates
# every server profile, so evaluation errors surface here rather than on a
# server; the build is this machine's system, built but not switched to (that
# needs sudo — `nup` does it, and is then instant).
gate() {
  echo "🔎 Evaluating every server profile..."
  nix eval --json .#deploy > /dev/null || return 1
  if [ "$(uname)" = Darwin ]; then
    echo "🔨 Building the Mac system (no switch)..."
    mac_system=$(nix build --no-link --print-out-paths ".#darwinConfigurations.$mac_host.system") || return 1
  fi
}
mac_system=""
if ! gate; then
  echo "❌ Check failed — nothing committed, pushed or deployed."
  echo "   The bump is left in the working tree: fix it, or drop it with"
  echo "   git -C $repo checkout flake.lock files/claude-manifest.json"
  exit 1
fi

# Commit only if the bump actually changed something.
git add flake.lock files/claude-manifest.json
if git diff --cached --quiet; then
  echo "ℹ️  Nothing changed — nothing to commit."
else
  msg=""
  git diff --cached --quiet -- flake.lock || msg="update flake.lock"
  if ! git diff --cached --quiet -- files/claude-manifest.json; then
    msg="${msg:+$msg, }bump claude-code $(jq -r .version files/claude-manifest.json)"
  fi
  git commit -m "$msg"
fi

echo "📤 Pushing to remote..."
git push

# Node names come straight from the flake so this stays in sync with deploy.nodes.
nodes=${only_nodes:-$(nix eval --json .#deploy.nodes --apply builtins.attrNames | jq -r '.[]')}
deploy=$(nix build --no-link --print-out-paths .#deploy-rs)/bin/deploy
logdir=$(mktemp -d "${TMPDIR:-/tmp}/update-servers.XXXXXX")

# One host: skip it if unreachable, otherwise deploy. Runs in the background,
# one per host, so a slow or broken host neither delays nor aborts the others;
# output goes to a per-host log and the outcome to a status file.
deploy_one() {
  local node=$1 start=$SECONDS
  # Fast reachability pre-check — a dead host fails in 5s instead of hanging
  # deploy-rs on a long SSH timeout. Node names resolve via ~/.ssh/config.
  if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$node" true 2> /dev/null; then
    echo skipped > "$logdir/$node.status"
    echo "⏭️  $node unreachable — skipped"
  # --skip-checks: deploy-rs's own check is `nix flake check`; the gate above
  # already covered more than that.
  elif "$deploy" --skip-checks ".#$node" > "$logdir/$node.log" 2>&1; then
    echo deployed > "$logdir/$node.status"
    echo "✅ $node deployed ($((SECONDS - start))s)"
  else
    echo failed > "$logdir/$node.status"
    echo "⚠️  $node failed ($((SECONDS - start))s)"
  fi
}

echo "🚀 Deploying in parallel:" $nodes
echo "   logs: $logdir"
for node in $nodes; do
  deploy_one "$node" &
done
wait

deployed=""
skipped=""
failed=""
for node in $nodes; do
  case "$(cat "$logdir/$node.status" 2> /dev/null)" in
    deployed) deployed="$deployed $node" ;;
    skipped) skipped="$skipped $node" ;;
    *) failed="$failed $node" ;;
  esac
done

echo ""
echo "📊 Summary:"
echo "  ✅ deployed:${deployed:- none}"
if [ -n "$skipped" ]; then
  echo "  ⏭️  skipped (unreachable):$skipped"
fi
if [ -n "$failed" ]; then
  echo "  ❌ failed:$failed"
  for node in $failed; do
    echo ""
    echo "── $node: last lines of $logdir/$node.log"
    tail -n 15 "$logdir/$node.log" 2> /dev/null | sed 's/^/   /'
  done
fi

if [ -n "$mac_system" ] && [ "$mac_system" != "$(readlink /run/current-system)" ]; then
  echo ""
  echo "💻 This Mac is not on the new config yet — run \`nup\` to switch."
fi

if [ -n "$failed" ]; then
  echo "⚠️  Pipeline finished, but some servers failed."
  exit 1
fi
echo "✅ Update pipeline complete!"
