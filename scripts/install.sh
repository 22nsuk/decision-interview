#!/usr/bin/env bash
# New installation only. Run with bash; do not source this file.
set -eu

if [ "$#" -gt 1 ] || [ "${1-}" = "--help" ] || [ "${1-}" = "-h" ]; then
  printf 'Usage: bash %s [destination]\n' "$0"
  [ "$#" -le 1 ] && exit 0
  exit 2
fi

skill_source="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../skills/decision-interview" && pwd -P)"
skill_target="${1-$HOME/.agents/skills/decision-interview}"
if [ -z "$skill_target" ]; then
  printf 'Destination must not be empty.\n' >&2
  exit 2
fi
for skill_file in SKILL.md agents/openai.yaml; do
  if [ ! -f "$skill_source/$skill_file" ]; then
    printf 'Missing required source file: %s\n' "$skill_source/$skill_file" >&2
    exit 1
  fi
done
if [ -e "$skill_target" ] || [ -L "$skill_target" ]; then
  printf 'Already exists: %s\n' "$skill_target" >&2
  exit 1
fi

skill_owns_target=0
skill_installed=0
cleanup_install() {
  skill_status=$?
  trap - EXIT
  if [ "$skill_owns_target" -eq 1 ] && [ "$skill_installed" -eq 0 ]; then
    if ! rm -rf -- "$skill_target"; then
      printf 'Could not remove incomplete installation: %s\n' "$skill_target" >&2
      skill_status=1
    fi
  fi
  exit "$skill_status"
}
trap cleanup_install EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p -- "$(dirname -- "$skill_target")"
# Only a successful exclusive mkdir gives this invocation cleanup ownership.
mkdir -- "$skill_target"
skill_owns_target=1
cp -R -- "$skill_source/." "$skill_target/"
for skill_file in SKILL.md agents/openai.yaml; do
  if [ ! -f "$skill_target/$skill_file" ] ||
      ! cmp -s -- "$skill_source/$skill_file" "$skill_target/$skill_file"; then
    printf 'Installed file verification failed: %s\n' "$skill_target/$skill_file" >&2
    exit 1
  fi
done
skill_installed=1
printf 'Installed: %s\n' "$skill_target"
