import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import type {
  AccountProfile,
  ChatMessage,
  CollectibleItem,
  UserInventoryItem,
  Achievement,
  AppNotification,
  Match,
  Profile,
  GameSession,
  Drop,
} from "@/types/roamora";

interface ApiErrorBody {
  error?: string;
  code?: string;
}

const apiOrigin = process.env.ROAMORA_API_URL ?? "http://127.0.0.1:8081";

async function request<T>(path: string): Promise<T> {
  const cookieJar = await cookies();
  const cookieHeader = cookieJar.getAll().map(({ name, value }) => `${name}=${value}`).join("; ");
  let response: Response;
  try {
    response = await fetch(new URL(`/api/v1${path}`, apiOrigin), {
      headers: { accept: "application/json", cookie: cookieHeader },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw new Error("Pookie Match API could not be reached. Start the API server and try again.");
  }

  const body: unknown = response.status === 204 ? undefined : await response.json();
  if (response.status === 401) redirect("/login");
  if (!response.ok) {
    const errorBody = body as ApiErrorBody | undefined;
    throw new Error(errorBody?.error ?? `Pookie Match could not load this page (HTTP ${response.status}).`);
  }
  return body as T;
}

export const liveApi = {
  async getCurrentUser(): Promise<AccountProfile> {
    const user = await request<any>("/me");
    if (!user.profile) throw new Error("Your account profile is incomplete. Please complete profile setup.");
    return {
      id: user.id,
      email: user.email,
      birthDate: user.birthDate,
      displayName: user.profile.displayName,
      city: user.profile.city,
      bio: user.profile.bio,
      interests: user.profile.interests,
      imageUrl: user.profile.imageUrl,
      photos: user.profile.photos ?? [],
      gender: user.profile.gender,
      lookingFor: user.profile.lookingFor,
      discoverable: user.profile.discoverable,
      locationConsent: user.preferences?.locationConsent ?? false,
      globalExploreMode: user.preferences?.globalExploreMode ?? false,
      discoveryRadiusMeters: user.preferences?.discoveryRadiusMeters ?? 500,
      stats: user.stats,
    };
  },

  async listProfiles(): Promise<Profile[]> {
    const profiles = await request<any[]>("/profiles");
    return profiles.map((p) => ({
      id: p.id,
      name: p.displayName,
      age: p.age,
      city: p.city,
      bio: p.bio,
      interests: p.interests,
      image: p.imageUrl,
      photos: p.photos ?? [],
      gender: p.gender,
      lookingFor: p.lookingFor,
      compatibility: p.compatibility,
      distanceLabel: p.distanceLabel,
    }));
  },

  async listMatches(): Promise<Match[]> {
    const matches = await request<any[]>("/matches");
    return matches.flatMap((m) => m.profile ? [{
      id: m.id,
      otherUserId: m.profile.id,
      name: m.profile.displayName,
      age: m.profile.age,
      city: m.profile.city,
      bio: m.profile.bio,
      interests: m.profile.interests,
      image: m.profile.imageUrl,
      photos: m.profile.photos ?? [],
      lastMessage: m.lastMessage,
      compatibility: m.profile.compatibility,
    }] : []);
  },

  async listMessages(matchId: string, currentUserId: string): Promise<ChatMessage[]> {
    const messages = await request<any[]>(`/matches/${encodeURIComponent(matchId)}/messages`);
    return messages.map((m) => ({
      id: m.id,
      from: m.senderId === currentUserId ? "you" : "other",
      text: m.body,
      time: new Date(m.createdAt).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }),
    }));
  },

  async listCollectibles(): Promise<CollectibleItem[]> {
    return request<CollectibleItem[]>("/collectibles");
  },

  async listInventory(): Promise<UserInventoryItem[]> {
    return request<UserInventoryItem[]>("/inventory");
  },

  async listAchievements(): Promise<{ achievements: Achievement[]; totalPoints: number }> {
    return request<{ achievements: Achievement[]; totalPoints: number }>("/achievements");
  },

  async listNotifications(): Promise<{ notifications: AppNotification[]; unreadCount: number }> {
    return request<{ notifications: AppNotification[]; unreadCount: number }>("/notifications");
  },

  async listDrops(): Promise<Drop[]> {
    const drops = await request<any[]>("/drops");
    return drops.map((d, index) => ({
      id: d.id,
      title: d.title,
      host: "Community Host",
      startsAt: new Date(d.startsAt).toLocaleDateString([], { weekday: "short", hour: "numeric", minute: "2-digit" }),
      area: d.areaLabel,
      interest: d.interest,
      x: 20 + ((index * 30) % 60),
      y: 25 + ((index * 25) % 55),
      latitude: d.latitude,
      longitude: d.longitude,
      description: d.description,
    }));
  },

  async listGames(): Promise<GameSession[]> {
    return request<GameSession[]>("/games");
  },
};
