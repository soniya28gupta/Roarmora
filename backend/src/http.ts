import type { ErrorRequestHandler, RequestHandler } from "express";
import { ZodError } from "zod";

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly code?: string,
  ) {
    super(message);
  }
}

export const notFound: RequestHandler = (_request, response) => {
  response.status(404).json({ error: "Not found" });
};

function isDatabaseUnavailable(error: unknown): boolean {
  if (!error || typeof error !== "object") return false;
  const candidate = error as { code?: string; name?: string; message?: string };
  return candidate.name === "PrismaClientInitializationError" ||
    candidate.code === "P1000" ||
    candidate.code === "P1001" ||
    candidate.code === "P1002" ||
    candidate.code === "P1003" ||
    candidate.code === "P1008" ||
    candidate.code === "P1010" ||
    candidate.code === "P1011" ||
    candidate.code === "P1017" ||
    candidate.code === "P2024" ||
    candidate.code === "P2028" ||
    (candidate.message ?? "").includes("DATABASE_URL");
}

export const errorHandler: ErrorRequestHandler = (error, _request, response, _next) => {
  if (error instanceof ZodError) {
    response.status(400).json({ error: "Invalid request", details: error.issues });
    return;
  }
  if (error instanceof HttpError) {
    response.status(error.status).json({ error: error.message, ...(error.code ? { code: error.code } : {}) });
    return;
  }
  if (isDatabaseUnavailable(error)) {
    response.status(503).json({ error: "Database unavailable", code: "DATABASE_UNAVAILABLE" });
    return;
  }
  console.error("Unhandled API error", error);
  response.status(500).json({ error: "Internal server error" });
};

export function fixedWindowLimit(maximum: number, windowMs: number): RequestHandler {
  const buckets = new Map<string, { count: number; resetAt: number }>();
  return (request, response, next) => {
    const rawForwarded = request.headers["x-forwarded-for"];
    const forwardedIp = Array.isArray(rawForwarded)
      ? rawForwarded[0]?.split(",")[0]?.trim()
      : typeof rawForwarded === "string"
        ? rawForwarded.split(",")[0]?.trim()
        : undefined;
    const key = forwardedIp || request.ip || "unknown";
    const time = Date.now();
    let bucket = buckets.get(key);
    if (!bucket || bucket.resetAt <= time) {
      bucket = { count: 0, resetAt: time + windowMs };
      buckets.set(key, bucket);
    }
    if (bucket.count >= maximum) {
      response.setHeader("RateLimit-Limit", maximum);
      response.setHeader("RateLimit-Remaining", 0);
      response.setHeader("RateLimit-Reset", Math.ceil(bucket.resetAt / 1000));
      response.status(429).json({ error: "Too many requests. Please wait a few moments and try again." });
      return;
    }
    bucket.count += 1;
    response.setHeader("RateLimit-Limit", maximum);
    response.setHeader("RateLimit-Remaining", Math.max(0, maximum - bucket.count));
    response.setHeader("RateLimit-Reset", Math.ceil(bucket.resetAt / 1000));
    if (buckets.size > 10_000) {
      for (const [bucketKey, value] of buckets) if (value.resetAt <= time) buckets.delete(bucketKey);
    }
    next();
  };
}
