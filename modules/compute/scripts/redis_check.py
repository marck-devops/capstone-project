#!/usr/bin/env python3
"""Connect to the Redis instance, write and read a key, and bump a counter.

  redis_check.py           run once and print the result
  redis_check.py --serve   serve the result over HTTP on APP_HOST:APP_PORT
                           (default 0.0.0.0:8000; nginx also proxies port 80 to it)

Connection settings come from REDIS_HOST / REDIS_PORT.
"""
import os
import socket
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import redis

host = os.environ.get("REDIS_HOST", "localhost")
port = int(os.environ.get("REDIS_PORT", "6379"))

client = redis.Redis(host=host, port=port, socket_connect_timeout=5, decode_responses=True)


def check():
    """Return (ok, lines) describing the Redis round trip."""
    try:
        client.ping()
        key = f"hello:{socket.gethostname()}"
        client.set(key, "hello from the web instance")
        return True, [
            f"Connected to Redis at {host}:{port}",
            f"SET {key} -> GET {key} = {client.get(key)!r}",
            f"Visits counter = {client.incr('web:visits')}",
        ]
    except redis.exceptions.RedisError as err:
        return False, [f"Could not connect to Redis at {host}:{port}: {err}"]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/favicon.ico":
            self.send_response(404)
            self.end_headers()
            return
        ok, lines = check()
        body = ("\n".join(lines) + "\n").encode()
        self.send_response(200 if ok else 502)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    if "--serve" in sys.argv:
        app_host = os.environ.get("APP_HOST", "0.0.0.0")
        app_port = int(os.environ.get("APP_PORT", "8000"))
        print(f"Serving on {app_host}:{app_port}", flush=True)
        ThreadingHTTPServer((app_host, app_port), Handler).serve_forever()
    else:
        ok, lines = check()
        print("\n".join(lines), file=sys.stdout if ok else sys.stderr)
        sys.exit(0 if ok else 1)
