#!/usr/bin/env bash
# Run the actual installer in disposable destinations; never change HOME.
set -eu
test_repo="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect_failure() {
  if "$@" > "$test_root/failure.log" 2>&1; then
    fail 'installation unexpectedly succeeded'
  fi
}
assert_absent() {
  [ ! -e "$1" ] && [ ! -L "$1" ] || fail "unexpected path: $1"
}

mkdir "$test_root/elsewhere"
test_cwd=$PWD
test_options=$-
skill_source=caller-source
skill_target=caller-target
(
  cd "$test_root/elsewhere"
  bash "$test_repo/scripts/install.sh" ../real-install
)
diff -r "$test_repo/skills/decision-interview" "$test_root/real-install"
[ "$PWD" = "$test_cwd" ] && [ "$-" = "$test_options" ] &&
  [ "$skill_source" = caller-source ] && [ "$skill_target" = caller-target ] || fail 'caller state changed'
printf 'PASS: real package, different working directory, relative target, and caller scope\n'

# Add hidden/deep files to a disposable package to exercise recursive copying.
test_package="$test_root/package [원본]"
mkdir -p "$test_package/scripts" "$test_package/skills"
cp "$test_repo/scripts/install.sh" "$test_package/scripts/install.sh"
cp -R "$test_repo/skills/decision-interview" "$test_package/skills/"
test_source="$test_package/skills/decision-interview"
mkdir -p "$test_source/nested [data]/deeper"
printf 'hidden contents\n' > "$test_source/.hidden"
printf 'nested contents\n' > "$test_source/nested [data]/deeper/file.txt"
test_installer="$test_package/scripts/install.sh"
test_destination="$test_root/new parent [설치]/decision-interview"
bash "$test_installer" "$test_destination"
diff -r "$test_source" "$test_destination"
printf 'PASS: hidden files, nested directories, spaces, Unicode, and literal brackets\n'

(
  cd "$test_package"
  CDPATH=. bash scripts/install.sh "$test_root/cdpath-install"
  cd "$test_root/elsewhere"
  bash "$test_installer" -skill
)
diff -r "$test_source" "$test_root/cdpath-install"
diff -r "$test_source" "$test_root/elsewhere/-skill"
printf 'PASS: inherited CDPATH and leading-hyphen relative destination\n'

printf 'local edits\n' > "$test_destination/SKILL.md"
printf 'user file\n' > "$test_destination/keep.txt"
cp -R "$test_destination" "$test_root/before"
expect_failure bash "$test_installer" "$test_destination"
diff -r "$test_root/before" "$test_destination"
printf 'keep file\n' > "$test_root/existing-file"
expect_failure bash "$test_installer" "$test_root/existing-file"
[ "$(cat "$test_root/existing-file")" = 'keep file' ] || fail 'existing file changed'
ln -s "$test_destination" "$test_root/live-link"
ln -s "$test_root/no-such-target" "$test_root/dangling-link"
for test_link in live-link dangling-link; do
  expect_failure bash "$test_installer" "$test_root/$test_link"
  [ -L "$test_root/$test_link" ] || fail 'existing link removed'
done
diff -r "$test_root/before" "$test_destination"
assert_absent "$test_root/no-such-target"
expect_failure bash "$test_installer" ''
printf 'PASS: existing directories, files, live/dangling links, and empty destination rejected\n'

for test_required in SKILL.md agents/openai.yaml; do
  mv "$test_source/$test_required" "$test_root/saved-required-file"
  expect_failure bash "$test_installer" "$test_root/missing-source-parent/skill"
  assert_absent "$test_root/missing-source-parent"
  mv "$test_root/saved-required-file" "$test_source/$test_required"
done
printf 'PASS: either required source file missing, no destination created\n'

# Inject a competitor after preflight, immediately before the exclusive mkdir.
(
  mkdir() {
    if [ "$1" = -- ]; then
      command mkdir -- "$2"
      printf 'competitor data\n' > "$2/keep.txt"
    fi
    command mkdir "$@"
  }
  export -f mkdir
  expect_failure bash "$test_installer" "$test_root/racing-target"
)
[ "$(cat "$test_root/racing-target/keep.txt")" = 'competitor data' ] || fail 'competing target removed'
[ ! -e "$test_root/racing-target/SKILL.md" ] || fail 'copied into competing target'
printf 'PASS: target created after preflight is preserved\n'

# Controlled copy fault: write one file, then fail. The installer must clean up.
(
  cp() {
    for copy_destination; do :; done
    printf 'partial copy\n' > "$copy_destination/SKILL.md"
    return 73
  }
  export -f cp
  expect_failure bash "$test_installer" "$test_root/failed-copy"
)
assert_absent "$test_root/failed-copy"
bash "$test_installer" "$test_root/failed-copy"
diff -r "$test_source" "$test_root/failed-copy"
printf 'PASS: partial-copy failure cleanup and retry\n'

# A zero exit code is insufficient when a required file is missing or corrupt.
for test_fault in missing corrupt; do
  (
    export DECISION_TEST_FAULT="$test_fault"
    cp() {
      command cp "$@"
      for copy_destination; do :; done
      if [ "$DECISION_TEST_FAULT" = missing ]; then
        rm "$copy_destination/agents/openai.yaml"
      else
        printf 'wrong contents\n' > "$copy_destination/SKILL.md"
      fi
    }
    export -f cp
    expect_failure bash "$test_installer" "$test_root/invalid-result"
  )
  assert_absent "$test_root/invalid-result"
done
printf 'PASS: missing or corrupt copied files fail verification and clean up\n'
