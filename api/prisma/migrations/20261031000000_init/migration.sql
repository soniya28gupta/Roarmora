CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE "SwipeDirection" AS ENUM ('LIKE', 'PASS');
CREATE TYPE "ReportStatus" AS ENUM ('OPEN', 'REVIEWED', 'ACTIONED');

CREATE TABLE "users" (
  "id" UUID NOT NULL,
  "email" VARCHAR(320) NOT NULL,
  "password_hash" TEXT NOT NULL,
  "birth_date" DATE NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

CREATE TABLE "profiles" (
  "id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "display_name" VARCHAR(80) NOT NULL,
  "bio" VARCHAR(500) NOT NULL,
  "city" VARCHAR(120) NOT NULL,
  "interests" TEXT[] NOT NULL,
  "image_url" VARCHAR(2048),
  "discoverable" BOOLEAN NOT NULL DEFAULT true,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "profiles_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "profiles_user_id_key" ON "profiles"("user_id");

CREATE TABLE "preferences" (
  "user_id" UUID NOT NULL,
  "min_age" INTEGER NOT NULL DEFAULT 18,
  "max_age" INTEGER NOT NULL DEFAULT 99,
  "max_distance_km" INTEGER NOT NULL DEFAULT 50,
  "interests" TEXT[] NOT NULL,
  "location_consent" BOOLEAN NOT NULL DEFAULT false,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "preferences_pkey" PRIMARY KEY ("user_id"),
  CONSTRAINT "preferences_age_range_check" CHECK ("min_age" >= 18 AND "max_age" >= "min_age"),
  CONSTRAINT "preferences_distance_check" CHECK ("max_distance_km" BETWEEN 1 AND 500)
);

CREATE TABLE "sessions" (
  "id" UUID NOT NULL,
  "token_hash" VARCHAR(64) NOT NULL,
  "user_id" UUID NOT NULL,
  "expires_at" TIMESTAMP(3) NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "sessions_token_hash_key" ON "sessions"("token_hash");
CREATE INDEX "sessions_user_id_idx" ON "sessions"("user_id");
CREATE INDEX "sessions_expires_at_idx" ON "sessions"("expires_at");

CREATE TABLE "swipes" (
  "id" UUID NOT NULL,
  "actor_id" UUID NOT NULL,
  "target_id" UUID NOT NULL,
  "direction" "SwipeDirection" NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "swipes_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "swipes_not_self_check" CHECK ("actor_id" <> "target_id")
);
CREATE UNIQUE INDEX "swipes_actor_id_target_id_key" ON "swipes"("actor_id", "target_id");

CREATE TABLE "matches" (
  "id" UUID NOT NULL,
  "user_a_id" UUID NOT NULL,
  "user_b_id" UUID NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "matches_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "matches_canonical_pair_check" CHECK ("user_a_id" < "user_b_id")
);
CREATE UNIQUE INDEX "matches_user_a_id_user_b_id_key" ON "matches"("user_a_id", "user_b_id");

CREATE TABLE "places" (
  "id" UUID NOT NULL,
  "name" VARCHAR(160) NOT NULL,
  "category" VARCHAR(80) NOT NULL,
  "neighborhood" VARCHAR(120) NOT NULL,
  "description" VARCHAR(500) NOT NULL,
  "latitude" DOUBLE PRECISION NOT NULL,
  "longitude" DOUBLE PRECISION NOT NULL,
  "fictional" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "location" geography(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography) STORED,
  CONSTRAINT "places_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "places_latitude_check" CHECK ("latitude" BETWEEN -90 AND 90),
  CONSTRAINT "places_longitude_check" CHECK ("longitude" BETWEEN -180 AND 180)
);
CREATE INDEX "places_location_gix" ON "places" USING GIST ("location");

CREATE TABLE "drops" (
  "id" UUID NOT NULL,
  "host_id" UUID NOT NULL,
  "title" VARCHAR(160) NOT NULL,
  "description" VARCHAR(500) NOT NULL,
  "interest" VARCHAR(80) NOT NULL,
  "starts_at" TIMESTAMP(3) NOT NULL,
  "area_label" VARCHAR(160) NOT NULL,
  "latitude" DOUBLE PRECISION NOT NULL,
  "longitude" DOUBLE PRECISION NOT NULL,
  "location_consent" BOOLEAN NOT NULL DEFAULT false,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "location" geography(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography) STORED,
  CONSTRAINT "drops_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "drops_latitude_check" CHECK ("latitude" BETWEEN -90 AND 90),
  CONSTRAINT "drops_longitude_check" CHECK ("longitude" BETWEEN -180 AND 180)
);
CREATE INDEX "drops_starts_at_idx" ON "drops"("starts_at");
CREATE INDEX "drops_location_gix" ON "drops" USING GIST ("location");

CREATE TABLE "drop_collections" (
  "user_id" UUID NOT NULL,
  "drop_id" UUID NOT NULL,
  "collected_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "drop_collections_pkey" PRIMARY KEY ("user_id", "drop_id")
);

CREATE TABLE "messages" (
  "id" UUID NOT NULL,
  "match_id" UUID NOT NULL,
  "sender_id" UUID NOT NULL,
  "body" VARCHAR(2000) NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "messages_match_id_created_at_idx" ON "messages"("match_id", "created_at");

CREATE TABLE "blocks" (
  "blocker_id" UUID NOT NULL,
  "blocked_id" UUID NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "blocks_pkey" PRIMARY KEY ("blocker_id", "blocked_id"),
  CONSTRAINT "blocks_not_self_check" CHECK ("blocker_id" <> "blocked_id")
);
CREATE INDEX "blocks_blocked_id_idx" ON "blocks"("blocked_id");

CREATE TABLE "reports" (
  "id" UUID NOT NULL,
  "reporter_id" UUID NOT NULL,
  "target_user_id" UUID NOT NULL,
  "reason" VARCHAR(80) NOT NULL,
  "details" VARCHAR(1000),
  "status" "ReportStatus" NOT NULL DEFAULT 'OPEN',
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "reports_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "reports_not_self_check" CHECK ("reporter_id" <> "target_user_id")
);
CREATE INDEX "reports_target_user_id_created_at_idx" ON "reports"("target_user_id", "created_at");

ALTER TABLE "profiles" ADD CONSTRAINT "profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "preferences" ADD CONSTRAINT "preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "swipes" ADD CONSTRAINT "swipes_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "swipes" ADD CONSTRAINT "swipes_target_id_fkey" FOREIGN KEY ("target_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "matches" ADD CONSTRAINT "matches_user_a_id_fkey" FOREIGN KEY ("user_a_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "matches" ADD CONSTRAINT "matches_user_b_id_fkey" FOREIGN KEY ("user_b_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "drops" ADD CONSTRAINT "drops_host_id_fkey" FOREIGN KEY ("host_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "drop_collections" ADD CONSTRAINT "drop_collections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "drop_collections" ADD CONSTRAINT "drop_collections_drop_id_fkey" FOREIGN KEY ("drop_id") REFERENCES "drops"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "messages" ADD CONSTRAINT "messages_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "matches"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "blocks" ADD CONSTRAINT "blocks_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "blocks" ADD CONSTRAINT "blocks_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "reports" ADD CONSTRAINT "reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "reports" ADD CONSTRAINT "reports_target_user_id_fkey" FOREIGN KEY ("target_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

