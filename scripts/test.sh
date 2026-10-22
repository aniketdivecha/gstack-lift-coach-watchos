#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/WristCoachKit"

DEVELOPER_DIR_PATH="$(xcode-select -p 2>/dev/null || true)"
CLT_PLUGIN_DIR="/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"

if [[ "$DEVELOPER_DIR_PATH" == *CommandLineTools* && -d "$CLT_PLUGIN_DIR" ]]; then
  # Command Line Tools keeps the Swift Testing macros in a subdirectory that
  # SwiftPM does not search by default.
  exec swift test -Xswiftc -plugin-path -Xswiftc "$CLT_PLUGIN_DIR"
else
  exec swift test
fi
