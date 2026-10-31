import "dotenv/config";
import { randomBytes } from "node:crypto";
import bcrypt from "bcryptjs";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const fictionalUsers = [
    {
      email: "mira@example.invalid",
      displayName: "Mira Sharma",
      city: "New Delhi",
      bio: "Coffee enthusiast, architecture admirer, and weekend explorer. Looking for someone who enjoys gallery walks and spontaneous chai stops.",
      interests: ["Cafés", "Outdoors", "Art", "Books"],
      birthDate: "1998-06-15",
      gender: "Female",
      lookingFor: "Everyone",
      imageUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&h=600&fit=crop&crop=faces",
      photos: [
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&h=600&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&h=600&fit=crop",
      ],
    },
    {
      email: "aarav@example.invalid",
      displayName: "Aarav Kapoor",
      city: "New Delhi",
      bio: "Street photographer and soundtrack collector. Always hunting for golden hour spots, quiet book nooks, and vintage vinyls.",
      interests: ["Photography", "Live music", "Cafés", "Books"],
      birthDate: "1996-11-02",
      gender: "Male",
      lookingFor: "Everyone",
      imageUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&h=600&fit=crop&crop=faces",
      photos: [
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&h=600&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600&h=600&fit=crop",
      ],
    },
    {
      email: "naina@example.invalid",
      displayName: "Naina Roy",
      city: "New Delhi",
      bio: "Illustrator and park wanderer. Watercolor sketchbook always in bag. If you know a café with great lemon tarts, we are already friends.",
      interests: ["Art", "Books", "Outdoors", "Food"],
      birthDate: "1999-02-20",
      gender: "Female",
      lookingFor: "Everyone",
      imageUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&h=600&fit=crop&crop=faces",
      photos: [
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&h=600&fit=crop&crop=faces",
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&h=600&fit=crop",
      ],
    },
    {
      email: "kabir@example.invalid",
      displayName: "Kabir Mehta",
      city: "New Delhi",
      bio: "Indie game designer & rock climbing fan. Love deep trivia nights, starlit terrace talks, and exploring hidden city corners.",
      interests: ["Outdoors", "Live music", "Food", "Art"],
      birthDate: "1997-08-14",
      gender: "Non-binary",
      lookingFor: "Everyone",
      imageUrl: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600&h=600&fit=crop&crop=faces",
      photos: [
        "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600&h=600&fit=crop&crop=faces",
      ],
    },
  ];

  for (const [index, person] of fictionalUsers.entries()) {
    const user = await prisma.user.upsert({
      where: { email: person.email },
      update: {
        profile: {
          update: {
            displayName: person.displayName,
            city: person.city,
            bio: person.bio,
            interests: person.interests,
            imageUrl: person.imageUrl,
            photos: person.photos,
            gender: person.gender,
            lookingFor: person.lookingFor,
          },
        },
      },
      create: {
        email: person.email,
        passwordHash: await bcrypt.hash(randomBytes(32).toString("base64url"), 12),
        birthDate: new Date(`${person.birthDate}T00:00:00.000Z`),
        profile: {
          create: {
            displayName: person.displayName,
            city: person.city,
            bio: person.bio,
            interests: person.interests,
            imageUrl: person.imageUrl,
            photos: person.photos,
            gender: person.gender,
            lookingFor: person.lookingFor,
          },
        },
        preferences: {
          create: {
            interests: person.interests,
            locationConsent: true,
            minAge: 18,
            maxAge: 40,
            maxDistanceKm: 50,
          },
        },
      },
    });

    await prisma.drop.upsert({
      where: { id: `00000000-0000-4000-8000-00000000000${index + 1}` },
      update: {},
      create: {
        id: `00000000-0000-4000-8000-00000000000${index + 1}`,
        hostId: user.id,
        title: ["Chai & book swap", "Golden-hour photo walk", "Sunday sketch walk", "Rooftop acoustic jam"][index]!,
        description: "Community-shared exploration drop in Pookie Match.",
        interest: person.interests[0]!,
        startsAt: new Date(Date.now() + (index + 1) * 24 * 60 * 60 * 1000),
        areaLabel: ["Hauz Khas Village", "Lodhi Garden", "Safdarjung Tomb", "Champa Gali"][index]!,
        latitude: 28.553 + index * 0.015,
        longitude: 77.194 + index * 0.015,
        locationConsent: true,
      },
    });
  }

  const collectibles = [
    {
      name: "Virtual Coffee Cup",
      slug: "coffee-cup",
      description: "A warm, steaming ceramic cup of artisan cappuccino. Perfect as a casual meetup invitation.",
      icon: "☕",
      rarity: "COMMON",
      category: "SOCIAL",
      perkDescription: "Unlocks the 'Coffee Date' icebreaker prompt in chat.",
      latitude: 28.5535,
      longitude: 77.1942,
    },
    {
      name: "Golden Heart",
      slug: "golden-heart",
      description: "A radiant enchanted golden heart crafted for truly special sparks. Expresses high romantic interest.",
      icon: "💛",
      rarity: "EPIC",
      category: "ROMANCE",
      perkDescription: "Sends an animated golden match celebration to your partner.",
      latitude: 28.5891,
      longitude: 77.2215,
    },
    {
      name: "Music Note Badge",
      slug: "music-badge",
      description: "A shimmering treble clef badge awarded for musical synchronicity and festival adventures.",
      icon: "🎵",
      rarity: "RARE",
      category: "SOCIAL",
      perkDescription: "Unlocks shared Spotify playlist sharing in your chats.",
      latitude: 28.5602,
      longitude: 77.2081,
    },
    {
      name: "Treasure Chest",
      slug: "treasure-chest",
      description: "An antique wooden chest with brass accents containing mystery rewards and rare avatar frames.",
      icon: "💎",
      rarity: "LEGENDARY",
      category: "MYSTERY",
      perkDescription: "Unlocks exclusive profile glow effects and premium badge.",
      latitude: 28.5192,
      longitude: 77.1983,
    },
    {
      name: "Adventure Compass",
      slug: "adventure-compass",
      description: "An ornate vintage brass compass that points toward fellow wanderers and secret city drops.",
      icon: "🧭",
      rarity: "RARE",
      category: "EXPLORATION",
      perkDescription: "Increases exploration radar discovery radius by 25%.",
      latitude: 28.5487,
      longitude: 77.2144,
    },
    {
      name: "Lucky Star",
      slug: "lucky-star",
      description: "A playful twinkling star token that breaks the ice with witty conversation starters.",
      icon: "⭐",
      rarity: "COMMON",
      category: "SOCIAL",
      perkDescription: "Generates 3 instant personalized AI conversation starters.",
      latitude: 28.5721,
      longitude: 77.2105,
    },
  ];

  for (const item of collectibles) {
    await prisma.collectibleItem.upsert({
      where: { slug: item.slug },
      update: item,
      create: item,
    });
  }

  const achievements = [
    {
      title: "Trailblazer",
      slug: "trailblazer",
      description: "Explored 3 different spots on the Pookie Match adventure map.",
      icon: "🗺️",
      badgeColor: "#FF5864",
      category: "EXPLORATION",
      points: 20,
    },
    {
      title: "Cupid's Arrow",
      slug: "cupids-arrow",
      description: "Created your first mutual match on Pookie Match.",
      icon: "🏹",
      badgeColor: "#FD3A73",
      category: "ROMANCE",
      points: 25,
    },
    {
      title: "Vibe Master",
      slug: "vibe-master",
      description: "Completed a Vibe Check Trivia game with a mutual match.",
      icon: "🎯",
      badgeColor: "#8B5CF6",
      category: "GAMES",
      points: 15,
    },
    {
      title: "Treasure Hunter",
      slug: "treasure-hunter",
      description: "Collected your first virtual collectible on the map.",
      icon: "🏆",
      badgeColor: "#F59E0B",
      category: "EXPLORATION",
      points: 30,
    },
    {
      title: "Truth Seeker",
      slug: "truth-seeker",
      description: "Completed 5 rounds of Virtual Truth or Dare.",
      icon: "🎭",
      badgeColor: "#10B981",
      category: "GAMES",
      points: 20,
    },
    {
      title: "Real Connection",
      slug: "real-connection",
      description: "Connected on a live video or audio call.",
      icon: "📹",
      badgeColor: "#06B6D4",
      category: "COMMUNICATION",
      points: 40,
    },
  ];

  for (const ach of achievements) {
    await prisma.achievement.upsert({
      where: { slug: ach.slug },
      update: ach,
      create: ach,
    });
  }

  const places = [
    { name: "The Reading Room Café", category: "Café · Books", neighborhood: "Hauz Khas Village", description: "Quiet tables, a leafy courtyard, and one more chapter.", latitude: 28.5535, longitude: 77.1942 },
    { name: "Lodhi Garden Heritage Walk", category: "Outdoors", neighborhood: "Lodhi Road", description: "Garden paths made for a slow Sunday and a longer walk.", latitude: 28.5891, longitude: 77.2215 },
    { name: "Champa Gali Courtyard", category: "Cafés · Shops", neighborhood: "Saidulajab", description: "Independent little shops and a coffee worth lingering over.", latitude: 28.5192, longitude: 77.1983 },
    { name: "National Crafts Museum & Café Lota", category: "Culture", neighborhood: "Pragati Maidan", description: "A thoughtful gallery wander, then tea in the courtyard.", latitude: 28.6148, longitude: 77.2423 },
    { name: "Safdarjung Tomb Sunset View", category: "Outdoors", neighborhood: "Safdarjung", description: "Magnificent Mughal architecture surrounded by quiet palms.", latitude: 28.5893, longitude: 77.2106 },
  ];
  for (const place of places) {
    await prisma.place.upsert({
      where: { id: `00000000-0000-4000-9000-${String(places.indexOf(place) + 1).padStart(12, "0")}` },
      update: place,
      create: {
        id: `00000000-0000-4000-9000-${String(places.indexOf(place) + 1).padStart(12, "0")}`,
        ...place,
        fictional: false,
      },
    });
  }
}

main()
  .then(() => console.log("Seeded Pookie Match profiles, collectibles, achievements, drops, and places!"))
  .catch((err) => {
    console.error("Seed error:", err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
