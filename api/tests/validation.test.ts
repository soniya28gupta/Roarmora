import { describe, expect, it } from "vitest";
import { approximateCoordinates, canonicalPair } from "../src/geo.js";
import {
  dropCollectionSchema,
  isAdult,
  preferenceSchema,
  registerSchema,
  searchSchema,
} from "../src/validation.js";

describe("age and account validation", () => {
  it("accepts users on their 18th birthday and rejects those a day younger", () => {
    const today = new Date("2026-10-31T12:00:00.000Z");
    expect(isAdult(new Date("2008-10-31T00:00:00.000Z"), today)).toBe(true);
    expect(isAdult(new Date("2008-11-01T00:00:00.000Z"), today)).toBe(false);
    expect(isAdult(new Date("2008-10-31T00:00:00.000Z"), new Date("2026-10-30T23:59:59.000Z"))).toBe(false);
  });

  it("normalizes email casing and enforces a minimum password length", () => {
    const valid = registerSchema.safeParse({
      email: "  PERSON@EXAMPLE.COM ",
      password: "a-secure-passphrase",
      birthDate: "2000-01-01",
      displayName: "Test",
      city: "Sample City",
    });
    expect(valid.success).toBe(true);
    if (valid.success) expect(valid.data.email).toBe("person@example.com");
    expect(registerSchema.safeParse({
      email: "person@example.com",
      password: "short",
      birthDate: "2000-01-01",
      displayName: "Test",
      city: "Sample City",
    }).success).toBe(false);
  });
});

describe("preferences and private location inputs", () => {
  it("requires age preferences to start at age 18", () => {
    expect(preferenceSchema.safeParse({ minAge: 17 }).success).toBe(false);
    expect(preferenceSchema.safeParse({ minAge: 35, maxAge: 24 }).success).toBe(false);
  });

  it("requires explicit consent and valid coordinates for radius searches", () => {
    expect(searchSchema.safeParse({ latitude: 28.6, longitude: 77.2, consent: "true" }).success).toBe(true);
    expect(searchSchema.safeParse({ latitude: 28.6, longitude: 77.2 }).success).toBe(false);
  });

  it("requires explicit consent and accurate coordinates to collect a drop", () => {
    const request = {
      latitude: 28.6,
      longitude: 77.2,
      accuracyMeters: 8,
      locationConsent: true,
    };
    expect(dropCollectionSchema.safeParse(request).success).toBe(true);
    expect(dropCollectionSchema.safeParse({ ...request, locationConsent: false }).success).toBe(false);
    expect(dropCollectionSchema.safeParse({ ...request, accuracyMeters: 16 }).success).toBe(false);
  });

  it("rounds coordinates before persistent storage and outward responses", () => {
    expect(approximateCoordinates({ latitude: 28.613927, longitude: 77.209023 })).toEqual({
      latitude: 28.61,
      longitude: 77.21,
    });
  });
});

it("canonicalizes a user pair independent of swipe order", () => {
  expect(canonicalPair("b", "a")).toEqual(["a", "b"]);
  expect(canonicalPair("a", "b")).toEqual(["a", "b"]);
});
