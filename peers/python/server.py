#!/usr/bin/env python3
"""Echo WebSocket server. Prints LISTEN then CLOSE <code> when a peer disconnects.

Optional argv[2] / argv[3] are PEM cert and key for WSS.
"""

from __future__ import annotations

import asyncio
import ssl
import sys


async def handler(ws) -> None:
    try:
        async for msg in ws:
            await ws.send(msg)
    finally:
        code = ws.close_code if ws.close_code is not None else 1000
        print(f"CLOSE {code}", flush=True)


async def main() -> None:
    port = int(sys.argv[1])
    cert = sys.argv[2] if len(sys.argv) > 2 else None
    key = sys.argv[3] if len(sys.argv) > 3 else None
    try:
        import websockets
    except ImportError:
        print("SKIP no websockets", file=sys.stderr)
        raise SystemExit(2)
    ssl_ctx = None
    if cert and key:
        ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_ctx.load_cert_chain(certfile=cert, keyfile=key)
    async with websockets.serve(handler, "127.0.0.1", port, ssl=ssl_ctx):
        print(f"LISTEN {port}", flush=True)
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
