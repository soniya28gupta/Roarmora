export async function apiRequest<T>(path: string, init?: RequestInit): Promise<T> {
  let response: Response;
  const headers = new Headers(init?.headers);
  headers.set("accept", "application/json");
  if (init?.body && !headers.has("content-type")) headers.set("content-type", "application/json");
  try {
    response = await fetch(`/api/v1${path}`, {
      ...init,
      credentials: "same-origin",
      cache: "no-store",
      headers,
    });
  } catch {
    throw new Error("Roamora’s API could not be reached. Check the API connection and try again.");
  }

  if (response.status === 204) return undefined as T;

  const body: unknown = await response.json();
  if (!response.ok) {
    const errorBody = body as { error?: string };
    throw new Error(errorBody.error ?? `The request failed (HTTP ${response.status}).`);
  }
  return body as T;
}
