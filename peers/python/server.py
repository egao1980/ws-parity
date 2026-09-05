#!/usr/bin/env python3
"""Echo WebSocket server. Prints LISTEN then CLOSE <code> when a peer disconnects."""

from __future__ import annotations

import asyncio
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
    try:
        import websockets
    except ImportError:
        print("SKIP no websockets", file=sys.stderr)
        raise SystemExit(2)
    async with websockets.serve(handler, "127.0.0.1", port):
        print(f"LISTEN {port}", flush=True)
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
