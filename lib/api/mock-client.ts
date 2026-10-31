import { demoUser, drops, places } from "@/data/demo";
import type { ApiClient } from "@/lib/api/types";

export const mockClient: ApiClient = {
  async getCurrentUser() {
    return demoUser;
  },
  async listPlaces() {
    return places;
  },
  async listDrops() {
    return drops;
  },
};
