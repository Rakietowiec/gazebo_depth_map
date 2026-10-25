# Proposed stereo depth architecture and next steps

## Goal

Simulate an X500-class quadcopter with two **ordinary RGB cameras**, estimate disparity from synchronised left/right images, and use camera calibration to turn disparity into metric depth.

The final estimate should come from the two RGB images, **not** from directly consuming a simulated depth camera image. A simulator-provided ground-truth depth image may optionally be used **only for evaluation**.

## Data paths

```text
              Gazebo Harmonic
        ┌────────────────────────┐
        │ World, UAV, RGB cameras│
        └─────┬────────────┬─────┘
              │            │
      simulated physics  camera image topics
              │            │
              ▼            ▼
          PX4 SITL     ros_gz_bridge
              │            │
     uXRCE-DDS client      |
              │            |
       Micro XRCE-DDS    ROS 2 left/right
            Agent         image topics
              │            │
              ▼            ▼
         ROS 2 PX4      Image sync,
          telemetry     rectification,
                        disparity + depth

          QGroundControl <-- MAVLink --> PX4 SITL
```

## Mathematical principle

For a calibrated, rectified pinhole stereo pair:

`Z [m] = f [pixels] * B [m] / d [pixels]`

Where `f` is focal length, `B` is baseline between the two camera centres and `d` is disparity. Only pixels with valid positive disparities should be converted. The pair must have known intrinsics, extrinsics, synchronisation and rectification.

## Proposed work packages

| Work package | Task | Acceptance criterion |
|---|---|---|
| 1 | Launch PX4 mono-camera X500 | Image topic appears in Gazebo and can be viewed |
| 2 | Bridge one image into ROS 2 | ROS `sensor_msgs/Image` displays actual pixels |
| 3 | Create dual-RGB model | Left/right camera frames from fixed known baseline |
| 4 | Synchronise + rectify images | Matched time stamps and epipolar rows align |
| 5 | Compute disparity | Usable disparity image on test scene |
| 6 | Estimate metric depth | Sensible distances to known scene geometry |
| 7 | Quantitative validation | Errors measured at multiple distances |
| 8 | Flight demonstration | Depth pipeline updates during simulated motion |

## Proposed responsibilities (not yet agreed with teammate)

- **Simulation/model role:** Gazebo model, two cameras, camera SDF configuration, objects/world, vehicle launch.
- **Perception role:** ROS 2 image bridge use, synchronisation, OpenCV stereo processing, depth and error analysis.
- **Shared:** interface conventions, testing, integration, demonstration, code review and documentation.

## Next immediate commands to test (not yet validated)

Stop the old X500 simulation before starting a different PX4 SITL instance:

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500_mono_cam
```

Inspect actual Gazebo camera topic names:

```bash
gz topic -l | grep -E 'camera|image'
```

Do **not** hard-code an example topic until the real published name is known. Then run an image bridge and viewer. Only after that step works should the team modify the SDF model for two cameras.

## Code quality guidelines for future contributions

- Keep simulation models, ROS nodes and launch files in this repository; do not commit third-party PX4 or ROS installations.
- Use feature branches/PRs for separate testable changes.
- Log the PX4/Gazebo/ROS versions used to test each feature.
- Document camera calibration, baseline, image resolution and message topic names.
- Do not commit large generated build outputs, telemetry logs or ROS bags by default.
