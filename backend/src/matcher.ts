export interface CompatibilityBreakdown {
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

export const DAILY_QUIZ_QUESTIONS = [
  {
    id: "q_coffee_or_walk",
    category: "lifestyle",
    question: "Ideal first date vibe?",
    options: [
      { label: "Quiet coffee & bookstore wander", tag: "cozy" },
      { label: "Sunset walk through a heritage garden", tag: "outdoors" },
      { label: "Trying an indie dessert spot", tag: "foodie" },
      { label: "Visiting a contemporary art gallery", tag: "creative" },
    ],
  },
  {
    id: "q_weekend_pace",
    category: "adventure",
    question: "How do your favorite Saturdays usually unfold?",
    options: [
      { label: "Spontaneous city exploration without a map", tag: "spontaneous" },
      { label: "Slow morning reading, lively evening meetup", tag: "balanced" },
      { label: "Active morning trek or sports, relaxing evening", tag: "active" },
      { label: "Creating art, cooking, or making music at home", tag: "creative" },
    ],
  },
  {
    id: "q_chat_style",
    category: "communication",
    question: "What is your conversation love language?",
    options: [
      { label: "Deep midnight voice notes & audio calls", tag: "audio" },
      { label: "Witty banter & playful text banter", tag: "playful" },
      { label: "Sharing songs, articles & photo snaps", tag: "multimedia" },
      { label: "Brief texting to plan in-person hangouts", tag: "in_person" },
    ],
  },
  {
    id: "q_spark_trigger",
    category: "romance",
    question: "What creates an instant spark for you?",
    options: [
      { label: "Someone passionate about their craft", tag: "passion" },
      { label: "Kindness to strangers & gentle humor", tag: "empathy" },
      { label: "A shared quirky sense of humor & memes", tag: "humor" },
      { label: "Curiosity to learn new things together", tag: "curiosity" },
    ],
  },
  {
    id: "q_travel_style",
    category: "lifestyle",
    question: "When traveling to a new city, what is your first stop?",
    options: [
      { label: "A tucked-away neighborhood café", tag: "cozy" },
      { label: "The local flea market or craft bazaar", tag: "creative" },
      { label: "A scenic overlook or historic ruin", tag: "outdoors" },
      { label: "The most famous local street food lane", tag: "foodie" },
    ],
  },
];

export function calculateCompatibility(
  userA: { interests: string[]; age?: number; answers?: Record<string, string> },
  userB: { interests: string[]; age?: number; answers?: Record<string, string> },
): CompatibilityBreakdown {
  const setA = new Set(userA.interests.map((i) => i.toLowerCase().trim()));
  const setB = new Set(userB.interests.map((i) => i.toLowerCase().trim()));
  const intersection = [...setA].filter((item) => setB.has(item));
  const union = new Set([...setA, ...setB]);
  const jaccard = union.size === 0 ? 0.5 : intersection.length / union.size;

  const interestsScore = Math.round(jaccard * 100);

  let quizMatchCount = 0;
  let totalQuizCompared = 0;
  if (userA.answers && userB.answers) {
    for (const [qId, ansA] of Object.entries(userA.answers)) {
      if (userB.answers[qId]) {
        totalQuizCompared += 1;
        if (userB.answers[qId] === ansA) quizMatchCount += 1;
      }
    }
  }

  const quizAlignment = totalQuizCompared > 0 ? (quizMatchCount / totalQuizCompared) * 100 : 75;
  const communicationScore = Math.min(100, Math.round(60 + (quizAlignment * 0.4)));
  const lifestyleScore = Math.min(100, Math.round((interestsScore * 0.5) + (quizAlignment * 0.5)));
  const adventureScore = Math.min(100, Math.round(55 + (intersection.length * 12)));

  const finalScore = Math.min(
    99,
    Math.max(
      60,
      Math.round(
        interestsScore * 0.35 +
        communicationScore * 0.25 +
        lifestyleScore * 0.25 +
        adventureScore * 0.15
      )
    )
  );

  const sharedInterests = intersection.map(
    (item) => item.charAt(0).toUpperCase() + item.slice(1)
  );

  const factors: string[] = [];
  if (sharedInterests.length > 0) {
    factors.push(`Shared passion for ${sharedInterests.slice(0, 3).join(", ")}`);
  } else {
    factors.push("Complementary interests that spark curiosity");
  }

  if (communicationScore >= 75) {
    factors.push("Harmonious conversational pace & vibe alignment");
  }
  if (lifestyleScore >= 75) {
    factors.push("Matching weekend rhythms & social preferences");
  }
  if (adventureScore >= 70) {
    factors.push("High eagerness for real-world exploration together");
  }

  const icebreakers: string[] = [];
  if (sharedInterests.includes("Cafés") || sharedInterests.includes("Coffee")) {
    icebreakers.push("What’s your go-to café order on a quiet afternoon?");
  }
  if (sharedInterests.includes("Books") || sharedInterests.includes("Art")) {
    icebreakers.push("What was the last book or exhibition that stayed on your mind for days?");
  }
  if (sharedInterests.includes("Outdoors") || sharedInterests.includes("Photography")) {
    icebreakers.push("Found any hidden scenic spots in the city lately?");
  }
  if (icebreakers.length < 3) {
    icebreakers.push("What is your favorite under-the-radar spot to bring friends to?");
    icebreakers.push("If we took a spontaneous 1-hour walk right now, which neighborhood would you pick?");
    icebreakers.push("What’s something you’re currently excited to learn or try?");
  }

  return {
    score: finalScore,
    sharedInterests,
    factors: factors.slice(0, 3),
    icebreakers: icebreakers.slice(0, 3),
    dimensions: {
      interests: interestsScore,
      communication: communicationScore,
      lifestyle: lifestyleScore,
      adventure: adventureScore,
    },
  };
}

