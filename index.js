const http = require("http");
const { Elm } = require("./elm.js");

// Initialize Elm app
const app = Elm.Main.init();

// Body reader (handles both GET and POST)
function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk.toString()));
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

// Start HTTP server
http
  .createServer(async (req, res) => {
    const method = req.method;
    const path = req.url;

    // Read body only for non-GET requests
    const rawBody =
      method === "POST" || method === "PUT" || method === "PATCH"
        ? await readBody(req)
        : "";

    const body = rawBody.length > 0 ? rawBody : null;

    const elmInput = [method, path, body];

    const onResponse = ([statusCode, maybeBody]) => {
      const body = maybeBody ?? "";
      res.writeHead(statusCode, { "Content-Type": "application/json" });
      res.end(body);
      app.ports.sendResponse.unsubscribe(onResponse); // prevent memory leak
    };

    app.ports.sendResponse.subscribe(onResponse);
    app.ports.receiveRequest.send(elmInput);
  })
  .listen(3000, () => {
    console.log("Listening on http://localhost:3000");
  });
