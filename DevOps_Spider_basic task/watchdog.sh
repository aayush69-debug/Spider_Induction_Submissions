#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/test_dir"
LOG_FILE="$SCRIPT_DIR/vault_sweep.log"


"$SCRIPT_DIR/vault_sweep.sh" "$TARGET_DIR"


if tail -n 20 "$LOG_FILE" | grep -q "WARN"; then

    osascript -e 'display notification "Malicious scripts or leaks found! Check vault_sweep.log immediately." with title "⚠️ Spider DevOps Security Alert" sound name "Submarine"'
fi