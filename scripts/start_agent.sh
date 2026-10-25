#!/usr/bin/env bash
set -euo pipefail

echo "Starting PX4 Micro XRCE-DDS Agent (UDP port 8888)..."
exec MicroXRCEAgent udp4 -p 8888
