#!/bin/sh
set -eu

unset $(git rev-parse --local-env-vars)
repo=$(git rev-parse --show-toplevel)
for hook in pre-commit pre-push; do
  path="$repo/.githooks/$hook"
  if [ ! -f "$path" ] || [ -L "$path" ] || [ ! -x "$path" ]; then
    printf 'Required executable hook is missing: %s\n' "$path" >&2
    exit 1
  fi
done

git config --local core.hooksPath .githooks
