#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

"$repo_root/.codex/hooks/validate_harness.sh"

for directory in Islandify IslandifyWidget Shared IslandifyTests; do
  if [ ! -d "$repo_root/$directory" ]; then
    printf 'Missing implementation directory: %s\n' "$repo_root/$directory" >&2
    exit 1
  fi
done

if [ ! -d "$repo_root/Islandify.xcodeproj" ]; then
  printf 'Missing Xcode project: %s\n' "$repo_root/Islandify.xcodeproj" >&2
  exit 1
fi

swift_files=$(find "$repo_root/Islandify" "$repo_root/IslandifyWidget" "$repo_root/Shared" "$repo_root/IslandifyTests" -type f -name '*.swift' -print)
if [ -z "$swift_files" ]; then
  printf 'No Swift sources found in the expected project directories.\n' >&2
  exit 1
fi

if command -v swiftc >/dev/null 2>&1; then
  for file in $swift_files; do
    swiftc -frontend -parse "$file" >/dev/null
  done
  printf 'Swift syntax: OK\n'
else
  printf 'Swift syntax: SKIPPED (swiftc unavailable)\n'
fi

if [ -f "$repo_root/Package.swift" ] && command -v swift >/dev/null 2>&1; then
  (cd "$repo_root" && swift test)
else
  printf 'Swift package tests: SKIPPED (Package.swift or swift unavailable)\n'
fi

if xcodebuild -version >/dev/null 2>&1; then
  xcodebuild -list -project "$repo_root/Islandify.xcodeproj"
else
  printf 'Xcode project build/list: PENDING (full Xcode is not the active developer directory)\n'
fi

(cd "$repo_root" && git diff --check)

if [ "${1:-}" = "--complete" ]; then
  if grep -Eq '^- \[ \]' "$repo_root/.codex/ticket/002-islandify-v1-goal.md"; then
    printf 'Goal completion: BLOCKED (the active goal ticket still has unchecked acceptance items)\n' >&2
    exit 1
  fi
  printf 'Goal completion checklist: OK\n'
fi

printf 'Goal verification checks: OK\n'
