// Bundles each hook (hooks/<name>/index.ts) into hooks/dist/<name>/index.mjs for Terraform to zip.
import { build } from "esbuild";
import { readdirSync, existsSync } from "node:fs";

const hooks = readdirSync(".", { withFileTypes: true })
  .filter((d) => d.isDirectory() && existsSync(`${d.name}/index.ts`))
  .map((d) => d.name);

await Promise.all(
  hooks.map((name) =>
    build({
      entryPoints: [`${name}/index.ts`],
      outfile: `dist/${name}/index.mjs`,
      bundle: true,
      platform: "node",
      target: "node22",
      format: "esm",
      // The bundled AWS SDK still calls require() for Node built-ins.
      banner: { js: "import { createRequire } from 'node:module'; const require = createRequire(import.meta.url);" },
    }),
  ),
);
console.log(`built: ${hooks.join(", ")}`);
