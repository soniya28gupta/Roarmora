"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState, type ReactNode } from "react";
import { LoaderCircle, ShieldAlert } from "lucide-react";

type GuardState = "checking" | "authorized" | "unavailable";

export function SessionGuard({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [state, setState] = useState<GuardState>("checking");
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    setState("checking");

    fetch("/api/v1/me", {
      credentials: "same-origin",
      cache: "no-store",
      signal: controller.signal,
    })
      .then((response) => {
        if (response.status === 401) {
          const loginUrl = new URL("/login", window.location.origin);
          loginUrl.searchParams.set("next", pathname);
          router.replace(`${loginUrl.pathname}${loginUrl.search}`);
          return;
        }
        if (!response.ok) throw new Error("Session check failed");
        setState("authorized");
      })
      .catch((error: unknown) => {
        if (error instanceof DOMException && error.name === "AbortError") return;
        setState("unavailable");
      });

    return () => controller.abort();
  }, [attempt, pathname, router]);

  if (state === "authorized") return children;

  if (state === "unavailable") {
    return (
      <div className="session-state" role="alert">
        <ShieldAlert size={24} />
        <h1>We couldn’t verify your sign-in.</h1>
        <p>Reconnect to Roamora and try again. Your account data remains protected.</p>
        <button className="button button-coral" onClick={() => setAttempt((current) => current + 1)} type="button">Try again</button>
        <Link className="text-link" href="/login">Return to sign in</Link>
      </div>
    );
  }

  return (
    <div aria-label="Checking your sign-in" className="session-state" role="status">
      <LoaderCircle className="session-spinner" size={25} />
      <p>Checking your Roamora session…</p>
    </div>
  );
}
