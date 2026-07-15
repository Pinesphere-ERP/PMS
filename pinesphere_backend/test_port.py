import socket
import sys

host = "ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech"

for port in [443, 80, 5432]:
    print(f"Testing connection to {host}:{port}")
    try:
        s = socket.create_connection((host, port), timeout=2)
        print(f"Success: Port {port} is OPEN")
        s.close()
    except Exception as e:
        print(f"Failed: {e}")
