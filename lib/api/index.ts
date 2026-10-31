import type { ApiClient } from "@/lib/api/types";
import { mockClient } from "@/lib/api/mock-client";

// Single swap point for a future live client; Phase 1 remains mock-only.
export const api: ApiClient = mockClient;
export type { ApiClient } from "@/lib/api/types";
