import { describe, expect, it } from "vitest";
import { drops, places } from "@/data/demo";
import { mockClient } from "@/lib/api/mock-client";

describe("Roamora sample content", () => {
  it("provides illustrative landing-page places and drops", async () => {
    expect(places.length).toBeGreaterThan(0);
    expect(drops.length).toBeGreaterThan(0);
    await expect(mockClient.listPlaces()).resolves.toEqual(places);
  });

  it("keeps all map markers within the illustrative map area", () => {
    for (const drop of drops) {
      expect(drop.x).toBeGreaterThanOrEqual(0);
      expect(drop.x).toBeLessThanOrEqual(100);
      expect(drop.y).toBeGreaterThanOrEqual(0);
      expect(drop.y).toBeLessThanOrEqual(100);
    }
  });

  it("uses loadable imagery for sample places", () => {
    for (const place of places) expect(place.image).toMatch(/^https:\/\//);
  });
});
