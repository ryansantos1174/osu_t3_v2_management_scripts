#!/bin/bash
#
# ===============================================================
# send_command_to_nodes.sh — Run arbitrary commands on cluster nodes
#
# Usage:
#   ./send_command_to_nodes.sh <pattern> <command>
#
# Examples:
#
#   # Run `uptime` on all compute nodes
#   ./send_command_to_nodes.sh compute uptime
#
#   # Run `hostname` only on compute nodes 0-3 through 0-6
#   ./send_command_to_nodes.sh compute-0-[3-6] hostname
#
#   # Run `date` on all interactive nodes
#   ./send_command_to_nodes.sh interactive 'date "+%T.%3N"'
#
#   # Run `df -h` only on compute nodes ending in "10"
#   ./send_command_to_nodes.sh 'compute-0-10' 'df -h'
#
#   # Run free-form regex pattern
#   ./send_command_to_nodes.sh 'compute.*' free -h
#
# Pattern shortcuts:
#   compute       → expands to compute-*  (all compute nodes)
#   interactive   → expands to interactive-* (all interactive nodes)
#
# This script uses:
#   pdsh -l root -w <expanded-pattern> <command>
#
# ===============================================================

set -e

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <pattern> <command>"
    exit 1
fi

PATTERN="$1"
shift
COMMAND="$*"

# Expand common shortcuts
case "$PATTERN" in
    compute)
        HOSTSPEC="compute-*"
        ;;
    interactive)
        HOSTSPEC="interactive-*"
        ;;
    *)
        # Use the pattern exactly as passed (regex/range/etc.)
        HOSTSPEC="$PATTERN"
        ;;
esac

echo "Running command on: $HOSTSPEC"
echo "Command: $COMMAND"
echo "----------------------------------------"

pdsh -l root -w "$HOSTSPEC" $COMMAND
