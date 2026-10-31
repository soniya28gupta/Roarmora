import "dotenv/config";
import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import { authRouter, requireAuth, type AuthenticatedRequest } from "./auth.js";
import { prisma } from "./db.js";
import {
  approximateCoordinates,
  canonicalPair,
  DROP_COLLECTION_RADIUS_METERS,
  COLLECTIBLE_COLLECTION_RADIUS_METERS,
  REMOTE_EXPLORE_MAX_DISTANCE_METERS,
  haversineDistanceMeters,
} from "./geo.js";
import { errorHandler, fixedWindowLimit, HttpError, notFound } from "./http.js";
import {
  calculateCompatibility,
  DAILY_QUIZ_QUESTIONS,
} from "./matcher.js";
import {
  VIBE_TRIVIA_QUESTIONS,
  TRUTH_OR_DARE_PROMPTS,
  TREASURE_RACE_QUESTS,
} from "./games.js";
import {
  dropSchema,
  dropCollectionSchema,
  collectibleCollectSchema,
  blockSchema,
  messageSchema,
  preferenceSchema,
  profileSchema,
  reportSchema,
  searchSchema,
  swipeSchema,
  callInitiateSchema,
  callAnswerSchema,
  callCandidateSchema,
  gameStartSchema,
  gameActionSchema,
  quizSubmitSchema,
  useItemSchema,
} from "./validation.js";

export const app = express();
const api = express.Router();
const webOrigin = process.env.WEB_ORIGIN ?? "http://localhost:3000";

app.disable("x-powered-by");
app.use(helmet());
app.use(cors({ origin: webOrigin, credentials: true }));
app.use(express.json({ limit: "64kb" }));
app.use(cookieParser());

app.get("/health", async (_request, response) => {
  if (!process.env.DATABASE_URL) {
    response.status(503).json({ status: "unavailable", database: "not_configured" });
    return;
  }
  try {
    await prisma.$queryRaw`SELECT 1`;
    response.json({ status: "ok", database: "connected", platform: "Pookie Match" });
  } catch {
    response.status(503).json({ status: "unavailable", database: "unavailable" });
  }
});

app.use("/api/v1/auth", fixedWindowLimit(10, 15 * 60 * 1000), authRouter);
app.use("/api/v1", api);

// -----------------------------------------------------------------------------
// USER & PROFILE ENDPOINTS
// -----------------------------------------------------------------------------

api.get("/me", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: request.userId },
      select: {
        id: true,
        email: true,
        profile: true,
        preferences: true,
        birthDate: true,
        _count: {
          select: {
            inventories: true,
            achievements: true,
            matchesA: true,
            matchesB: true,
          },
        },
      },
    });
    if (!user) throw new HttpError(404, "Account not found");
    const age = ageOn(user.birthDate);
    const unreadNotifications = await prisma.notification.count({
      where: { userId: user.id, read: false },
    });

    response.json({
      id: user.id,
      email: user.email,
      age,
      profile: user.profile,
      preferences: user.preferences,
      stats: {
        itemsCount: user._count.inventories,
        achievementsCount: user._count.achievements,
        matchesCount: user._count.matchesA + user._count.matchesB,
        unreadNotifications,
      },
    });
  } catch (error) {
    next(error);
  }
});

api.patch("/profile", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const data = profileSchema.parse(request.body);
    const profile = await prisma.profile.update({
      where: { userId: request.userId },
      data,
    });
    response.json(profile);
  } catch (error) {
    next(error);
  }
});

api.put("/preferences", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const data = preferenceSchema.parse(request.body);
    const preferences = await prisma.preference.upsert({
      where: { userId: request.userId },
      create: { userId: request.userId!, interests: [], ...data },
      update: data,
    });
    response.json(preferences);
  } catch (error) {
    next(error);
  }
});

// Account deletion & privacy control (Requirement 2 & 12)
api.delete("/account", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    await prisma.user.delete({
      where: { id: request.userId },
    });
    response.clearCookie("session", { httpOnly: true, sameSite: "lax" });
    response.status(200).json({ message: "Your account and all associated data have been permanently deleted." });
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// TINDER-STYLE MATCHMAKING & DISCOVERY
// -----------------------------------------------------------------------------

api.get("/profiles", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const current = await prisma.user.findUnique({
      where: { id: request.userId },
      include: {
        profile: true,
        preferences: true,
        quizAnswers: true,
      },
    });
    if (!current) throw new HttpError(404, "Account not found");
    const prefs = current.preferences;

    const earliestBirth = new Date();
    earliestBirth.setFullYear(earliestBirth.getFullYear() - (prefs?.maxAge ?? 99) - 1);
    const latestBirth = new Date();
    latestBirth.setFullYear(latestBirth.getFullYear() - (prefs?.minAge ?? 18));

    const [alreadySwiped, blocked, candidateUsers] = await Promise.all([
      prisma.swipe.findMany({ where: { actorId: request.userId }, select: { targetId: true } }),
      prisma.block.findMany({
        where: { OR: [{ blockerId: request.userId }, { blockedId: request.userId }] },
        select: { blockerId: true, blockedId: true },
      }),
      prisma.user.findMany({
        where: {
          id: { not: request.userId },
          birthDate: { gte: earliestBirth, lte: latestBirth },
          profile: {
            is: {
              discoverable: true,
            },
          },
        },
        select: {
          id: true,
          birthDate: true,
          profile: true,
          quizAnswers: true,
        },
        take: 100,
      }),
    ]);

    const excluded = new Set([
      ...alreadySwiped.map(({ targetId }) => targetId),
      ...blocked.flatMap(({ blockerId, blockedId }) => [blockerId, blockedId]),
    ]);

    const myAnswersMap: Record<string, string> = {};
    for (const ans of current.quizAnswers) {
      myAnswersMap[ans.questionId] = ans.answerValue;
    }

    const eligible = candidateUsers.filter((u) => !excluded.has(u.id));

    const results = eligible.map((u) => {
      const otherAnswersMap: Record<string, string> = {};
      for (const ans of u.quizAnswers) {
        otherAnswersMap[ans.questionId] = ans.answerValue;
      }

      const comp = calculateCompatibility(
        {
          interests: current.profile?.interests ?? [],
          age: ageOn(current.birthDate),
          answers: myAnswersMap,
        },
        {
          interests: u.profile?.interests ?? [],
          age: ageOn(u.birthDate),
          answers: otherAnswersMap,
        },
      );

      return {
        ...u.profile,
        id: u.id,
        age: ageOn(u.birthDate),
        compatibility: comp,
        distanceLabel: prefs?.locationConsent ? "Within 5 km" : undefined,
      };
    });

    results.sort((a, b) => b.compatibility.score - a.compatibility.score);
    response.json(results);
  } catch (error) {
    next(error);
  }
});

api.post("/swipes", requireAuth, fixedWindowLimit(90, 60_000), async (request: AuthenticatedRequest, response, next) => {
  try {
    const { targetUserId, direction } = swipeSchema.parse(request.body);
    if (targetUserId === request.userId) {
      throw new HttpError(400, "You cannot swipe on your own profile");
    }
    const pair = canonicalPair(request.userId!, targetUserId);

    await prisma.$transaction(async (transaction) => {
      const target = await transaction.user.findUnique({
        where: { id: targetUserId },
        select: { id: true },
      });
      if (!target) throw new HttpError(404, "Profile not found");

      const block = await transaction.block.findFirst({
        where: {
          OR: [
            { blockerId: request.userId, blockedId: targetUserId },
            { blockerId: targetUserId, blockedId: request.userId },
          ],
        },
      });
      if (block) throw new HttpError(403, "This profile is unavailable");

      await transaction.swipe.upsert({
        where: { actorId_targetId: { actorId: request.userId!, targetId: targetUserId } },
        create: { actorId: request.userId!, targetId: targetUserId, direction },
        update: { direction },
      });
    });

    if (direction !== "LIKE") {
      response.json({ matched: false });
      return;
    }

    const matchInfo = await prisma.$transaction(async (transaction) => {
      const mutual = await transaction.swipe.findFirst({
        where: { actorId: targetUserId, targetId: request.userId, direction: "LIKE" },
      });
      if (!mutual) return null;

      const match = await transaction.match.upsert({
        where: { userAId_userBId: { userAId: pair[0], userBId: pair[1] } },
        create: { userAId: pair[0], userBId: pair[1] },
        update: {},
        select: { id: true },
      });

      // Unlock Cupid's Arrow achievement for both if models are present
      if ((transaction as any).achievement?.findUnique) {
        const cupidAchievement = await (transaction as any).achievement.findUnique({
          where: { slug: "cupids-arrow" },
        });
        if (cupidAchievement && (transaction as any).userAchievement) {
          await (transaction as any).userAchievement.upsert({
            where: { userId_achievementId: { userId: request.userId!, achievementId: cupidAchievement.id } },
            create: { userId: request.userId!, achievementId: cupidAchievement.id },
            update: {},
          });
          await (transaction as any).userAchievement.upsert({
            where: { userId_achievementId: { userId: targetUserId, achievementId: cupidAchievement.id } },
            create: { userId: targetUserId, achievementId: cupidAchievement.id },
            update: {},
          });
        }
      }

      // Notify target of new match
      if ((transaction as any).profile?.findUnique && (transaction as any).notification?.create) {
        const actorProfile = await (transaction as any).profile.findUnique({
          where: { userId: request.userId },
          select: { displayName: true },
        });
        await (transaction as any).notification.create({
          data: {
            userId: targetUserId,
            type: "MATCH",
            title: "It's a Mutual Spark! ✨",
            message: `You and ${actorProfile?.displayName ?? "someone"} liked each other! Start chatting now.`,
            link: `/chat?matchId=${match.id}`,
          },
        });
      }

      return match.id;
    });

    if (!matchInfo) {
      response.json({ matched: false });
      return;
    }

    response.json({
      matched: true,
      matchId: matchInfo,
    });
  } catch (error) {
    next(error);
  }
});

api.get("/matches", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const matches = await prisma.match.findMany({
      where: { OR: [{ userAId: request.userId }, { userBId: request.userId }] },
      include: {
        userA: { include: { profile: true, quizAnswers: true } },
        userB: { include: { profile: true, quizAnswers: true } },
        messages: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
      orderBy: { createdAt: "desc" },
    });

    const currentUser = await prisma.user.findUnique({
      where: { id: request.userId },
      include: { profile: true, quizAnswers: true },
    });

    const visible = await Promise.all(
      matches.map(async (match) => {
        const other = match.userAId === request.userId ? match.userB : match.userA;
        const blocked = await prisma.block.findFirst({
          where: {
            OR: [
              { blockerId: request.userId, blockedId: other.id },
              { blockerId: other.id, blockedId: request.userId },
            ],
          },
        });
        if (blocked) return null;

        const myAnswersMap: Record<string, string> = {};
        for (const a of currentUser?.quizAnswers ?? []) myAnswersMap[a.questionId] = a.answerValue;
        const otherAnswersMap: Record<string, string> = {};
        for (const a of other.quizAnswers) otherAnswersMap[a.questionId] = a.answerValue;

        const comp = calculateCompatibility(
          {
            interests: currentUser?.profile?.interests ?? [],
            age: currentUser ? ageOn(currentUser.birthDate) : undefined,
            answers: myAnswersMap,
          },
          {
            interests: other.profile?.interests ?? [],
            age: ageOn(other.birthDate),
            answers: otherAnswersMap,
          },
        );

        return {
          id: match.id,
          createdAt: match.createdAt,
          lastMessage: match.messages[0] ? {
            text: match.messages[0].body,
            time: match.messages[0].createdAt,
            fromMe: match.messages[0].senderId === request.userId,
          } : null,
          profile: other.profile && {
            ...other.profile,
            id: other.id,
            age: ageOn(other.birthDate),
            compatibility: comp,
          },
        };
      }),
    );

    response.json(visible.filter(Boolean));
  } catch (error) {
    next(error);
  }
});

api.delete("/matches/:matchId", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const matchId = routeParam(request.params.matchId);
    const result = await prisma.match.deleteMany({
      where: {
        id: matchId,
        OR: [{ userAId: request.userId }, { userBId: request.userId }],
      },
    });
    if (result.count === 0) throw new HttpError(404, "Match not found");
    response.status(204).end();
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// ADVENTURE MODE, PLACES & DROPS
// -----------------------------------------------------------------------------

api.get("/places", requireAuth, async (_request, response, next) => {
  try {
    const places = await prisma.place.findMany({
      select: {
        id: true,
        name: true,
        category: true,
        neighborhood: true,
        description: true,
        latitude: true,
        longitude: true,
        fictional: true,
      },
      orderBy: { name: "asc" },
      take: 100,
    });
    response.json(places);
  } catch (error) {
    next(error);
  }
});

api.get("/drops", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const preference = await prisma.preference.findUnique({
      where: { userId: request.userId },
      select: { locationConsent: true, globalExploreMode: true },
    });

    if (request.query.latitude !== undefined || request.query.longitude !== undefined) {
      const search = searchSchema.parse(request.query);
      if (!preference?.locationConsent && !preference?.globalExploreMode) {
        throw new HttpError(403, "Enable location discovery consent in preferences first");
      }
      const point = approximateCoordinates(search);

      // Robust geospatial query using haversine calculation in PostgreSQL
      const rows = await prisma.$queryRaw<Array<{
        id: string; title: string; description: string; interest: string; startsAt: Date;
        areaLabel: string; latitude: number; longitude: number; hostId: string;
      }>>`
        SELECT d.id, d.title, d.description, d.interest, d.starts_at AS "startsAt",
          d.area_label AS "areaLabel",
          round(d.latitude::numeric, 4)::float8 AS latitude,
          round(d.longitude::numeric, 4)::float8 AS longitude, d.host_id AS "hostId"
        FROM drops d
        JOIN users u ON u.id = d.host_id
        WHERE d.starts_at >= NOW()
          AND d.location_consent = true
          AND (6371000 * acos(least(1.0, greatest(-1.0,
            cos(radians(${point.latitude})) * cos(radians(d.latitude)) *
            cos(radians(d.longitude) - radians(${point.longitude})) +
            sin(radians(${point.latitude})) * sin(radians(d.latitude))
          )))) <= ${search.radiusKm * 1000}
          AND NOT EXISTS (
            SELECT 1 FROM blocks b
            WHERE (b.blocker_id = ${request.userId}::uuid AND b.blocked_id = d.host_id)
               OR (b.blocker_id = d.host_id AND b.blocked_id = ${request.userId}::uuid)
          )
        ORDER BY d.starts_at ASC LIMIT 100
      `;
      response.json(rows.map(({ hostId: _hostId, ...drop }) => drop));
      return;
    }

    const blocks = await prisma.block.findMany({
      where: { OR: [{ blockerId: request.userId }, { blockedId: request.userId }] },
      select: { blockerId: true, blockedId: true },
    });
    const hiddenHosts = [...new Set(blocks.map(({ blockerId, blockedId }) =>
      blockerId === request.userId ? blockedId : blockerId,
    ))];

    const drops = await prisma.drop.findMany({
      where: { startsAt: { gte: new Date() }, hostId: { notIn: hiddenHosts } },
      select: {
        id: true,
        title: true,
        description: true,
        interest: true,
        startsAt: true,
        areaLabel: true,
        latitude: true,
        longitude: true,
      },
      orderBy: { startsAt: "asc" },
      take: 100,
    });
    response.json(drops);
  } catch (error) {
    next(error);
  }
});

api.post("/drops", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const input = dropSchema.parse(request.body);
    const preference = await prisma.preference.findUnique({
      where: { userId: request.userId },
      select: { locationConsent: true },
    });
    if (!preference?.locationConsent) {
      throw new HttpError(403, "Enable location sharing consent in preferences first");
    }

    const drop = await prisma.drop.create({
      data: {
        hostId: request.userId!,
        title: input.title,
        description: input.description,
        interest: input.interest,
        startsAt: input.startsAt,
        areaLabel: input.areaLabel,
        latitude: input.latitude,
        longitude: input.longitude,
        locationConsent: true,
      },
      select: { id: true, title: true, description: true, interest: true, startsAt: true, areaLabel: true },
    });
    response.status(201).json(drop);
  } catch (error) {
    next(error);
  }
});

api.post("/drops/:dropId/collect", requireAuth, fixedWindowLimit(15, 60_000), async (request: AuthenticatedRequest, response, next) => {
  try {
    const dropId = routeParam(request.params.dropId);
    const input = dropCollectionSchema.parse(request.body);
    const preference = await prisma.preference.findUnique({
      where: { userId: request.userId },
      select: { locationConsent: true, globalExploreMode: true },
    });

    if (!preference?.locationConsent && !preference?.globalExploreMode) {
      throw new HttpError(403, "Enable location discovery consent in preferences first");
    }

    const allowedRadius = preference?.globalExploreMode && input.remoteMode
      ? REMOTE_EXPLORE_MAX_DISTANCE_METERS
      : DROP_COLLECTION_RADIUS_METERS;

    const collection = await prisma.$transaction(async (transaction) => {
      const drop = await transaction.drop.findUnique({
        where: { id: dropId },
      });
      if (!drop) throw new HttpError(404, "Drop not found");
      if (drop.hostId === request.userId) throw new HttpError(400, "You cannot collect your own drop");

      const dist = haversineDistanceMeters(
        input.latitude,
        input.longitude,
        drop.latitude,
        drop.longitude,
      );

      if (dist > allowedRadius) {
        throw new HttpError(400, `You are ${Math.round(dist)}m away. Drop requires being within ${allowedRadius}m.`);
      }

      const blocked = await transaction.block.findFirst({
        where: {
          OR: [
            { blockerId: request.userId, blockedId: drop.hostId },
            { blockerId: drop.hostId, blockedId: request.userId },
          ],
        },
      });
      if (blocked) throw new HttpError(404, "Drop not found");

      return transaction.dropCollection.upsert({
        where: { userId_dropId: { userId: request.userId!, dropId: drop.id } },
        create: { userId: request.userId!, dropId: drop.id },
        update: {},
        select: { userId: true, dropId: true, collectedAt: true },
      });
    });

    response.status(200).json(collection);
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// VIRTUAL COLLECTIBLES & INVENTORY
// -----------------------------------------------------------------------------

api.get("/collectibles", requireAuth, async (_request, response, next) => {
  try {
    const items = await prisma.collectibleItem.findMany({
      where: { active: true },
      orderBy: { createdAt: "asc" },
    });
    response.json(items);
  } catch (error) {
    next(error);
  }
});

api.get("/inventory", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const inventory = await prisma.userInventory.findMany({
      where: { userId: request.userId },
      include: { item: true },
      orderBy: { acquiredAt: "desc" },
    });
    response.json(inventory);
  } catch (error) {
    next(error);
  }
});

api.post("/collectibles/:itemId/collect", requireAuth, fixedWindowLimit(20, 60_000), async (request: AuthenticatedRequest, response, next) => {
  try {
    const itemId = routeParam(request.params.itemId);
    const input = collectibleCollectSchema.parse(request.body);
    const preference = await prisma.preference.findUnique({
      where: { userId: request.userId },
      select: { locationConsent: true, globalExploreMode: true },
    });

    const item = await prisma.collectibleItem.findUnique({
      where: { id: itemId },
    });
    if (!item || !item.active) throw new HttpError(404, "Collectible item not found or inactive");

    // Server-side distance verification
    if (item.latitude !== null && item.longitude !== null) {
      const allowedRadius = preference?.globalExploreMode && input.remoteMode
        ? REMOTE_EXPLORE_MAX_DISTANCE_METERS
        : COLLECTIBLE_COLLECTION_RADIUS_METERS;

      const dist = haversineDistanceMeters(
        input.latitude,
        input.longitude,
        item.latitude,
        item.longitude,
      );

      if (dist > allowedRadius) {
        throw new HttpError(
          400,
          `Too far to collect! You are ${Math.round(dist)}m away. Get within ${allowedRadius}m or enable Remote Explorer mode.`,
        );
      }
    }

    const inventoryRecord = await prisma.$transaction(async (transaction) => {
      const inv = await transaction.userInventory.upsert({
        where: { userId_itemId: { userId: request.userId!, itemId: item.id } },
        create: { userId: request.userId!, itemId: item.id, quantity: 1 },
        update: { quantity: { increment: 1 } },
        include: { item: true },
      });

      // Unlock Treasure Hunter achievement
      const hunterAch = await transaction.achievement.findUnique({
        where: { slug: "treasure-hunter" },
      });
      if (hunterAch) {
        await transaction.userAchievement.upsert({
          where: { userId_achievementId: { userId: request.userId!, achievementId: hunterAch.id } },
          create: { userId: request.userId!, achievementId: hunterAch.id },
          update: {},
        });
      }

      // Create notification
      await transaction.notification.create({
        data: {
          userId: request.userId!,
          type: "COLLECTIBLE",
          title: `Claimed ${item.name}! ${item.icon}`,
          message: item.description,
          link: "/profile",
        },
      });

      return inv;
    });

    response.status(200).json({
      success: true,
      item: inventoryRecord.item,
      quantity: inventoryRecord.quantity,
      message: `You collected ${item.name}! Check your profile inventory.`,
    });
  } catch (error) {
    next(error);
  }
});

api.post("/inventory/:itemId/use", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const itemId = routeParam(request.params.itemId);
    const { targetMatchId } = useItemSchema.parse(request.body);

    const inv = await prisma.userInventory.findUnique({
      where: { userId_itemId: { userId: request.userId!, itemId } },
      include: { item: true },
    });
    if (!inv || inv.quantity < 1) {
      throw new HttpError(400, "You don't have this item in your inventory.");
    }

    let resultMessage = `You activated ${inv.item.name}!`;

    if (targetMatchId) {
      await assertMatchAccess(request.userId!, targetMatchId);
      const match = await prisma.match.findUnique({ where: { id: targetMatchId } });
      const recipientId = match!.userAId === request.userId ? match!.userBId : match!.userAId;

      await prisma.$transaction(async (transaction) => {
        // Decrement quantity
        if (inv.quantity === 1) {
          await transaction.userInventory.delete({ where: { id: inv.id } });
        } else {
          await transaction.userInventory.update({
            where: { id: inv.id },
            data: { quantity: { decrement: 1 } },
          });
        }

        // Post chat message with item perk
        await transaction.message.create({
          data: {
            matchId: targetMatchId,
            senderId: request.userId!,
            body: `Sent a virtual gift: ${inv.item.icon} ${inv.item.name}! "${inv.item.perkDescription || inv.item.description}"`,
          },
        });

        // Notify recipient
        await transaction.notification.create({
          data: {
            userId: recipientId,
            type: "COLLECTIBLE",
            title: `Gift from your match! ${inv.item.icon}`,
            message: `Your match sent you a ${inv.item.name}!`,
            link: `/chat?matchId=${targetMatchId}`,
          },
        });
      });
      resultMessage = `Sent ${inv.item.name} to your match!`;
    }

    response.json({ success: true, message: resultMessage });
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// ACHIEVEMENTS
// -----------------------------------------------------------------------------

api.get("/achievements", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const [all, userAchievements] = await Promise.all([
      prisma.achievement.findMany({ orderBy: { points: "asc" } }),
      prisma.userAchievement.findMany({
        where: { userId: request.userId },
        include: { achievement: true },
      }),
    ]);

    const unlockedSet = new Set(userAchievements.map((ua) => ua.achievementId));
    const totalPoints = userAchievements.reduce((sum, ua) => sum + ua.achievement.points, 0);

    const payload = all.map((ach) => ({
      ...ach,
      unlocked: unlockedSet.has(ach.id),
      unlockedAt: userAchievements.find((ua) => ua.achievementId === ach.id)?.unlockedAt ?? null,
    }));

    response.json({ achievements: payload, totalPoints });
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// NOTIFICATIONS
// -----------------------------------------------------------------------------

api.get("/notifications", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: request.userId },
      orderBy: { createdAt: "desc" },
      take: 50,
    });
    const unreadCount = notifications.filter((n) => !n.read).length;
    response.json({ notifications, unreadCount });
  } catch (error) {
    next(error);
  }
});

api.patch("/notifications/:id/read", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const id = routeParam(request.params.id);
    await prisma.notification.updateMany({
      where: { id, userId: request.userId },
      data: { read: true },
    });
    response.status(204).end();
  } catch (error) {
    next(error);
  }
});

api.post("/notifications/read-all", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: request.userId, read: false },
      data: { read: true },
    });
    response.json({ success: true });
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// AI COMPATIBILITY MATCHER & DAILY QUIZ
// -----------------------------------------------------------------------------

api.get("/quiz/daily", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const myAnswers = await prisma.quizAnswer.findMany({
      where: { userId: request.userId },
    });
    const answeredMap: Record<string, string> = {};
    for (const a of myAnswers) answeredMap[a.questionId] = a.answerValue;

    response.json({
      questions: DAILY_QUIZ_QUESTIONS,
      answered: answeredMap,
    });
  } catch (error) {
    next(error);
  }
});

api.post("/quiz/submit", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const { answers } = quizSubmitSchema.parse(request.body);

    await prisma.$transaction(async (transaction) => {
      for (const ans of answers) {
        await transaction.quizAnswer.upsert({
          where: { userId_questionId: { userId: request.userId!, questionId: ans.questionId } },
          create: {
            userId: request.userId!,
            questionId: ans.questionId,
            category: ans.category,
            answerValue: ans.answerValue,
          },
          update: {
            category: ans.category,
            answerValue: ans.answerValue,
          },
        });
      }
    });

    response.json({ success: true, message: "Your answers have updated your compatibility profile!" });
  } catch (error) {
    next(error);
  }
});

api.get("/compatibility/:targetUserId", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const targetUserId = routeParam(request.params.targetUserId);
    const [me, other] = await Promise.all([
      prisma.user.findUnique({
        where: { id: request.userId },
        include: { profile: true, quizAnswers: true },
      }),
      prisma.user.findUnique({
        where: { id: targetUserId },
        include: { profile: true, quizAnswers: true },
      }),
    ]);
    if (!me || !other) throw new HttpError(404, "Profile not found");

    const myAnswers: Record<string, string> = {};
    for (const a of me.quizAnswers) myAnswers[a.questionId] = a.answerValue;
    const otherAnswers: Record<string, string> = {};
    for (const a of other.quizAnswers) otherAnswers[a.questionId] = a.answerValue;

    const breakdown = calculateCompatibility(
      { interests: me.profile?.interests ?? [], age: ageOn(me.birthDate), answers: myAnswers },
      { interests: other.profile?.interests ?? [], age: ageOn(other.birthDate), answers: otherAnswers },
    );

    response.json(breakdown);
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// IN-APP MINI-GAMES
// -----------------------------------------------------------------------------

api.get("/games", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const sessions = await prisma.gameSession.findMany({
      where: {
        OR: [
          { hostId: request.userId },
          { participants: { some: { userId: request.userId } } },
        ],
      },
      include: {
        participants: { include: { user: { include: { profile: true } } } },
      },
      orderBy: { updatedAt: "desc" },
      take: 20,
    });
    response.json(sessions);
  } catch (error) {
    next(error);
  }
});

api.post("/games/start", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const { gameType, matchId } = gameStartSchema.parse(request.body);
    let targetParticipantId: string | null = null;

    if (matchId) {
      await assertMatchAccess(request.userId!, matchId);
      const match = await prisma.match.findUnique({ where: { id: matchId } });
      targetParticipantId = match!.userAId === request.userId ? match!.userBId : match!.userAId;
    }

    let initialQuestions: any = null;
    if (gameType === "VIBE_CHECK") {
      initialQuestions = VIBE_TRIVIA_QUESTIONS;
    } else if (gameType === "TRUTH_OR_DARE") {
      initialQuestions = TRUTH_OR_DARE_PROMPTS;
    } else if (gameType === "TREASURE_RACE") {
      initialQuestions = TREASURE_RACE_QUESTS;
    } else {
      initialQuestions = DAILY_QUIZ_QUESTIONS;
    }

    const session = await prisma.$transaction(async (transaction) => {
      const gs = await transaction.gameSession.create({
        data: {
          gameType,
          hostId: request.userId!,
          matchId,
          status: "ACTIVE",
          state: {
            content: initialQuestions,
            round: 1,
            history: [],
          },
        },
      });

      // Add host as participant
      await transaction.gameParticipant.create({
        data: { sessionId: gs.id, userId: request.userId! },
      });

      // Add matched partner as participant if applicable
      if (targetParticipantId) {
        await transaction.gameParticipant.create({
          data: { sessionId: gs.id, userId: targetParticipantId },
        });

        // Notify partner
        const myProfile = await transaction.profile.findUnique({ where: { userId: request.userId } });
        await transaction.notification.create({
          data: {
            userId: targetParticipantId,
            type: "INVITE",
            title: `Mini-Game Invite from ${myProfile?.displayName ?? "Match"}! 🎮`,
            message: `Invited you to play ${gameType.replace(/_/g, " ")}. Tap to join!`,
            link: `/chat?matchId=${matchId}`,
          },
        });
      }

      return gs;
    });

    response.status(201).json(session);
  } catch (error) {
    next(error);
  }
});

api.get("/games/:sessionId", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const sessionId = routeParam(request.params.sessionId);
    const session = await prisma.gameSession.findUnique({
      where: { id: sessionId },
      include: {
        participants: { include: { user: { include: { profile: true } } } },
      },
    });
    if (!session) throw new HttpError(404, "Game session not found");
    const isParticipant = session.participants.some((p) => p.userId === request.userId) || session.hostId === request.userId;
    if (!isParticipant) throw new HttpError(403, "Access denied to this game session");

    response.json(session);
  } catch (error) {
    next(error);
  }
});

api.post("/games/:sessionId/action", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const sessionId = routeParam(request.params.sessionId);
    const { action, payload } = gameActionSchema.parse(request.body);

    const session = await prisma.gameSession.findUnique({
      where: { id: sessionId },
      include: { participants: true },
    });
    if (!session) throw new HttpError(404, "Game session not found");

    const updated = await prisma.$transaction(async (transaction) => {
      const participant = await transaction.gameParticipant.findUnique({
        where: { sessionId_userId: { sessionId, userId: request.userId! } },
      });
      if (!participant) throw new HttpError(403, "You are not a participant in this game");

      const existingAnswers = (participant.answers as any) || {};
      const newAnswers = { ...existingAnswers, [action]: payload, updatedAt: new Date().toISOString() };
      let scoreIncrement = 10;

      if (session.gameType === "VIBE_CHECK" && payload?.correct) {
        scoreIncrement = 20;
      }

      await transaction.gameParticipant.update({
        where: { id: participant.id },
        data: {
          answers: newAnswers,
          score: { increment: scoreIncrement },
          completed: payload?.completed ?? false,
        },
      });

      // If Truth Seeker game, unlock Truth Seeker achievement
      if (session.gameType === "TRUTH_OR_DARE") {
        const ach = await transaction.achievement.findUnique({ where: { slug: "truth-seeker" } });
        if (ach) {
          await transaction.userAchievement.upsert({
            where: { userId_achievementId: { userId: request.userId!, achievementId: ach.id } },
            create: { userId: request.userId!, achievementId: ach.id },
            update: {},
          });
        }
      }

      // If Vibe Master, unlock Vibe Master achievement
      if (session.gameType === "VIBE_CHECK") {
        const ach = await transaction.achievement.findUnique({ where: { slug: "vibe-master" } });
        if (ach) {
          await transaction.userAchievement.upsert({
            where: { userId_achievementId: { userId: request.userId!, achievementId: ach.id } },
            create: { userId: request.userId!, achievementId: ach.id },
            update: {},
          });
        }
      }

      return transaction.gameSession.findUnique({
        where: { id: sessionId },
        include: { participants: { include: { user: { include: { profile: true } } } } },
      });
    });

    response.json(updated);
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// WEBRTC AUDIO/VIDEO CALLING
// -----------------------------------------------------------------------------

api.post("/calls/initiate", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const { targetUserId, matchId, callType, offer } = callInitiateSchema.parse(request.body);
    await assertMatchAccess(request.userId!, matchId);

    // End any existing active calls between these users
    await prisma.callSession.updateMany({
      where: {
        matchId,
        status: { in: ["CALLING", "ACCEPTED"] },
      },
      data: { status: "ENDED", endedAt: new Date() },
    });

    const call = await prisma.callSession.create({
      data: {
        callerId: request.userId!,
        calleeId: targetUserId,
        matchId,
        callType,
        status: "CALLING",
        offer: offer ?? null,
      },
      include: {
        caller: { include: { profile: true } },
        callee: { include: { profile: true } },
      },
    });

    // Notify callee
    await prisma.notification.create({
      data: {
        userId: targetUserId,
        type: "CALL",
        title: `Incoming ${callType.toLowerCase()} call from ${call.caller.profile?.displayName ?? "Match"}`,
        message: "Tap to answer your incoming call.",
        link: `/chat?matchId=${matchId}&callId=${call.id}`,
      },
    });

    response.status(201).json(call);
  } catch (error) {
    next(error);
  }
});

api.get("/calls/active", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const matchIdQuery = request.query.matchId ? String(request.query.matchId) : undefined;
    const call = await prisma.callSession.findFirst({
      where: {
        status: { in: ["CALLING", "ACCEPTED"] },
        OR: [{ callerId: request.userId }, { calleeId: request.userId }],
        ...(matchIdQuery ? { matchId: matchIdQuery } : {}),
      },
      include: {
        caller: { include: { profile: true } },
        callee: { include: { profile: true } },
      },
      orderBy: { createdAt: "desc" },
    });

    response.json(call);
  } catch (error) {
    next(error);
  }
});

api.post("/calls/:callId/answer", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const callId = routeParam(request.params.callId);
    const { answer } = callAnswerSchema.parse(request.body);

    const call = await prisma.callSession.findUnique({ where: { id: callId } });
    if (!call || call.calleeId !== request.userId) {
      throw new HttpError(404, "Call not found or unauthorized to answer");
    }

    const updated = await prisma.callSession.update({
      where: { id: callId },
      data: {
        status: "ACCEPTED",
        answer,
        startedAt: new Date(),
      },
    });

    response.json(updated);
  } catch (error) {
    next(error);
  }
});

api.post("/calls/:callId/candidate", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const callId = routeParam(request.params.callId);
    const { candidate } = callCandidateSchema.parse(request.body);

    const call = await prisma.callSession.findUnique({ where: { id: callId } });
    if (!call || (call.callerId !== request.userId && call.calleeId !== request.userId)) {
      throw new HttpError(404, "Call not found");
    }

    const existing = (call.candidates as any[]) || [];
    const updatedCandidates = [...existing, { from: request.userId, candidate, time: Date.now() }];

    await prisma.callSession.update({
      where: { id: callId },
      data: { candidates: updatedCandidates },
    });

    response.json({ success: true });
  } catch (error) {
    next(error);
  }
});

api.post("/calls/:callId/end", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const callId = routeParam(request.params.callId);
    const call = await prisma.callSession.findUnique({ where: { id: callId } });
    if (!call || (call.callerId !== request.userId && call.calleeId !== request.userId)) {
      throw new HttpError(404, "Call not found");
    }

    const updated = await prisma.callSession.update({
      where: { id: callId },
      data: {
        status: "ENDED",
        endedAt: new Date(),
      },
    });

    // If call lasted > 10 seconds, award Real Connection achievement
    if (call.startedAt) {
      const durationSec = (Date.now() - new Date(call.startedAt).getTime()) / 1000;
      if (durationSec > 10) {
        const ach = await prisma.achievement.findUnique({ where: { slug: "real-connection" } });
        if (ach) {
          await prisma.userAchievement.upsert({
            where: { userId_achievementId: { userId: request.userId!, achievementId: ach.id } },
            create: { userId: request.userId!, achievementId: ach.id },
            update: {},
          });
        }
      }
    }

    response.json(updated);
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// MESSAGES, BLOCKS, AND REPORTS
// -----------------------------------------------------------------------------

api.get("/matches/:matchId/messages", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const matchId = routeParam(request.params.matchId);
    await assertMatchAccess(request.userId!, matchId);
    const messages = await prisma.message.findMany({
      where: { matchId },
      orderBy: { createdAt: "asc" },
      take: 200,
      select: { id: true, senderId: true, body: true, createdAt: true },
    });
    response.json(messages);
  } catch (error) {
    next(error);
  }
});

api.post("/matches/:matchId/messages", requireAuth, fixedWindowLimit(60, 60_000), async (request: AuthenticatedRequest, response, next) => {
  try {
    const matchId = routeParam(request.params.matchId);
    await assertMatchAccess(request.userId!, matchId);
    const { body } = messageSchema.parse(request.body);

    const message = await prisma.$transaction(async (transaction) => {
      const msg = await transaction.message.create({
        data: { matchId, senderId: request.userId!, body },
        select: { id: true, senderId: true, body: true, createdAt: true },
      });

      const match = await transaction.match.findUnique({ where: { id: matchId } });
      const recipientId = match!.userAId === request.userId ? match!.userBId : match!.userAId;
      const senderProfile = await transaction.profile.findUnique({ where: { userId: request.userId } });

      await transaction.notification.create({
        data: {
          userId: recipientId,
          type: "MESSAGE",
          title: `New message from ${senderProfile?.displayName ?? "Match"}`,
          message: body.slice(0, 100),
          link: `/chat?matchId=${matchId}`,
        },
      });

      return msg;
    });

    response.status(201).json(message);
  } catch (error) {
    next(error);
  }
});

api.post("/blocks", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const { targetUserId } = blockSchema.parse(request.body);
    if (targetUserId === request.userId) throw new HttpError(400, "You cannot block yourself");
    const target = await prisma.user.findUnique({ where: { id: targetUserId }, select: { id: true } });
    if (!target) throw new HttpError(404, "Profile not found");

    await prisma.$transaction(async (transaction) => {
      await transaction.block.upsert({
        where: { blockerId_blockedId: { blockerId: request.userId!, blockedId: targetUserId } },
        create: { blockerId: request.userId!, blockedId: targetUserId },
        update: {},
      });
      const pair = canonicalPair(request.userId!, targetUserId);
      await transaction.match.deleteMany({ where: { userAId: pair[0], userBId: pair[1] } });
    });
    response.status(204).end();
  } catch (error) {
    next(error);
  }
});

api.post("/reports", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const input = reportSchema.parse(request.body);
    if (input.targetUserId === request.userId) throw new HttpError(400, "You cannot report yourself");
    const reported = await prisma.user.findUnique({ where: { id: input.targetUserId }, select: { id: true } });
    if (!reported) throw new HttpError(404, "Profile not found");

    const report = await prisma.report.create({
      data: { reporterId: request.userId!, ...input },
      select: { id: true, status: true, createdAt: true },
    });
    response.status(201).json(report);
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// HELPERS
// -----------------------------------------------------------------------------

async function assertMatchAccess(userId: string, matchId: string): Promise<void> {
  const match = await prisma.match.findUnique({ where: { id: matchId }, select: { userAId: true, userBId: true } });
  if (!match || (match.userAId !== userId && match.userBId !== userId)) {
    throw new HttpError(404, "Match not found");
  }
  const otherUserId = match.userAId === userId ? match.userBId : match.userAId;
  const blocked = await prisma.block.findFirst({
    where: {
      OR: [
        { blockerId: userId, blockedId: otherUserId },
        { blockerId: otherUserId, blockedId: userId },
      ],
    },
  });
  if (blocked) throw new HttpError(404, "Match not found");
}

function ageOn(birthDate: Date): number {
  const today = new Date();
  let age = today.getUTCFullYear() - birthDate.getUTCFullYear();
  if (today.getUTCMonth() < birthDate.getUTCMonth() ||
    (today.getUTCMonth() === birthDate.getUTCMonth() && today.getUTCDate() < birthDate.getUTCDate())) age -= 1;
  return age;
}

function routeParam(value: string | string[] | undefined): string {
  const result = Array.isArray(value) ? value[0] : value;
  if (!result) throw new HttpError(400, "Invalid route parameter");
  return result;
}

app.use(notFound);
app.use(errorHandler);
