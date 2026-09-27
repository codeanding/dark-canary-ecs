// A small pool of Den Den Mushi (transponder snails) shared by every call to Marine HQ.
const SNAILS = 20;
let inUse = 0;

export async function withDenDenMushi<T>(call: () => Promise<T>): Promise<T> {
  if (inUse >= SNAILS) {
    throw new Error("No Den Den Mushi available");
  }
  inUse++;
  try {
    return await call();
  } finally {
    inUse--; // hang up
  }
}
