#!/usr/bin/env bash
set -euo pipefail

px4_dir="${PX4_DIR:-$HOME/PX4-Autopilot}"
if [[ ! -d "$px4_dir" ]]; then
  echo "PX4 not found at $px4_dir" >&2
  echo "Set PX4_DIR to the actual installation directory." >&2
  exit 1
fi

cd "$px4_dir"
echo "Starting PX4 SITL and Gazebo X500..."
exec make px4_sitl gz_x500
