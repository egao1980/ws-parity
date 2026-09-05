# ws-parity

Interop canary: **[`ws-protocol`](https://github.com/egao1980/ws-protocol)** `accept` / `make-ws-server` vs **Python `websockets`** and **Node `ws`**.

Lisp owns the harness and assertions. Node/Python peers are the SUT.
**CI-only — not published to GHCR.** Wave-1 is **H1 Upgrade** (RFC 6455). H2 Extended CONNECT stays in `ws-backend-websocket-driver` tests.

```
Lisp client  →  Lisp server
Lisp client  →  Node server
Lisp client  →  Python server
Node client  →  Lisp server
Python client → Lisp server
```

Cases: text echo + close code 1000.

## Run

```bash
cd peers/node && npm install
cd ../python && uv sync
export WS_PARITY_PEERS=1
ros -l scripts/run.lisp
```

Lisp↔Lisp only:

```bash
export WS_PARITY_PEERS=0
ros -l scripts/run.lisp
```

## Matrix

See [MATRIX.md](MATRIX.md).

## Env

| Variable | Default | Meaning |
|----------|---------|---------|
| `WS_PARITY_PEERS` | on | `0` skips Node/Python peers |

permessage-deflate is out.

## License

MIT
