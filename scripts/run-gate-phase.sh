#!/bin/sh
set -eu

phase=${1:-}
case "$phase" in
  commit) timeout=180 ;;
  push) timeout=900 ;;
  *)
    printf '%s\n' 'usage: run-gate-phase.sh <commit|push>' >&2
    exit 64
    ;;
esac
shift

unset $(git rev-parse --local-env-vars)
repo=$(git rev-parse --show-toplevel)
cd "$repo"

global_hooks=$(git config --global --path --get core.hooksPath 2>/dev/null || true)
if [ -n "$global_hooks" ]; then
  case "$global_hooks" in
    /*) global_hook="$global_hooks/pre-$phase" ;;
    *) global_hook="$repo/$global_hooks/pre-$phase" ;;
  esac
  local_hook="$repo/.githooks/pre-$phase"
  if [ -x "$global_hook" ] && [ "$global_hook" != "$local_hook" ]; then
    "$global_hook" "$@"
  fi
fi

hard_eng_root=${HARD_ENG_ROOT:-"$HOME/.agents"}
gate="$hard_eng_root/skills/deterministic-checks/scripts/project_gate.py"
if [ ! -f "$gate" ]; then
  printf 'Hard Eng project gate is unavailable: %s\n' "$gate" >&2
  exit 1
fi

exec "${HARD_ENG_PYTHON:-python3}" "$gate" phase --repo "$repo" --timeout "$timeout" --phase "$phase"
