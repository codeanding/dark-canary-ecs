import { createServer, type ServerResponse } from "node:http";
import type { Bounty } from "./bounties.js";

export interface Ship {
  name: string;
  color: string;
  getBounties: () => Promise<Bounty[]>;
}

// Baked into the image at build time: which release this image is (v1, v2-broken, v2-fixed).
const VERSION = process.env.APP_VERSION ?? "dev";
const PORT = Number(process.env.PORT ?? 3000);

function json(res: ServerResponse, status: number, body: unknown) {
  res.writeHead(status, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
}

function page(ship: Ship, bounties: Bounty[] | null, error: string | null) {
  const rows = (bounties ?? [])
    .map((b) => `<li><strong>${b.name}</strong> “${b.epithet}” — ฿${b.berries.toLocaleString("en-US")}</li>`)
    .join("");
  return `<!doctype html>
<html><head><meta charset="utf-8"><meta http-equiv="refresh" content="2">
<title>${ship.name} · ${VERSION}</title>
<style>
  body { margin: 0; font: 20px/1.4 system-ui, sans-serif; background: ${ship.color}; color: #fff; }
  main { max-width: 760px; margin: 0 auto; padding: 32px 16px; }
  h1 { font-size: 56px; margin: 0; } .version { font-size: 28px; opacity: .85; }
  ul { background: rgba(0,0,0,.2); border-radius: 12px; padding: 16px 16px 16px 40px; }
  .error { background: #b00020; border-radius: 12px; padding: 16px; font-size: 28px; }
  .at { opacity: .7; font-size: 16px; }
</style></head>
<body><main>
  <h1>🏴‍☠️ ${ship.name}</h1>
  <div class="version">${VERSION}</div>
  <h2>Wanted</h2>
  ${error ? `<div class="error">🐌 ${error}</div>` : `<ul>${rows}</ul>`}
  <p class="at">${new Date().toISOString()}</p>
</main></body></html>`;
}

export function sail(ship: Ship) {
  createServer(async (req, res) => {
    switch (req.url) {
      case "/health":
        return json(res, 200, { status: "ok" });
      case "/version":
        return json(res, 200, { version: VERSION, ship: ship.name, at: new Date().toISOString() });
      case "/api/bounties":
        try {
          return json(res, 200, { version: VERSION, ship: ship.name, bounties: await ship.getBounties() });
        } catch (err) {
          return json(res, 500, { version: VERSION, ship: ship.name, error: (err as Error).message });
        }
      case "/":
        try {
          const bounties = await ship.getBounties();
          res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
          return res.end(page(ship, bounties, null));
        } catch (err) {
          res.writeHead(500, { "content-type": "text/html; charset=utf-8" });
          return res.end(page(ship, null, (err as Error).message));
        }
      default:
        return json(res, 404, { error: "not found" });
    }
  }).listen(PORT, () => console.log(`${ship.name} (${VERSION}) listening on :${PORT}`));
}
