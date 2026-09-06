# ws-parity matrix

Status: `have` · `missing` · `skip`

| Case | Lisp→Lisp | Lisp→Node | Lisp→Python | Node→Lisp | Python→Lisp |
|------|-----------|-----------|-------------|-----------|-------------|
| text echo | have | have | have | have | have |
| close 1000 | partial | partial | partial | have* | have* |
| binary echo | have | have | have | have | have |
| H2 Extended CONNECT | have | skip | skip | skip | skip |
| permessage-deflate | have | have | have | have | have |
| WSS | have | have | have | have | have |

`have*` = foreign client *sends* 1000. Peer-observed code is often **1006** (`websocket-driver` drops TCP without a close frame). The harness accepts 1000 or 1006.

H2 is Lisp→Lisp only: driver RFC 8441 server + `http-backend-async` client. Node/Python peers stay H1.

permessage-deflate is a real RSV1 + chipz wrap in `ws-backend-websocket-driver` (stock websocket-driver has no extension hook). The canary fails if the extension is not negotiated.
