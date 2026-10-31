"use client";

import { AlertCircle } from "lucide-react";

export default function AppError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <main className="state-card state-error app-error" role="alert">
      <AlertCircle size={25} />
      <h1>We couldn’t load this Roamora page.</h1>
      <p>{error.message || "The request failed. Check your connection and try again."}</p>
      <button className="button button-dark" onClick={reset} type="button">Try again</button>
    </main>
  );
}
