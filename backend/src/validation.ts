import { z } from "zod";
import { DROP_COLLECTION_RADIUS_METERS } from "./geo.js";

const now = () => new Date();

export function isAdult(birthDate: Date, today = now()): boolean {
  const eighteenthBirthday = Date.UTC(
    birthDate.getUTCFullYear() + 18,
    birthDate.getUTCMonth(),
    birthDate.getUTCDate(),
  );
  const currentDate = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
  return eighteenthBirthday <= currentDate;
}

export const registerSchema = z.object({
  email: z.string().trim().email().max(320).transform((value) => value.toLowerCase()),
  password: z.string().min(12, "Password must be at least 12 characters").max(128),
  birthDate: z.iso.date().refine((value) => {
    const date = new Date(`${value}T00:00:00.000Z`);
    return !Number.isNaN(date.valueOf()) && isAdult(date);
  }, "You must be at least 18 years old to join Pookie Match"),
  displayName: z.string().trim().min(1).max(80),
  bio: z.string().trim().max(150, "Bio cannot exceed 150 characters").default(""),
  city: z.string().trim().min(1).max(120),
  interests: z.array(z.string().trim().min(1).max(40)).max(30).default([]),
  gender: z.string().trim().max(40).optional(),
  lookingFor: z.string().trim().max(40).optional(),
  connectionGoal: z.string().trim().max(80).optional(),
});

export const loginSchema = z.object({
  email: z.string().trim().email().max(320).transform((value) => value.toLowerCase()),
  password: z.string().min(1).max(128),
});

export const googleAuthSchema = z.object({
  idToken: z.string().trim().min(1).optional(),
  accessToken: z.string().trim().min(1).optional(),
  birthDate: z.iso.date().refine((value) => {
    const date = new Date(`${value}T00:00:00.000Z`);
    return !Number.isNaN(date.valueOf()) && isAdult(date);
  }, "You must be at least 18 years old to join Pookie Match").optional(),
  displayName: z.string().trim().min(1).max(80).optional(),
}).refine((val) => Boolean(val.idToken || val.accessToken), {
  message: "Either idToken or accessToken is required for Google Sign-In",
});

export const otpSendSchema = z.object({
  email: z.string().trim().email().max(320).transform((value) => value.toLowerCase()),
});

export const otpVerifySchema = z.object({
  email: z.string().trim().email().max(320).transform((value) => value.toLowerCase()),
  code: z.string().trim().regex(/^\d{6}$/, "OTP must be an exact 6-digit numeric code"),
});

const photoUriValidator = z.string().trim().min(1).max(2_500_000).refine(
  (val) => val.startsWith("https://") || val.startsWith("http://") || /^data:image\/(jpeg|jpg|png|webp);base64,/i.test(val),
  "Photo must be a valid HTTPS URL or base64 encoded JPEG/PNG/WebP image",
);

export const profileSchema = z.object({
  displayName: z.string().trim().min(1).max(80).optional(),
  bio: z.string().trim().max(150, "Bio cannot exceed 150 characters").optional(),
  city: z.string().trim().min(1).max(120).optional(),
  interests: z.array(z.string().trim().min(1).max(40)).max(30).optional(),
  imageUrl: photoUriValidator.nullable().optional(),
  photos: z.array(photoUriValidator).max(10).optional(),
  gender: z.string().trim().max(40).optional(),
  lookingFor: z.string().trim().max(40).optional(),
  connectionGoal: z.string().trim().max(80).optional(),
  discoverable: z.boolean().optional(),
  birthDate: z.iso.date().refine((value) => {
    const date = new Date(`${value}T00:00:00.000Z`);
    return !Number.isNaN(date.valueOf()) && isAdult(date);
  }, "You must be at least 18 years old to join Pookie Match").optional(),
}).strict();

export const photoUploadSchema = z.object({
  photos: z.array(photoUriValidator).min(2, "Minimum 2 gallery photos are required").max(10),
});

export const livenessVerifySchema = z.object({
  sessionId: z.string().trim().min(1).max(120),
  faceScanPayload: z.string().min(1).optional(),
  auditTrailImage: z.string().min(1).optional(),
  lowQualityAuditTrailImage: z.string().min(1).optional(),
});

export const preferenceSchema = z.object({
  minAge: z.number().int().min(18).max(99).optional(),
  maxAge: z.number().int().min(18).max(99).optional(),
  maxDistanceKm: z.number().int().min(1).max(500).optional(),
  discoveryRadiusMeters: z.number().int().min(50).max(5000).optional(),
  globalExploreMode: z.boolean().optional(),
  interests: z.array(z.string().trim().min(1).max(40)).max(30).optional(),
  genderPreference: z.array(z.string().trim().max(40)).max(10).optional(),
  locationConsent: z.boolean().optional(),
}).strict().refine((value) =>
  value.minAge === undefined ||
  value.maxAge === undefined ||
  value.minAge <= value.maxAge,
{ message: "minAge must not exceed maxAge" });

export const swipeSchema = z.object({
  targetUserId: z.string().uuid(),
  direction: z.enum(["LIKE", "PASS"]),
});

export const dropSchema = z.object({
  title: z.string().trim().min(1).max(160),
  description: z.string().trim().max(500).default(""),
  interest: z.string().trim().min(1).max(80),
  startsAt: z.iso.datetime().transform((value) => new Date(value)),
  areaLabel: z.string().trim().min(1).max(160),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  locationConsent: z.literal(true),
});

export const searchSchema = z.object({
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  radiusKm: z.coerce.number().int().min(1).max(100).default(10),
  consent: z.literal("true"),
});

export const dropCollectionSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracyMeters: z.number().min(0).max(DROP_COLLECTION_RADIUS_METERS),
  locationConsent: z.literal(true),
  remoteMode: z.boolean().optional(),
});

export const collectibleCollectSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracyMeters: z.number().min(0).max(100).optional(),
  locationConsent: z.boolean().optional(),
  remoteMode: z.boolean().optional(),
});

export const messageSchema = z.object({
  body: z.string().trim().min(1).max(2000),
});

export const reportSchema = z.object({
  targetUserId: z.string().uuid(),
  reason: z.string().trim().min(1).max(80),
  details: z.string().trim().max(1000).optional(),
});

export const blockSchema = z.object({
  targetUserId: z.string().uuid(),
});

export const callInitiateSchema = z.object({
  targetUserId: z.string().uuid(),
  matchId: z.string().uuid(),
  callType: z.enum(["AUDIO", "VIDEO"]).default("VIDEO"),
  offer: z.any().optional(),
});

export const callAnswerSchema = z.object({
  answer: z.any(),
});

export const callCandidateSchema = z.object({
  candidate: z.any(),
});

export const gameStartSchema = z.object({
  gameType: z.enum(["COMPATIBILITY_QUIZ", "VIBE_CHECK", "TRUTH_OR_DARE", "TREASURE_RACE"]),
  matchId: z.string().uuid().optional(),
});

export const gameInviteSchema = z.object({
  gameType: z.enum(["COMPATIBILITY_QUIZ", "VIBE_CHECK", "TRUTH_OR_DARE", "TREASURE_RACE"]),
  matchId: z.string().uuid(),
});

export const gameActionSchema = z.object({
  action: z.string().trim().min(1),
  payload: z.any(),
});

export const quizSubmitSchema = z.object({
  answers: z.array(z.object({
    questionId: z.string().trim().min(1),
    category: z.string().trim().min(1),
    answerValue: z.string().trim().min(1),
  })).min(1).max(20),
});

export const useItemSchema = z.object({
  targetMatchId: z.string().uuid().optional(),
});
