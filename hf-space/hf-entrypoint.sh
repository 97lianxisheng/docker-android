#!/bin/bash
set -e

# HF Space 对外只暴露 PORT（7860），将流量转发到容器内 ADB 5555
echo "Forwarding HF port ${PORT:-7860} -> ADB 5555 ..."
socat "TCP-LISTEN:${PORT:-7860},fork,reuseaddr" TCP:127.0.0.1:5555 &

exec /opt/start-emulator.sh
