-- Milestone 1: Additive schema updates for Google OAuth, 60s OTP verification, Onboarding, and Face Liveness Verification
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "google_id" VARCHAR(255),
  ADD COLUMN IF NOT EXISTS "is_email_verified" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "is_identity_verified" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "onboarding_completed" BOOLEAN NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS "users_google_id_key" ON "users"("google_id");

ALTER TABLE "profiles"
  ADD COLUMN IF NOT EXISTS "connection_goal" VARCHAR(80),
  ADD COLUMN IF NOT EXISTS "liveness_session_id" VARCHAR(120),
  ADD COLUMN IF NOT EXISTS "liveness_verified_at" TIMESTAMP(3);

CREATE TABLE IF NOT EXISTS "otp_codes" (
  "id" UUID NOT NULL,
  "user_id" UUID,
  "email" VARCHAR(320) NOT NULL,
  "code_hash" VARCHAR(64) NOT NULL,
  "expires_at" TIMESTAMP(3) NOT NULL,
  "used_at" TIMESTAMP(3),
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "otp_codes_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "otp_codes_email_created_at_idx" ON "otp_codes"("email", "created_at");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'otp_codes_user_id_fkey'
  ) THEN
    ALTER TABLE "otp_codes"
      ADD CONSTRAINT "otp_codes_user_id_fkey"
      FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

