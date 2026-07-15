import socket
import sys

host = "52.45.105.76"  # IPv4 for Neon
port = 5432

print(f"Testing IPv4 connection to {host}:{port}")
try:
    s = socket.create_connection((host, port), timeout=3)
    print("Success: Port 5432 is OPEN over IPv4")
    s.close()
except Exception as e:
    print(f"Failed: {e}")
