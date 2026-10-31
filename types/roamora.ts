export interface CompatibilityData {
  score: number;
  sharedInterests: string[];
  factors: string[];
  icebreakers: string[];
  dimensions: {
    interests: number;
    communication: number;
    lifestyle: number;
    adventure: number;
  };
}

export interface Profile {
  id: string;
  name: string;
  age: number;
  city: string;
  bio: string;
  interests: string[];
  image?: string | null;
  photos?: string[];
  gender?: string;
  lookingFor?: string;
  compatibility?: CompatibilityData;
  distanceLabel?: string;
}

export interface Place {
  id: string;
  name: string;
  category: string;
  neighborhood: string;
  description: string;
  distance: string;
  image: string;
  tag: string;
  latitude?: number;
  longitude?: number;
}

export interface Drop {
  id: string;
  title: string;
  host: string;
  startsAt: string;
  area: string;
  interest: string;
  x: number;
  y: number;
  latitude?: number;
  longitude?: number;
  description?: string;
  collected?: boolean;
}

export interface Match {
  id: string;
  otherUserId: string;
  name: string;
  age: number;
  city: string;
  bio: string;
  interests: string[];
  image?: string | null;
  photos?: string[];
  lastMessage?: {
    text: string;
    time: string;
    fromMe: boolean;
  } | null;
  compatibility?: CompatibilityData;
}

export interface ChatMessage {
  id: string;
  from: "other" | "you";
  text: string;
  time: string;
}

export interface CollectibleItem {
  id: string;
  name: string;
  slug: string;
  description: string;
  icon: string;
  rarity: "COMMON" | "RARE" | "EPIC" | "LEGENDARY";
  category: string;
  perkDescription?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  active?: boolean;
}

export interface UserInventoryItem {
  id: string;
  userId: string;
  itemId: string;
  quantity: number;
  acquiredAt: string;
  item: CollectibleItem;
}

export interface Achievement {
  id: string;
  title: string;
  slug: string;
  description: string;
  icon: string;
  badgeColor: string;
  category: string;
  points: number;
  unlocked?: boolean;
  unlockedAt?: string | null;
}

export interface AppNotification {
  id: string;
  userId: string;
  type: string;
  title: string;
  message: string;
  link?: string | null;
  read: boolean;
  createdAt: string;
}

export interface CallSession {
  id: string;
  callerId: string;
  calleeId: string;
  matchId: string;
  callType: "AUDIO" | "VIDEO";
  status: "CALLING" | "ACCEPTED" | "DECLINED" | "ENDED" | "MISSED";
  offer?: any;
  answer?: any;
  candidates?: any[];
  startedAt?: string | null;
  endedAt?: string | null;
  caller?: {
    profile?: {
      displayName: string;
      imageUrl?: string | null;
    } | null;
  };
  callee?: {
    profile?: {
      displayName: string;
      imageUrl?: string | null;
    } | null;
  };
}

export interface GameParticipant {
  id: string;
  sessionId: string;
  userId: string;
  score: number;
  completed: boolean;
  answers?: any;
  user?: {
    profile?: {
      displayName: string;
      imageUrl?: string | null;
    } | null;
  };
}

export interface GameSession {
  id: string;
  gameType: "COMPATIBILITY_QUIZ" | "VIBE_CHECK" | "TRUTH_OR_DARE" | "TREASURE_RACE";
  hostId: string;
  matchId?: string | null;
  status: "ACTIVE" | "COMPLETED" | "EXPIRED";
  state?: any;
  createdAt: string;
  updatedAt: string;
  participants: GameParticipant[];
}

export interface AccountProfile {
  id: string;
  email: string;
  birthDate: string;
  displayName: string;
  city: string;
  bio: string;
  interests: string[];
  imageUrl: string | null;
  photos?: string[];
  gender?: string | null;
  lookingFor?: string | null;
  discoverable: boolean;
  locationConsent: boolean;
  globalExploreMode?: boolean;
  discoveryRadiusMeters?: number;
  stats?: {
    itemsCount: number;
    achievementsCount: number;
    matchesCount: number;
    unreadNotifications: number;
  };
}

export interface DemoUser {
  name: string;
  city: string;
  interests: string[];
  image: string;
}

export type PreviewDataState = "data" | "loading" | "empty" | "error";
