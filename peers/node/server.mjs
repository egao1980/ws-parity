import { WebSocketServer } from "ws";

const port = Number(process.argv[2]);
const wss = new WebSocketServer({ host: "127.0.0.1", port, path: "/echo" });

wss.on("listening", () => {
  console.log(`LISTEN ${port}`);
});

wss.on("connection", (ws) => {
  ws.on("message", (data, isBinary) => {
    ws.send(data, { binary: isBinary });
  });
  ws.on("close", (code) => {
    console.log(`CLOSE ${code}`);
  });
});
