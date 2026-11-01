import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

const database = vi.hoisted(() => ({
  session: { findUnique: vi.fn() },
  block: { findMany: vi.fn(), deleteMany: vi.fn(), upsert: vi.fn() },
  swipe: { deleteMany: vi.fn() },
  match: { deleteMany: vi.fn() },
  user: { findUnique: vi.fn() },
  $transaction: vi.fn(),
}));

vi.mock("../src/db.js", () => ({ prisma: database }));

import { app } from "../src/app.js";

describe("blocks management API", () => {
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
    database.$transaction.mockImplementation(async (callback: any) => callback(database));
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  });

  it("lists blocked users for authenticated user", async () => {
    database.block.findMany.mockResolvedValue([
      {
        blockerId: "user-1",
        blockedId: "target-123",
        createdAt: new Date("2026-11-01T07:00:00Z"),
        blocked: {
          id: "target-123",
          profile: {
            displayName: "Nikhil Goyal",
            imageUrl: "https://example.com/nikhil.jpg",
            photos: [],
            city: "San Francisco",
          },
        },
      },
    ]);

    const response = await fetch(`${baseUrl}/api/v1/blocks`, {
      headers: { cookie: "roamora_session=valid-session" },
    });

    expect(response.status).toBe(200);
    const data = await response.json();
    expect(data).toHaveLength(1);
    expect(data[0]).toMatchObject({
      id: "target-123",
      name: "Nikhil Goyal",
      avatarUrl: "https://example.com/nikhil.jpg",
      city: "San Francisco",
    });
  });

  it("unblocks user via DELETE /blocks/:targetUserId and clears swipes", async () => {
    database.block.deleteMany.mockResolvedValue({ count: 1 });
    database.swipe.deleteMany.mockResolvedValue({ count: 1 });

    const response = await fetch(`${baseUrl}/api/v1/blocks/target-123`, {
      method: "DELETE",
      headers: { cookie: "roamora_session=valid-session" },
    });

    expect(response.status).toBe(204);
    expect(database.block.deleteMany).toHaveBeenCalledWith({
      where: { blockerId: "user-1", blockedId: "target-123" },
    });
    expect(database.swipe.deleteMany).toHaveBeenCalledWith({
      where: {
        OR: [
          { actorId: "user-1", targetId: "target-123" },
          { actorId: "target-123", targetId: "user-1" },
        ],
      },
    });
  });

  it("unblocks user via POST /blocks/unblock", async () => {
    database.block.deleteMany.mockResolvedValue({ count: 1 });
    database.swipe.deleteMany.mockResolvedValue({ count: 1 });

    const response = await fetch(`${baseUrl}/api/v1/blocks/unblock`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        cookie: "roamora_session=valid-session",
      },
      body: JSON.stringify({ targetUserId: "281b7b37-4c4d-4315-9ce4-bf1b4853b69d" }),
    });

    expect(response.status).toBe(204);
    expect(database.block.deleteMany).toHaveBeenCalledWith({
      where: { blockerId: "user-1", blockedId: "281b7b37-4c4d-4315-9ce4-bf1b4853b69d" },
    });
  });
});

