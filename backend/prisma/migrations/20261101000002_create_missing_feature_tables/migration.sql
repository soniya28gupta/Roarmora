CREATE TABLE "collectible_items" (
    "id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "slug" VARCHAR(120) NOT NULL,
    "description" VARCHAR(500) NOT NULL,
    "icon" VARCHAR(80) NOT NULL,
    "rarity" VARCHAR(40) NOT NULL,
    "category" VARCHAR(60) NOT NULL,
    "perk_description" VARCHAR(240),
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "collectible_items_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "collectible_items_slug_key"
ON "collectible_items"("slug");

CREATE TABLE "user_inventories" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "item_id" UUID NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "acquired_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "user_inventories_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "user_inventories_user_id_item_id_key"
ON "user_inventories"("user_id", "item_id");

CREATE TABLE "achievements" (
    "id" UUID NOT NULL,
    "title" VARCHAR(120) NOT NULL,
    "slug" VARCHAR(120) NOT NULL,
    "description" VARCHAR(500) NOT NULL,
    "icon" VARCHAR(80) NOT NULL,
    "badge_color" VARCHAR(40) NOT NULL,
    "category" VARCHAR(60) NOT NULL,
    "points" INTEGER NOT NULL DEFAULT 10,
    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "achievements_slug_key"
ON "achievements"("slug");

CREATE TABLE "user_achievements" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "achievement_id" UUID NOT NULL,
    "unlocked_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "user_achievements_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "user_achievements_user_id_achievement_id_key"
ON "user_achievements"("user_id", "achievement_id");

CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" VARCHAR(40) NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "message" VARCHAR(500) NOT NULL,
    "link" VARCHAR(240),
    "read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "notifications_user_id_read_idx"
ON "notifications"("user_id", "read");

CREATE TABLE "game_sessions" (
    "id" UUID NOT NULL,
    "game_type" VARCHAR(40) NOT NULL,
    "host_id" UUID NOT NULL,
    "match_id" UUID,
    "status" VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    "state" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "game_sessions_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "game_participants" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "answers" JSONB,
    CONSTRAINT "game_participants_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "game_participants_session_id_user_id_key"
ON "game_participants"("session_id", "user_id");

CREATE TABLE "call_sessions" (
    "id" UUID NOT NULL,
    "caller_id" UUID NOT NULL,
    "callee_id" UUID NOT NULL,
    "match_id" UUID NOT NULL,
    "call_type" VARCHAR(20) NOT NULL DEFAULT 'VIDEO',
    "status" VARCHAR(20) NOT NULL DEFAULT 'CALLING',
    "offer" JSONB,
    "answer" JSONB,
    "candidates" JSONB,
    "started_at" TIMESTAMP(3),
    "ended_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "call_sessions_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "user_inventories"
ADD CONSTRAINT "user_inventories_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_inventories"
ADD CONSTRAINT "user_inventories_item_id_fkey"
FOREIGN KEY ("item_id") REFERENCES "collectible_items"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_achievements"
ADD CONSTRAINT "user_achievements_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_achievements"
ADD CONSTRAINT "user_achievements_achievement_id_fkey"
FOREIGN KEY ("achievement_id") REFERENCES "achievements"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "notifications"
ADD CONSTRAINT "notifications_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "game_sessions"
ADD CONSTRAINT "game_sessions_host_id_fkey"
FOREIGN KEY ("host_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "game_participants"
ADD CONSTRAINT "game_participants_session_id_fkey"
FOREIGN KEY ("session_id") REFERENCES "game_sessions"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "game_participants"
ADD CONSTRAINT "game_participants_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "call_sessions"
ADD CONSTRAINT "call_sessions_caller_id_fkey"
FOREIGN KEY ("caller_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "call_sessions"
ADD CONSTRAINT "call_sessions_callee_id_fkey"
FOREIGN KEY ("callee_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;