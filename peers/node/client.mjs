import WebSocket from "ws";

const url = process.argv[2];
const payload = process.argv[3] ?? "ping";
const code = Number(process.argv[4] ?? 1000);
const mode = process.argv[5] ?? "text";
const binary = mode === "binary";

const opts = url.startsWith("wss:") ? { rejectUnauthorized: false } : {};
const ws = new WebSocket(url, opts);

ws.on("open", () => {
  if (binary) {
    ws.send(Buffer.from(payload, "utf8"), { binary: true });
  } else {
    ws.send(payload);
  }
});

ws.on("message", (data) => {
  console.log(Buffer.isBuffer(data) ? data.toString("utf8") : String(data));
  ws.close(code, "bye");
});

ws.on("close", (got) => {
  console.log(`CLOSE ${got || code}`);
});

ws.on("error", (err) => {
  console.error(err.message);
  process.exit(1);
});
