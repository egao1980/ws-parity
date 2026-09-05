#!/usr/bin/env python3
"""Connect, send one text frame, print the echo, close with a code."""

from __future__ import annotations

import asyncio
import sys


async def main() -> None:
    url = sys.argv[1]
    payload = sys.argv[2] if len(sys.argv) > 2 else "ping"
    code = int(sys.argv[3]) if len(sys.argv) > 3 else 1000
    try:
        import websockets
    except ImportError:
        print("SKIP no websockets", file=sys.stderr)
        raise SystemExit(2)
    async with websockets.connect(url) as ws:
        await ws.send(payload)
        print(await ws.recv(), flush=True)
        await ws.close(code=code, reason="bye")
    print(f"CLOSE {code}", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
