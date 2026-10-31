import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

const database = vi.hoisted(() => ({
  session: { findUnique: vi.fn() },
  match: { deleteMany: vi.fn() },
}));

vi.mock("../src/db.js", () => ({ prisma: database }));

import { app } from "../src/app.js";

describe("match management API", () => {
  let server: ReturnType<typeof app.listen>;
  let baseUrl: string;

  beforeAll(async () => {
    server = app.listen(0, "127.0.0.1");
    await new Promise<void>((resolve) => server.once("listening", resolve));
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Test server did not bind a TCP port");
    baseUrl = `http://127.0.0.1:${address.port}`;
  });

  beforeEach(() => {
    vi.clearAllMocks();
    database.session.findUnique.mockResolvedValue({
      userId: "user-1",
      expiresAt: new Date(Date.now() + 60_000),
    });
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  });

  it("allows a match participant to unmatch and returns no content", async () => {
    database.match.deleteMany.mockResolvedValue({ count: 1 });

    const response = await fetch(`${baseUrl}/api/v1/matches/match-1`, {
      method: "DELETE",
      headers: { cookie: "roamora_session=valid-session" },
    });

    expect(response.status).toBe(204);
    expect(database.match.deleteMany).toHaveBeenCalledWith({
      where: {
        id: "match-1",
        OR: [{ userAId: "user-1" }, { userBId: "user-1" }],
      },
    });
  });

  it("does not reveal a match that does not belong to the authenticated user", async () => {
    database.match.deleteMany.mockResolvedValue({ count: 0 });

    const response = await fetch(`${baseUrl}/api/v1/matches/match-2`, {
      method: "DELETE",
      headers: { cookie: "roamora_session=valid-session" },
    });

    expect(response.status).toBe(404);
    expect(await response.json()).toMatchObject({ error: "Match not found" });
    expect(database.match.deleteMany).toHaveBeenCalledOnce();
  });
});
