#!/bin/bash
# run_physical_device.sh
# Detects the local Wi-Fi IP address and injects it into the Flutter build
# so the physical device can connect to the FastAPI backend running on this machine.

# Try to get the local IP address
if command -v ip > /dev/null; then
    IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
elif command -v hostname > /dev/null; then
    IP=$(hostname -I | awk '{print $1}')
else
    echo "Could not detect local IP address."
    exit 1
fi

if [ -z "$IP" ]; then
    echo "Could not detect local IP address."
    exit 1
fi

echo "=========================================================="
echo " Starting Flutter on Physical Device"
echo " Detected Local IP: $IP"
echo " Backend API URL: http://$IP:8000/api/v1"
echo " Make sure your FastAPI server is running on 0.0.0.0:8000!"
echo "=========================================================="

flutter run --dart-define=API_URL=http://$IP:8000/api/v1
