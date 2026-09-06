#!/usr/bin/env python3
"""Connect, send one text or binary frame, print the echo, close with a code."""

from __future__ import annotations

import asyncio
import ssl
import sys


async def main() -> None:
    url = sys.argv[1]
    payload = sys.argv[2] if len(sys.argv) > 2 else "ping"
    code = int(sys.argv[3]) if len(sys.argv) > 3 else 1000
    mode = sys.argv[4] if len(sys.argv) > 4 else "text"
    try:
        import websockets
    except ImportError:
        print("SKIP no websockets", file=sys.stderr)
        raise SystemExit(2)
    ssl_ctx = None
    if url.startswith("wss:"):
        ssl_ctx = ssl._create_unverified_context()
    async with websockets.connect(url, ssl=ssl_ctx) as ws:
        if mode == "binary":
            await ws.send(payload.encode("utf-8"))
        else:
            await ws.send(payload)
        msg = await ws.recv()
        if isinstance(msg, bytes):
            print(msg.decode("utf-8"), flush=True)
        else:
            print(msg, flush=True)
        await ws.close(code=code, reason="bye")
    print(f"CLOSE {code}", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
