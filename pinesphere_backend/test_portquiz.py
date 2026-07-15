import socket

host = "portquiz.net"
port = 5432

print(f"Testing connection to {host}:{port}")
try:
    s = socket.create_connection((host, port), timeout=3)
    print("Success: Port 5432 is OPEN")
    s.close()
except Exception as e:
    print(f"Failed: {e}")
