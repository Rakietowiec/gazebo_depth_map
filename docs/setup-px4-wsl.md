# PX4 + Gazebo + ROS 2 environment setup

> Scope: reproduction of a **tested simulation and telemetry environment** for the Gazebo stereo-depth project. Camera and depth-estimation components have not been implemented or verified yet.

## Verified environment (25 October 2026)

| Component | Selection | Verification |
|---|---|---|
| Host | Windows running WSL2 | Ubuntu launched successfully |
| Linux | Ubuntu 24.04 LTS | Used for simulation |
| PX4 | v1.17.0 | PX4 SITL started, X500 takeoff and landing |
| Gazebo | Harmonic (Gazebo Sim 8.15.0) | `x500_0` spawned and displayed |
| QGroundControl | Linux AppImage (version not recorded) | Connected to PX4, controlled vehicle |
| ROS 2 | Jazzy | Working ROS commands and PX4 topic subscriber |
| Micro XRCE-DDS Agent | v2.4.3 | PX4 session established and publishers created |
| PX4 ROS messages | `px4_msgs` `release/1.17` | Workspace built and `/fmu/out/vehicle_status_v1` read |
| Gazebo to ROS 2 bridge | `ros-jazzy-ros-gz` | Package installed; camera bridge not yet tested |
| OpenCV | `python3-opencv` | Installed; stereo pipeline not yet tested |

### Important architectural distinction

- **PX4 <-> Gazebo**: PX4's Gazebo simulator integration provides simulated vehicle dynamics and sensors.
- **PX4 <-> ROS 2**: PX4's `uxrce_dds_client` connects to Micro XRCE-DDS Agent (`udp4`, port 8888). The agent exposes PX4's DDS data to ROS 2.
- **Gazebo camera images -> ROS 2**: use `ros_gz_bridge`/`ros_gz_image`, not Micro XRCE-DDS Agent.

## 1. WSL2 + Ubuntu 24.04

From **64-bit Windows PowerShell**:

```powershell
wsl --install -d Ubuntu-24.04
wsl -d Ubuntu-24.04
```

If WSL was installed already, the first line is unnecessary. Create a Linux user when prompted. The WSL username may differ from the Windows username. In Ubuntu, verify:

```bash
lsb_release -a
```

If the default Ubuntu distribution was installed first, keep in mind that `Ubuntu` and `Ubuntu-24.04` are separate WSL installations, with different Linux usernames, packages and home directories.

Windows WSL shells sometimes begin in `/mnt/c/Users/USERNAME` rather than Linux `~`; run `cd ~` when installing Linux packages or cloning large Linux software projects.

All subsequent installation commands are **inside Ubuntu**, not PowerShell or the PX4 `pxh>` console.

## 2. Install PX4 + Gazebo Harmonic

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl
cd ~
git clone --recursive --branch v1.17.0 https://github.com/PX4/PX4-Autopilot.git
bash ~/PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx
```

Restart WSL from **Windows PowerShell** after the dependency script completes:

```powershell
wsl --shutdown
wsl -d Ubuntu-24.04
```

Launch simulator from Ubuntu:

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500
```

Expected: a `pxh>` console and Gazebo world with a model named `x500_0`. At the `pxh>` prompt, the commands below were verified with QGroundControl connected and preflight checks passing:

```text
commander takeoff
commander land
```

Do not bypass failed preflight checks.

## 3. QGroundControl

Official installation guide: https://docs.qgroundcontrol.com/master/en/qgc-user-guide/getting_started/download_and_install.html

Download the **Linux x86_64 AppImage**. To move it from your Windows Downloads folder into Ubuntu without guessing the Windows username, open the Ubuntu home folder from the Ubuntu terminal:

```bash
cd ~
explorer.exe .
```

A Windows File Explorer window appears showing the Ubuntu home folder. In another File Explorer window, copy the downloaded QGroundControl `.AppImage` from Windows Downloads, then paste it into the Ubuntu folder.

Then:

```bash
sudo apt install -y libfuse2t64 libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor0
cd ~
chmod +x QGroundControl*.AppImage
./QGroundControl*.AppImage
```

QGroundControl connected to the X500 simulator and a simulated takeoff and landing succeeded.

## 4. Install ROS 2 Jazzy

Follow the current **Ubuntu 24.04/Jazzy deb package repository setup** at:
https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html

The original environment was prepared with the following repository setup. The official documentation should take precedence if it changes:

```bash
sudo apt update
sudo apt install -y locales curl software-properties-common
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
sudo add-apt-repository universe -y

export ROS_APT_SOURCE_VERSION=$(curl -s \
  https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
  | grep -F '"tag_name"' | awk -F'"' '{print $4}')

curl -L -o /tmp/ros2-apt-source.deb \
  "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"

sudo dpkg -i /tmp/ros2-apt-source.deb
sudo apt update
sudo apt install -y ros-jazzy-desktop ros-dev-tools
source /opt/ros/jazzy/setup.bash
```

If the downloaded repository installer fails (for example, its release filename has changed), refer back to the official ROS installation instructions instead of guessing a filename.

Optional: source ROS in future interactive shells by adding this line once to `~/.bashrc`:

```bash
source /opt/ros/jazzy/setup.bash
```

Verify:

```bash
ros2 --help
```

## 5. Install Gazebo/ROS integration and image-processing packages

```bash
sudo apt install -y \
  ros-jazzy-ros-gz \
  ros-jazzy-cv-bridge \
  ros-jazzy-image-transport \
  ros-jazzy-rqt-image-view \
  python3-opencv \
  python3-numpy

ros2 pkg executables ros_gz_bridge
```

**Correct package:** `ros-jazzy-ros-gz`. The attempted name `ros-jazzy-ros-gzharmonic` does not exist in the standard Jazzy apt repository.

## 6. Install Micro XRCE-DDS Agent

```bash
sudo apt install -y git cmake build-essential
cd ~
git clone -b v2.4.3 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git
cd ~/Micro-XRCE-DDS-Agent
mkdir -p build
cd build
cmake ..
make -j4
sudo make install
sudo ldconfig /usr/local/lib/
MicroXRCEAgent --help
```

## 7. Build matching PX4 ROS message definitions

```bash
mkdir -p ~/ae_stereo_ws/src
cd ~/ae_stereo_ws/src
git clone -b release/1.17 https://github.com/PX4/px4_msgs.git
cd ~/ae_stereo_ws
source /opt/ros/jazzy/setup.bash
colcon build --symlink-install
source ~/ae_stereo_ws/install/setup.bash
```

Use the message definitions compatible with the selected PX4 firmware.

## 8. Launch three terminals for communication test

**Terminal 1 – DDS Agent:**

```bash
MicroXRCEAgent udp4 -p 8888
```

**Terminal 2 – PX4 SITL + Gazebo:**

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500
```

**Terminal 3 – ROS 2:**

```bash
source /opt/ros/jazzy/setup.bash
source ~/ae_stereo_ws/install/setup.bash
ros2 daemon stop
ros2 topic list --no-daemon
ros2 topic echo /fmu/out/vehicle_status_v1 --qos-reliability best_effort
```

**Verified result:** PX4 synchronised with the agent, the agent established a client session, and ROS 2 continuously printed `VehicleStatus` messages on `/fmu/out/vehicle_status_v1`. Use `Ctrl+C` to stop `ros2 topic echo`.

Successful diagnostic excerpts (abridged; not a complete log):

```text
INFO [init] Gazebo simulator 8.15.0
INFO [init] Gazebo world is ready
INFO [gz_bridge] world: default, model: x500_0
INFO [px4] Startup script returned successfully
[agent] session established
INFO [uxrce_dds_client] synchronized with time offset ...
INFO [uxrce_dds_client] successfully created rt/fmu/out/vehicle_status_v1 data writer
```

Example fields in the observed ROS `VehicleStatus` stream included `arming_state: 1`, `failsafe: false`, `gcs_connection_lost: true`, `power_input_valid: true`, and `pre_flight_checks_pass: false`. These are one snapshot, not a statement that preflight was ready for flight at that moment.

## 9. Launch convenience scripts (after adding the files in this contribution)

Use separate Ubuntu terminals in the cloned project directory:

```bash
bash scripts/start_agent.sh
bash scripts/start_px4.sh
bash scripts/check_ros.sh
```

These are wrappers around manually verified commands; the wrapper files themselves still need a first run on the teammate's machine. Browser-uploaded `.sh` files may not have an executable bit, so launch them with `bash`.

## 10. Next unverified camera experiment

With the default PX4 simulation stopped, try PX4's mono-camera variant:

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500_mono_cam
```

Identify the **actual** Gazebo camera topic; do not assume a hard-coded name:

```bash
gz topic -l | grep -E 'camera|image'
```

Bridge it to ROS 2 and inspect the image before adding a second camera. This test has **not yet been completed**.

## References

- https://docs.px4.io/v1.17/en/
- https://docs.px4.io/main/en/sim_gazebo_gz/
- https://gazebosim.org/docs/harmonic/
- https://docs.ros.org/en/jazzy/
- https://github.com/PX4/px4_msgs
- https://github.com/eProsima/Micro-XRCE-DDS-Agent

