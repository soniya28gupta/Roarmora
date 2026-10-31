"use server";

import { cookies } from "next/headers";

type SignInResult =
  | { ok: true }
  | { ok: false; message: string };

type AuthResponse = {
  error?: string;
};

export async function signIn(email: string, password: string): Promise<SignInResult> {
  const apiOrigin = process.env.ROAMORA_API_URL ?? "http://127.0.0.1:8081";

  let response: Response;
  try {
    response = await fetch(new URL("/api/v1/auth/login", apiOrigin), {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, password }),
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    return {
      ok: false,
      message: `Roamora’s API is not reachable at ${apiOrigin}. Start the API and configure its database connection, then try again.`,
    };
  }

  const result = await response.json().catch((): AuthResponse => ({}));
  if (!response.ok) {
    const message = response.status === 401
      ? "That email and password don’t match. Please try again."
      : response.status === 400
        ? "Please check your email and password, then try again."
        : response.status === 503
          ? "Roamora’s authentication service is unavailable. Check the API database configuration, then try again."
          : result.error ?? "We couldn’t complete your sign-in. Please try again later.";
    return { ok: false, message };
  }

  const sessionCookie = response.headers
    .get("set-cookie")
    ?.match(/(?:^|,\s*)roamora_session=([^;,]*)/);
  if (!sessionCookie?.[1]) {
    return {
      ok: false,
      message: "Roamora did not establish a secure session. Please try again.",
    };
  }

  const expiryText = response.headers.get("set-cookie")?.match(/expires=([^;]+)/i)?.[1];
  const expires = expiryText ? new Date(expiryText) : undefined;
  if (expires && Number.isNaN(expires.getTime())) {
    return {
      ok: false,
      message: "Roamora returned an invalid session. Please try again.",
    };
  }

  const cookieStore = await cookies();
  cookieStore.set("roamora_session", sessionCookie[1], {
    httpOnly: true,
    secure: process.env.COOKIE_SECURE === "true" || process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    ...(expires ? { expires } : {}),
  });

  return { ok: true };
}
