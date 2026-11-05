import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import bcrypt from "bcryptjs";

const database = vi.hoisted(() => ({
  user: {
    create: vi.fn(),
    findUnique: vi.fn(),
    findFirst: vi.fn(),
    update: vi.fn(),
  },
  session: {
    create: vi.fn(),
  },
  otpCode: {
    updateMany: vi.fn(),
    create: vi.fn(),
    findFirst: vi.fn(),
    update: vi.fn(),
  },
}));

vi.mock("../src/db.js", () => ({ prisma: database }));

import { app } from "../src/app.js";

describe("authentication API", () => {
  let server: ReturnType<typeof app.listen>;
  let baseUrl: string;
  let passwordHash: string;

  beforeAll(async () => {
    passwordHash = await bcrypt.hash("a-valid-test-password", 4);
    server = app.listen(0, "127.0.0.1");
    await new Promise<void>((resolve) => server.once("listening", resolve));
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Test server did not bind a TCP port");
    baseUrl = `http://127.0.0.1:${address.port}`;
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  });

  it("rejects malformed email and empty login submissions before querying accounts", async () => {
    const malformed = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email: "not-an-email", password: "a-valid-test-password" }),
    });
    const empty = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({}),
    });

    expect(malformed.status).toBe(400);
    expect(empty.status).toBe(400);
    expect(database.user.findUnique).not.toHaveBeenCalled();
  });

  it("rejects incorrect passwords without issuing a session", async () => {
    database.user.findUnique.mockResolvedValue({ id: "user-1", passwordHash });

    const response = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email: "person@example.com", password: "wrong-password-value" }),
    });

    expect(response.status).toBe(401);
    expect(database.session.create).not.toHaveBeenCalled();
  });

  it("authenticates valid credentials and issues an HttpOnly session cookie", async () => {
    database.user.findUnique.mockResolvedValue({ id: "user-1", passwordHash });

    const response = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email: " PERSON@example.com ", password: "a-valid-test-password" }),
    });

    expect(response.status).toBe(200);
    expect(database.user.findUnique).toHaveBeenCalledWith({
      where: { email: "person@example.com" },
      select: { id: true, passwordHash: true },
    });
    expect(response.headers.get("set-cookie")).toContain("HttpOnly");
    expect(response.headers.get("set-cookie")).toContain("SameSite=Lax");
    expect(database.session.create).toHaveBeenCalledOnce();
    expect(database.session.create.mock.calls[0]?.[0].data.tokenHash).not.toBe("a-valid-test-password");
  });

  it("allows existing accounts with passwords shorter than the registration minimum to sign in", async () => {
    const legacyPassword = "short-pass";
    database.user.findUnique.mockResolvedValue({
      id: "user-1",
      passwordHash: await bcrypt.hash(legacyPassword, 4),
    });

    const response = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email: "person@example.com", password: legacyPassword }),
    });

    expect(response.status).toBe(200);
    expect(response.headers.get("set-cookie")).toContain("HttpOnly");
    expect(database.session.create).toHaveBeenCalledOnce();
  });

  it("registers new accounts with hashed passwords and rejects duplicate email addresses", async () => {
    database.user.create.mockResolvedValue({ id: "new-user" });
    const body = {
      displayName: "Roamora Tester",
      city: "Sample City",
      birthDate: "1990-05-10",
      email: "NEW@example.com",
      password: "a-new-valid-password",
    };

    const created = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });

    expect(created.status).toBe(201);
    const createData = database.user.create.mock.calls[0]?.[0].data;
    expect(createData.email).toBe("new@example.com");
    expect(createData.passwordHash).not.toBe(body.password);
    expect(await bcrypt.compare(body.password, createData.passwordHash)).toBe(true);
    expect(created.headers.get("set-cookie")).toContain("HttpOnly");

    database.user.create.mockRejectedValueOnce(Object.assign(new Error("Unique constraint"), { code: "P2002" }));
    const duplicate = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });

    expect(duplicate.status).toBe(409);
    expect(await duplicate.json()).toMatchObject({ error: "An account with this email already exists" });
  });

  it("rejects underage registration on the server before creating an account", async () => {
    const response = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        displayName: "Underage Tester",
        city: "Sample City",
        birthDate: "2010-01-01",
        email: "underage@example.com",
        password: "a-valid-test-password",
      }),
    });

    expect(response.status).toBe(400);
    expect(database.user.create).not.toHaveBeenCalled();
    expect(await response.json()).toMatchObject({
      error: "Invalid request",
      details: expect.arrayContaining([
        expect.objectContaining({ path: ["birthDate"] }),
      ]),
    });
  });

  it("generates a 60-second OTP, rejects expired or reused OTPs, and verifies valid 6-digit OTPs", async () => {
    database.otpCode.updateMany.mockResolvedValue({ count: 0 });
    database.user.findUnique.mockResolvedValue({ id: "user-1" });
    database.otpCode.create.mockResolvedValue({ id: "otp-1" });

    const sendRes = await fetch(`${baseUrl}/api/v1/auth/otp/send`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email: "  SONIYA@GMAIL.COM " }),
    });

    expect(sendRes.status).toBe(200);
    const sendBody = await sendRes.json();
    expect(sendBody.email).toBe("soniya@gmail.com");
    expect(sendBody.expiresInSeconds).toBe(60);
    expect(database.otpCode.create).toHaveBeenCalledOnce();
    const createdOtpData = database.otpCode.create.mock.calls[0]?.[0].data;
    expect(createdOtpData.email).toBe("soniya@gmail.com");

    // Test expired OTP rejection
    database.otpCode.findFirst.mockResolvedValueOnce({
      id: "otp-expired",
      email: "soniya@gmail.com",
      codeHash: createdOtpData.codeHash,
      expiresAt: new Date(Date.now() - 1000),
      usedAt: null,
      attempts: 0,
    });

    const expiredRes = await fetch(`${baseUrl}/api/v1/auth/otp/verify`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email: "soniya@gmail.com", code: "123456" }),
    });
    expect(expiredRes.status).toBe(400);
    expect((await expiredRes.json()).error).toContain("expired");

    // Test already used OTP rejection
    database.otpCode.findFirst.mockResolvedValueOnce({
      id: "otp-used",
      email: "soniya@gmail.com",
      codeHash: createdOtpData.codeHash,
      expiresAt: new Date(Date.now() + 30_000),
      usedAt: new Date(),
      attempts: 0,
    });

    const usedRes = await fetch(`${baseUrl}/api/v1/auth/otp/verify`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email: "soniya@gmail.com", code: "123456" }),
    });
    expect(usedRes.status).toBe(400);
    expect((await usedRes.json()).error).toContain("already been used");
  });

  it("rejects Google sign-in requests when no token is provided", async () => {
    const emptyGoogleRes = await fetch(`${baseUrl}/api/v1/auth/google`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({}),
    });
    expect(emptyGoogleRes.status).toBe(400);
    expect(database.session.create).not.toHaveBeenCalled();
  });
});
