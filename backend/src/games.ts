export interface TriviaQuestion {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
}

export const VIBE_TRIVIA_QUESTIONS: TriviaQuestion[] = [
  {
    id: "trivia_1",
    question: "Which city is famously home to the historic Hauz Khas complex and water tank built in the 13th century?",
    options: ["Jaipur", "New Delhi", "Lucknow", "Bhopal"],
    correctIndex: 1,
    explanation: "Hauz Khas was originally built by Alauddin Khalji in New Delhi to supply water to Siri Fort.",
  },
  {
    id: "trivia_2",
    question: "If your date says they want a 'golden hour' photoshoot, when should you meet?",
    options: ["Right at noon", "Shortly after sunrise or before sunset", "At midnight under streetlights", "At 3 PM"],
    correctIndex: 1,
    explanation: "Golden hour is the magical hour right before sunset or after sunrise with warm diffused light.",
  },
  {
    id: "trivia_3",
    question: "What does the Japanese concept of 'Shinrin-yoku' mean?",
    options: ["Tea ceremony", "Forest bathing & nature immersion", "Pottery making", "Silent poetry"],
    correctIndex: 1,
    explanation: "Shinrin-yoku means taking in the forest atmosphere, or forest bathing for wellness.",
  },
  {
    id: "trivia_4",
    question: "Which musical instrument has 88 keys and spans over 7 octaves?",
    options: ["Harpsichord", "Acoustic Piano", "Accordion", "Pipe Organ"],
    correctIndex: 1,
    explanation: "A standard piano features 52 white keys and 36 black keys totaling 88 keys.",
  },
  {
    id: "trivia_5",
    question: "In coffee culture, what is an 'Affogato'?",
    options: ["Espresso poured over gelato", "Extra frothy dark roast", "Iced coffee with cinnamon", "Filtered pour-over"],
    correctIndex: 0,
    explanation: "Affogato translates to 'drowned' in Italian: a hot shot of espresso poured over cold vanilla gelato.",
  },
];

export const TRUTH_OR_DARE_PROMPTS = {
  truths: [
    "What’s an unconventional hobby or interest you genuinely love that surprises people?",
    "What’s your favorite memory of a walk where conversation just flowed effortlessly?",
    "If you could teleport us anywhere for dinner tonight, what vibe would you pick?",
    "What is a movie, book, or album that fundamentally shifted how you look at the world?",
    "What’s the most thoughtful little gesture someone has done for you recently?",
    "What is a simple daily ritual that immediately puts you in a good mood?",
    "If you could instantly become a master at any creative skill, what would you choose?",
  ],
  dares: [
    "Text me a photo of your current view right now or a favorite photo from your camera roll.",
    "Recommend a song that feels like your personal theme song this week.",
    "Share a haiku (5-7-5 syllables) describing your ideal weekend.",
    "Describe your favorite café in three adjectives without naming it.",
    "Share the most wholesome photo in your gallery with a one-sentence backstory.",
    "Voice note a 10-second clip singing or humming a tune you can't get out of your head.",
  ],
};

export const TREASURE_RACE_QUESTS = [
  {
    id: "quest_hk_courtyard",
    title: "The Scholar's Secret Garden",
    clue: "Seek the courtyard where old pages turn beside steaming chai. Near Hauz Khas Village's vintage book café.",
    targetCoords: { latitude: 28.5535, longitude: 77.1942 },
    rewardSlug: "coffee-cup",
    rewardPoints: 50,
  },
  {
    id: "quest_lodhi_sunset",
    title: "Shadows of the Sunset Tomb",
    clue: "Wander along the domed path where birds gather at golden hour among ancient stone canopies.",
    targetCoords: { latitude: 28.5891, longitude: 77.2215 },
    rewardSlug: "golden-heart",
    rewardPoints: 75,
  },
  {
    id: "quest_art_bazaar",
    title: "The Weaver's Riddle",
    clue: "Find the terracotta sanctuary where artisans carve wooden blocks and clay lamps in Pragati Maidan.",
    targetCoords: { latitude: 28.6148, longitude: 77.2423 },
    rewardSlug: "treasure-chest",
    rewardPoints: 100,
  },
];

