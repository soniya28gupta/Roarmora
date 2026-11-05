import { describe, expect, it } from "vitest";
import { approximateCoordinates, canonicalPair } from "../src/geo.js";
import {
  dropCollectionSchema,
  isAdult,
  otpSendSchema,
  otpVerifySchema,
  photoUploadSchema,
  preferenceSchema,
  profileSchema,
  registerSchema,
  searchSchema,
} from "../src/validation.js";
import { generateSixDigitOtp, hashToken, OTP_EXPIRY_SECONDS } from "../src/auth.js";
import { calculateProfileCompletion } from "../src/app.js";

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

describe("Milestone 1: OTP, Bio 150-char limit, Photo upload & Profile Completion Matrix", () => {
  it("enforces strict 150-character bio limit on register and profile update", () => {
    const bio150 = "a".repeat(150);
    const bio151 = "a".repeat(151);

    expect(profileSchema.safeParse({ bio: bio150 }).success).toBe(true);
    expect(profileSchema.safeParse({ bio: bio151 }).success).toBe(false);

    expect(
      registerSchema.safeParse({
        email: "user@example.com",
        password: "a-secure-passphrase",
        birthDate: "2000-01-01",
        displayName: "Soniya",
        city: "Mumbai",
        bio: bio151,
      }).success,
    ).toBe(false);
  });

  it("validates 6-digit OTP format and exact 60-second expiry constant", () => {
    expect(OTP_EXPIRY_SECONDS).toBe(60);
    const otp = generateSixDigitOtp();
    expect(otp).toMatch(/^\d{6}$/);
    expect(hashToken(otp)).toHaveLength(64);
    expect(hashToken(otp)).not.toBe(otp);

    expect(otpSendSchema.safeParse({ email: "  USER@GMAIL.COM " }).success).toBe(true);
    expect(otpVerifySchema.safeParse({ email: "user@gmail.com", code: "123456" }).success).toBe(true);
    expect(otpVerifySchema.safeParse({ email: "user@gmail.com", code: "12345" }).success).toBe(false);
    expect(otpVerifySchema.safeParse({ email: "user@gmail.com", code: "12345a" }).success).toBe(false);
  });

  it("enforces minimum 2 gallery photos on photoUploadSchema", () => {
    const validPhoto1 = "https://images.unsplash.com/photo-1";
    const validPhoto2 = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/";

    expect(photoUploadSchema.safeParse({ photos: [validPhoto1] }).success).toBe(false);
    expect(photoUploadSchema.safeParse({ photos: [validPhoto1, validPhoto2] }).success).toBe(true);
  });

  it("calculates dynamic profile completion across all 5 x 20% = 100% milestones", () => {
    const emptyResult = calculateProfileCompletion({
      email: "user@gmail.com",
      isEmailVerified: false,
      isIdentityVerified: false,
      age: 22,
      profile: null,
      preferences: null,
    });
    expect(emptyResult.percentage).toBe(0);
    expect(emptyResult.isComplete).toBe(false);

    const partialResult = calculateProfileCompletion({
      email: "user@gmail.com",
      isEmailVerified: true, // +20%
      isIdentityVerified: false,
      age: 23,
      profile: {
        displayName: "Soniya",
        gender: "Woman",
        bio: "Coffee & sunsets in Mumbai", // +20% (demographics + bio <= 150)
        interests: ["Travel", "Music"],
        connectionGoal: "Long-term partner", // +20% (hobbies + preferences)
        photos: ["https://example.com/1.jpg", "https://example.com/2.jpg"], // +20% (>= 2 photos)
      },
      preferences: {
        minAge: 21,
        maxAge: 30,
        maxDistanceKm: 25,
      },
    });
    expect(partialResult.percentage).toBe(80);
    expect(partialResult.isComplete).toBe(false);
    expect(partialResult.milestones.faceLivenessVerified).toBe(false);

    const fullResult = calculateProfileCompletion({
      email: "user@gmail.com",
      googleId: "google-sub-123",
      isEmailVerified: true,
      isIdentityVerified: true, // +20% (Face Liveness Verified)
      age: 23,
      profile: {
        displayName: "Soniya",
        gender: "Woman",
        bio: "Coffee & sunsets in Mumbai",
        interests: ["Travel", "Music"],
        connectionGoal: "Long-term partner",
        photos: ["https://example.com/1.jpg", "https://example.com/2.jpg"],
      },
      preferences: {
        minAge: 21,
        maxAge: 30,
        maxDistanceKm: 25,
      },
    });
    expect(fullResult.percentage).toBe(100);
    expect(fullResult.isComplete).toBe(true);
  });
});
