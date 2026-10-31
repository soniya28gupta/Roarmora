import type { NextRequest } from "next/server";

type RouteContext = {
  params: Promise<{ segments: string[] }>;
};

const DEFAULT_PROD_API = "https://roarmora-api.onrender.com";
const DEFAULT_DEV_API = "http://127.0.0.1:8081";

async function proxyToApi(request: NextRequest, context: RouteContext) {
  const { segments } = await context.params;
  const fallback = process.env.NODE_ENV === "production" ? DEFAULT_PROD_API : DEFAULT_DEV_API;
  const configuredOrigin = (process.env.ROAMORA_API_URL ?? fallback).trim().replace(/\/+$/, "");
  // Strip trailing /api/v1 if a user configured the full API path in the environment variable
  const baseOrigin = configuredOrigin.replace(/\/api\/v1\/?$/, "");
  const encodedPath = segments.map((segment) => encodeURIComponent(segment)).join("/");
  const apiUrl = new URL(`/api/v1/${encodedPath}`, `${baseOrigin}/`);
  apiUrl.search = request.nextUrl.search;

  const headers = new Headers();
  for (const name of ["accept", "content-type", "cookie", "authorization"]) {
    const value = request.headers.get(name);
    if (value) headers.set(name, value);
  }

  let upstream: Response;
  try {
    upstream = await fetch(apiUrl, {
      method: request.method,
      headers,
      body: ["GET", "HEAD"].includes(request.method) ? undefined : await request.arrayBuffer(),
      cache: "no-store",
      redirect: "manual",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    return Response.json(
      { error: "Roamora’s API is unavailable. Start the API and configure its database connection, then try again." },
      { status: 503 },
    );
  }

  if (upstream.status === 502) {
    return Response.json(
      { error: "Roamora’s API is unavailable. Start the API and configure its database connection, then try again." },
      { status: 503 },
    );
  }

  const responseHeaders = new Headers();
  const contentType = upstream.headers.get("content-type");
  if (contentType) responseHeaders.set("content-type", contentType);

  // Preserve all Set-Cookie headers from upstream
  if (typeof (upstream.headers as unknown as { getSetCookie?: () => string[] }).getSetCookie === "function") {
    const cookies = (upstream.headers as unknown as { getSetCookie: () => string[] }).getSetCookie();
    for (const cookie of cookies) {
      responseHeaders.append("set-cookie", cookie);
    }
  } else {
    const setCookie = upstream.headers.get("set-cookie");
    if (setCookie) responseHeaders.set("set-cookie", setCookie);
  }

  return new Response(upstream.body, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers: responseHeaders,
  });
}

export const GET = proxyToApi;
export const POST = proxyToApi;
export const PUT = proxyToApi;
export const PATCH = proxyToApi;
export const DELETE = proxyToApi;
