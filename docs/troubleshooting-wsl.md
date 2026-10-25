# Troubleshooting — Windows WSL2 / PX4 / Gazebo / ROS 2

These are issues encountered while building the environment on 25 October 2026.

## `wsl` not recognised in Windows PowerShell

The active PowerShell process was **32-bit**, although the Windows operating system was **64-bit**. The 32-bit process could not find `wsl.exe` through normal system path resolution.

Check:

```powershell
[Environment]::Is64BitOperatingSystem
[Environment]::Is64BitProcess
```

From 32-bit PowerShell, open 64-bit PowerShell:

```powershell
& "$env:windir\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
```

Then install WSL (if necessary):

```powershell
wsl.exe --install
```

## Accidentally installed a different Ubuntu distribution

The generic `wsl.exe --install` created a distribution named `Ubuntu`. We installed the separate, specifically supported `Ubuntu-24.04` distribution:

```powershell
wsl --install -d Ubuntu-24.04
wsl --list --verbose
wsl -d Ubuntu-24.04
```

Each WSL distribution has its own Linux user and packages. A downloaded Ubuntu `.iso` in Windows Downloads is **not** the WSL distribution.

## `ros-jazzy-ros-gzharmonic` not found

Use the correct ROS 2 Jazzy package:

```bash
sudo apt update
sudo apt install -y ros-jazzy-ros-gz
```

## Gazebo model missing in the graphical Entity Tree

The simulation server had successfully spawned the X500 even though the GUI showed no model.

Verify via a separate Ubuntu terminal:

```bash
gz model --list
```

Expected entries included `ground_plane` and `x500_0`. The graphical view was restored by closing **only the Gazebo GUI** (not the PX4/agent servers) and launching:

```bash
gz sim -g -v 4
```

## ROS only shows `/parameter_events` and `/rosout`

These are regular ROS topics, not the PX4 telemetry feed. Check:

1. DDS Agent terminal is still running on UDP 8888.
2. PX4 SITL started and displays messages about DDS client synchronisation / publisher creation.
3. Agent terminal shows `session established`.
4. Source the correct ROS environment and workspace.

```bash
source /opt/ros/jazzy/setup.bash
source ~/ae_stereo_ws/install/setup.bash
ros2 daemon stop
ros2 topic list --no-daemon
```

PX4 1.17 can publish versioned topic names. The confirmed working topic was:

```bash
ros2 topic echo /fmu/out/vehicle_status_v1 --qos-reliability best_effort
```

If the topics still do not appear, inspect:

```bash
printenv | grep -E 'ROS_DOMAIN_ID|RMW_IMPLEMENTATION|ROS_LOCALHOST_ONLY|ROS_AUTOMATIC_DISCOVERY_RANGE'
```

## Gazebo startup XML warnings

The simulator logged SDF warnings about `gz_frame_id` under some sensors. Despite these warnings, `x500_0` spawned and flight simulation worked. Avoid editing upstream model definitions solely to suppress those warnings.

## PX4 preflight and timing warnings

One run had IMU timestamp warnings. Treat repeated timing errors or failed preflight checks as a real diagnostic issue. Do **not** force arming to bypass checks. `No connection to the GCS` was expected when QGroundControl was closed.
