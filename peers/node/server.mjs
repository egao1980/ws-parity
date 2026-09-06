import { readFileSync } from "fs";
import { createServer as createHttpsServer } from "https";
import { WebSocketServer } from "ws";

const port = Number(process.argv[2]);
const cert = process.argv[3];
const key = process.argv[4];

function onConnection(ws) {
  ws.on("message", (data, isBinary) => {
    ws.send(data, { binary: isBinary });
  });
  ws.on("close", (code) => {
    console.log(`CLOSE ${code}`);
  });
}

if (cert && key) {
  const https = createHttpsServer({
    cert: readFileSync(cert),
    key: readFileSync(key),
  });
  const wss = new WebSocketServer({
    server: https,
    path: "/echo",
    perMessageDeflate: true,
  });
  wss.on("connection", onConnection);
  https.listen(port, "127.0.0.1", () => {
    console.log(`LISTEN ${port}`);
  });
} else {
  const wss = new WebSocketServer({
    host: "127.0.0.1",
    port,
    path: "/echo",
    perMessageDeflate: true,
  });
  wss.on("listening", () => {
    console.log(`LISTEN ${port}`);
  });
  wss.on("connection", onConnection);
}
