import { afterEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "@/app/api/v1/[...segments]/route";

describe("same-origin API proxy", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
  });

  it("forwards login requests and returns the HttpOnly session cookie", async () => {
    vi.stubEnv("ROAMORA_API_URL", "http://api.example.test");
    const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify({ id: "account-1" }), {
      status: 200,
      headers: {
        "content-type": "application/json",
        "set-cookie": "roamora_session=opaque; Path=/; HttpOnly; SameSite=Lax",
      },
    }));
    vi.stubGlobal("fetch", fetchMock);
    const request = new NextRequest("http://localhost/api/v1/auth/login", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        cookie: "existing_session=opaque",
      },
      body: JSON.stringify({ email: "person@example.com", password: "secret" }),
    });

    const response = await POST(request, { params: Promise.resolve({ segments: ["auth", "login"] }) });

    expect(fetchMock).toHaveBeenCalledOnce();
    const [target, options] = fetchMock.mock.calls[0]!;
    expect(target.toString()).toBe("http://api.example.test/api/v1/auth/login");
    expect(options.headers.get("cookie")).toBe("existing_session=opaque");
    expect(response.status).toBe(200);
    expect(response.headers.get("set-cookie")).toContain("HttpOnly");
    expect(await response.json()).toEqual({ id: "account-1" });
  });

  it("returns an explicit service-unavailable response when the API cannot be reached", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new TypeError("fetch failed")));
    const request = new NextRequest("http://localhost/api/v1/auth/login", {
      method: "POST",
      body: JSON.stringify({ email: "person@example.com", password: "secret" }),
    });

    const response = await POST(request, { params: Promise.resolve({ segments: ["auth", "login"] }) });

    expect(response.status).toBe(503);
    expect(await response.json()).toMatchObject({
      error: "Roamora’s API is unavailable. Start the API and configure its database connection, then try again.",
    });
  });

  it("converts an upstream gateway failure into an explicit service-unavailable response", async () => {
    vi.stubEnv("ROAMORA_API_URL", "http://api.example.test");
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response("", { status: 502 })));
    const request = new NextRequest("http://localhost/api/v1/auth/login", {
      method: "POST",
      body: JSON.stringify({ email: "person@example.com", password: "test-password" }),
    });

    const response = await POST(request, { params: Promise.resolve({ segments: ["auth", "login"] }) });

    expect(response.status).toBe(503);
    expect(await response.json()).toMatchObject({
      error: "Roamora’s API is unavailable. Start the API and configure its database connection, then try again.",
    });
  });
});
