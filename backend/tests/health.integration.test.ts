import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { app } from "../src/app.js";

describe("API readiness endpoint", () => {
  const previousDatabaseUrl = process.env.DATABASE_URL;
  let server: ReturnType<typeof app.listen>;
  let baseUrl: string;

  beforeAll(async () => {
    delete process.env.DATABASE_URL;
    server = app.listen(0, "127.0.0.1");
    await new Promise<void>((resolve) => server.once("listening", resolve));
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Test server did not bind a TCP port");
    baseUrl = `http://127.0.0.1:${address.port}`;
  });

  afterAll(async () => {
    if (previousDatabaseUrl === undefined) delete process.env.DATABASE_URL;
    else process.env.DATABASE_URL = previousDatabaseUrl;
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  });

  it("reports 503 instead of implying storage is operational without configuration", async () => {
    const response = await fetch(`${baseUrl}/health`);
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ status: "unavailable", database: "not_configured" });
  });
});
