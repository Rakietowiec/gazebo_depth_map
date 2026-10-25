#!/usr/bin/env bash
set -eo pipefail

ros_setup=/opt/ros/jazzy/setup.bash
workspace_setup="${ROS_WORKSPACE:-$HOME/ae_stereo_ws}/install/setup.bash"

if [[ ! -f "$ros_setup" || ! -f "$workspace_setup" ]]; then
  echo "Missing ROS Jazzy or built workspace setup file." >&2
  echo "Expected: $ros_setup and $workspace_setup" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$ros_setup"
# shellcheck source=/dev/null
source "$workspace_setup"

echo "Discovered ROS 2 topics:"
ros2 topic list --no-daemon

echo
read -r -p "Show live PX4 vehicle status? [y/N] " reply
if [[ "$reply" == [yY] ]]; then
  ros2 topic echo /fmu/out/vehicle_status_v1 --qos-reliability best_effort
fi
