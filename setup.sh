#!/bin/bash
set -e
apt-get update
apt-get -y install python3 curl htop

cat >/opt/callsvc.py <<'EOF'
import socket, time, json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
HOST = socket.gethostname()
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = {"status": "ok"}
        elif self.path.startswith("/call"):
            end = time.time() + 0.05
            while time.time() < end: pass
            body = {"handled_by": HOST, "result": "call routed"}
        else:
            body = {"service": "nimbus-callsvc", "host": HOST}
        data = json.dumps(body).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(data)
    def log_message(self, fmt, *a):
        print(self.address_string(), fmt % a, flush=True)
ThreadingHTTPServer(("0.0.0.0", 8080), H).serve_forever()
EOF

cat >/etc/systemd/system/callsvc.service <<'EOF'
[Unit]
Description=Nimbus call service stand-in
After=network.target
[Service]
ExecStart=/usr/bin/python3 /opt/callsvc.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now callsvc
