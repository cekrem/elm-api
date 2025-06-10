const http = require("http");
const { Elm } = require("./elm.js");

// Initialize Elm app
const app = Elm.Main.init();

// Track pending requests by ID
const pendingRequests = new Map();
let requestIdCounter = 0;

// Body reader (handles both GET and POST)
function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk.toString()));
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

// Listen for responses from Elm
app.ports.sendResponse.subscribe(([requestId, statusCode, maybeBody]) => {
  const pendingRequest = pendingRequests.get(requestId);
  if (pendingRequest) {
    const body = maybeBody ?? "";
    pendingRequest.res.writeHead(statusCode, {
      "Content-Type": "application/json",
    });
    pendingRequest.res.end(body);
    pendingRequests.delete(requestId);
  }
});

// Start HTTP server
http
  .createServer(async (req, res) => {
    const requestId = ++requestIdCounter;
    const method = req.method;
    const path = req.url;

    // Store the response object for this request
    pendingRequests.set(requestId, { res });

    // Read body only for non-GET requests
    const rawBody =
      method === "POST" || method === "PUT" || method === "PATCH"
        ? await readBody(req)
        : "";

    const body = rawBody.length > 0 ? rawBody : null;

    const elmRequest = { requestId, method, path, body };
    app.ports.receiveRequest.send(elmRequest);
  })
  .listen(3000, () => {
    console.log("Listening on http://localhost:3000");
  });
