ALTER TABLE "profiles"
ADD COLUMN "photos" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
ADD COLUMN "gender" VARCHAR(40),
ADD COLUMN "looking_for" VARCHAR(40),
ADD COLUMN "compatibility_score" INTEGER;

ALTER TABLE "preferences"
ADD COLUMN "discovery_radius_meters" INTEGER NOT NULL DEFAULT 500,
ADD COLUMN "global_explore_mode" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "gender_preference" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
