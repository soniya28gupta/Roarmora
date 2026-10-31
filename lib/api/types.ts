import type { DemoUser, Drop, Place } from "@/types/roamora";

export interface ApiClient {
  getCurrentUser(): Promise<DemoUser>;
  listPlaces(): Promise<Place[]>;
  listDrops(): Promise<Drop[]>;
}
