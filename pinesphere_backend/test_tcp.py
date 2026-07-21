import socket

hosts = [
    ("ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech", 5432),
    ("ep-wild-bird-atptd648-pooler.c-9.us-east-1.aws.neon.tech", 5432),
    ("ep-wild-bird-atptd648-pooler.c-9.us-east-1.aws.neon.tech", 6543),
]

for host, port in hosts:
    print(f"Testing TCP socket {host}:{port}...")
    try:
        s = socket.create_connection((host, port), timeout=5)
        print(f"  -> SUCCESS! Connected to {host}:{port}")
        s.close()
    except Exception as e:
        print(f"  -> FAILED {host}:{port}: {e}")
