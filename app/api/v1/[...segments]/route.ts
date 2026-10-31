import type { NextRequest } from "next/server";

type RouteContext = {
  params: Promise<{ segments: string[] }>;
};

async function proxyToApi(request: NextRequest, context: RouteContext) {
  const { segments } = await context.params;
  const apiOrigin = process.env.ROAMORA_API_URL ?? "http://127.0.0.1:8081";
  const apiUrl = new URL(
    `/api/v1/${segments.map((segment) => encodeURIComponent(segment)).join("/")}`,
    apiOrigin,
  );
  apiUrl.search = request.nextUrl.search;

  const headers = new Headers();
  for (const name of ["accept", "content-type", "cookie"]) {
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
  const setCookie = upstream.headers.get("set-cookie");
  if (setCookie) responseHeaders.set("set-cookie", setCookie);

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
