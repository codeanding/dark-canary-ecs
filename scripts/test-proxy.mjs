// Local proxy that adds the test header, so a browser can show green on the real ALB URL.
// Usage: node scripts/test-proxy.mjs   (prints the Chrome command to open the test window)
import http from "node:http";
import { execSync } from "node:child_process";

const target = new URL(execSync("terraform -chdir=infra output -raw prod_url", { encoding: "utf8" }).trim());
const PORT = 8081;
const agent = new http.Agent({ keepAlive: false });

http
  .createServer((req, res) => {
    // As a browser proxy, the request line has the full URL; as localhost, only the path.
    const url = req.url.startsWith("http") ? new URL(req.url) : null;
    const path = url ? url.pathname + url.search : req.url;
    const headers = { ...req.headers, host: target.host, "x-dark-canary": "1" };
    delete headers["proxy-connection"];

    const upstream = http.request({ host: target.host, path, method: req.method, headers, agent, timeout: 10_000 }, (up) => {
      res.writeHead(up.statusCode ?? 502, up.headers);
      up.pipe(res);
    });

    const fail = (err) => {
      // The page reloads every 2 s, so browsers cancel requests all the time: never crash on it.
      if (!res.headersSent) {
        res.writeHead(502, { "content-type": "text/plain" });
        res.end(`proxy error: ${err.message}`);
      } else {
        res.destroy();
      }
    };
    upstream.on("timeout", () => upstream.destroy(new Error("upstream timeout")));
    upstream.on("error", fail);
    req.on("error", () => upstream.destroy());
    res.on("close", () => upstream.destroy());
    req.pipe(upstream);
  })
  .listen(PORT, () => {
    console.log(`proxy ready: x-dark-canary: 1 → ${target.host}`);
    console.log("\nOpen the test window with:\n");
    console.log(
      `open -na "Google Chrome" --args --user-data-dir=/tmp/chrome-dark-canary --no-first-run ` +
        `--proxy-server="http://localhost:${PORT}" --proxy-bypass-list="*.googleapis.com;*.gstatic.com" "${target.href}"\n`,
    );
  });

process.on("uncaughtException", (err) => console.error(`proxy kept running after: ${err.message}`));
