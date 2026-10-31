"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { apiRequest } from "@/lib/api/browser-client";

export function SignOutButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function signOut() {
    if (busy) return;
    setBusy(true);
    setError("");
    try {
      await apiRequest<void>("/auth/logout", { method: "POST" });
      router.replace("/login");
      router.refresh();
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "You could not be signed out.");
      setBusy(false);
    }
  }

  return (
    <div className="sign-out-control">
      <button className="button button-outline button-small" disabled={busy} onClick={() => void signOut()} type="button">{busy ? "Signing out…" : "Sign out"}</button>
      {error && <span role="alert">{error}</span>}
    </div>
  );
}
