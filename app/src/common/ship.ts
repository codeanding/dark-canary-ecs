import { readFile } from "node:fs/promises";
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

function poster(b: Bounty) {
  return `<article class="poster">
    <div class="wanted">WANTED</div>
    <div class="portrait" data-emoji="${b.emoji}"><img src="/crew/${b.image}" alt="${b.name}"
      onerror="this.parentElement.textContent=this.parentElement.dataset.emoji"></div>
    <div class="doa">DEAD OR ALIVE</div>
    <div class="name">${b.name}</div>
    <div class="epithet">“${b.epithet}”</div>
    <div class="bounty">฿ ${b.berries.toLocaleString("en-US")}-</div>
    <div class="marine">MARINE</div>
  </article>`;
}

function page(ship: Ship, bounties: Bounty[] | null, error: string | null) {
  const body = error
    ? `<div class="error">🐌 ${error}</div>`
    : `<section class="board">${(bounties ?? []).map(poster).join("")}</section>`;
  return `<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="2">
<title>${ship.name} · ${VERSION}</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Pirata+One&family=Rye&display=swap" rel="stylesheet">
<style>
  :root { --paper: #f1dfb8; --paper-edge: #d9c08e; --ink: #3a2410; }
  * { box-sizing: border-box; }
  body { margin: 0; font: 18px/1.4 system-ui, sans-serif; background: ${ship.color}; color: #fff; }
  main { max-width: 1180px; margin: 0 auto; padding: 28px 16px 20px; }
  header { display: flex; align-items: baseline; gap: 16px; flex-wrap: wrap; }
  h1 { font: 400 60px/1 "Pirata One", system-ui, sans-serif; margin: 0; letter-spacing: 1px; }
  .version { font: 600 22px/1 ui-monospace, monospace; background: rgba(0,0,0,.25);
             padding: 8px 14px; border-radius: 999px; }
  .board { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
           gap: 18px; margin-top: 24px; }
  .poster { background: var(--paper); color: var(--ink); text-align: center; padding: 12px 12px 10px;
            border: 3px solid var(--paper-edge); border-radius: 4px;
            box-shadow: 0 6px 14px rgba(0,0,0,.35), inset 0 0 28px rgba(120,80,30,.35);
            font-family: Rye, Georgia, serif; }
  .poster:nth-child(odd) { transform: rotate(-1.2deg); }
  .poster:nth-child(even) { transform: rotate(1deg); }
  .wanted { font-size: clamp(26px, 2.6vw, 34px); letter-spacing: 1px; line-height: 1; }
  .portrait { margin: 8px auto 6px; aspect-ratio: 1; display: grid; place-items: center; font-size: 64px;
              background: #e4cfa2; border: 2px solid var(--ink); overflow: hidden; }
  .portrait img { width: 100%; height: 100%; object-fit: cover; object-position: center top; }
  .doa { font: 700 12px/1.4 Georgia, serif; letter-spacing: 2px; }
  .name { font-size: 17px; text-transform: uppercase; margin-top: 4px; line-height: 1.15; }
  .epithet { font: italic 14px/1.3 Georgia, serif; opacity: .8; }
  .bounty { font-size: 18px; margin-top: 6px; }
  .marine { font: 10px Georgia, serif; letter-spacing: 3px; opacity: .6; margin-top: 4px; }
  .error { margin-top: 28px; background: #b00020; border-radius: 12px; padding: 28px; font-size: 32px; font-weight: 700; }
  .at { opacity: .75; font: 15px ui-monospace, monospace; margin-top: 18px; }
</style></head>
<body><main>
  <header><h1>🏴‍☠️ ${ship.name}</h1><span class="version">${VERSION}</span></header>
  ${body}
  <p class="at">${new Date().toISOString()}</p>
</main></body></html>`;
}

// Must outlive the ALB idle timeout (60 s). With Node's default 5 s, the ALB reuses
// connections Node is closing and those requests hang until the client gives up.
const KEEP_ALIVE_MS = 65_000;

export function sail(ship: Ship) {
  const server = createServer(async (req, res) => {
    const crew = req.url?.match(/^\/crew\/([a-z0-9-]+\.png)$/);
    if (crew) {
      try {
        const img = await readFile(`public/crew/${crew[1]}`);
        res.writeHead(200, { "content-type": "image/png", "cache-control": "public, max-age=3600" });
        return res.end(img);
      } catch {
        return json(res, 404, { error: "not found" });
      }
    }
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
  });
  server.keepAliveTimeout = KEEP_ALIVE_MS;
  server.headersTimeout = KEEP_ALIVE_MS + 1_000;
  server.listen(PORT, () => console.log(`${ship.name} (${VERSION}) listening on :${PORT}`));

  // As PID 1, Node ignores SIGTERM unless handled, and ECS would wait 30 s before SIGKILL.
  process.on("SIGTERM", () => {
    console.log("SIGTERM: closing server");
    server.close(() => process.exit(0));
    server.closeIdleConnections();
    setTimeout(() => process.exit(0), 10_000).unref();
  });
}
