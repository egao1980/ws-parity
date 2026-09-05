import WebSocket from "ws";

const url = process.argv[2];
const payload = process.argv[3] ?? "ping";
const code = Number(process.argv[4] ?? 1000);

const ws = new WebSocket(url);

ws.on("open", () => {
  ws.send(payload);
});

ws.on("message", (data) => {
  console.log(String(data));
  ws.close(code, "bye");
});

ws.on("close", (got) => {
  console.log(`CLOSE ${got || code}`);
});

ws.on("error", (err) => {
  console.error(err.message);
  process.exit(1);
});
