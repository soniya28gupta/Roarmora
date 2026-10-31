import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

const userId = "00000000-0000-4000-8000-000000000001";
const targetUserId = "00000000-0000-4000-8000-000000000002";

const database = vi.hoisted(() => ({
  session: { findUnique: vi.fn() },
  user: { findUnique: vi.fn() },
  block: { findFirst: vi.fn() },
  swipe: { upsert: vi.fn(), findFirst: vi.fn() },
  match: { upsert: vi.fn() },
  $transaction: vi.fn(),
}));

vi.mock("../src/db.js", () => ({ prisma: database }));

import { app } from "../src/app.js";

describe("discovery swipe API", () => {
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
      userId,
      expiresAt: new Date(Date.now() + 60_000),
    });
    database.$transaction.mockImplementation((operation) => operation(database));
    database.user.findUnique.mockResolvedValue({ id: targetUserId });
    database.block.findFirst.mockResolvedValue(null);
    database.swipe.upsert.mockResolvedValue({});
    database.swipe.findFirst.mockResolvedValue({ id: "mutual-like" });
    database.match.upsert.mockResolvedValue({ id: "match-1" });
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  });

  it("creates a match only when the target has already liked the authenticated user", async () => {
    const response = await fetch(`${baseUrl}/api/v1/swipes`, {
      method: "POST",
      headers: {
        cookie: "roamora_session=valid-session",
        "content-type": "application/json",
      },
      body: JSON.stringify({ targetUserId, direction: "LIKE" }),
    });

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ matched: true, matchId: "match-1" });
    expect(database.swipe.upsert).toHaveBeenCalledOnce();
    expect(database.match.upsert).toHaveBeenCalledWith({
      where: { userAId_userBId: { userAId: userId, userBId: targetUserId } },
      create: { userAId: userId, userBId: targetUserId },
      update: {},
      select: { id: true },
    });
  });

  it("does not create a match when the target has not liked back", async () => {
    database.swipe.findFirst.mockResolvedValue(null);

    const response = await fetch(`${baseUrl}/api/v1/swipes`, {
      method: "POST",
      headers: {
        cookie: "roamora_session=valid-session",
        "content-type": "application/json",
      },
      body: JSON.stringify({ targetUserId, direction: "LIKE" }),
    });

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ matched: false });
    expect(database.match.upsert).not.toHaveBeenCalled();
  });
});
