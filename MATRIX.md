# ws-parity matrix

Status: `have` · `missing` · `skip`

| Case | Lisp→Lisp | Lisp→Node | Lisp→Python | Node→Lisp | Python→Lisp |
|------|-----------|-----------|-------------|-----------|-------------|
| text echo | have | have | have | have | have |
| close 1000 | partial | partial | partial | have* | have* |
| binary echo | skip | skip | skip | skip | skip |
| H2 Extended CONNECT | skip | skip | skip | skip | skip |
| permessage-deflate | missing | missing | missing | missing | missing |
| WSS | skip | skip | skip | skip | skip |

`have*` = foreign client *sends* 1000. Peer-observed code is often **1006** (`websocket-driver` drops TCP without a close frame). The harness accepts 1000 or 1006.

H2 server / WSS live in `ws-backend-websocket-driver` tests, not this canary.
