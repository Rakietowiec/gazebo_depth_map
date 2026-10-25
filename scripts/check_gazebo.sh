#!/usr/bin/env bash
set -euo pipefail

echo "Gazebo models:"
gz model --list

echo
echo "Gazebo camera topics (none expected for basic non-camera X500):"
gz topic -l | grep -E 'camera|image' || true
