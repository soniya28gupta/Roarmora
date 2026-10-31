import { describe, expect, it } from "vitest";
import { calculateCompatibility } from "../src/matcher.js";

describe("AI Compatibility Matcher", () => {
  it("computes high compatibility score for users with shared interests and aligned quiz answers", () => {
    const userA = {
      interests: ["Cafés", "Books", "Art", "Outdoors"],
      age: 26,
      answers: {
        q_coffee_or_walk: "cozy",
        q_chat_style: "playful",
        q_spark_trigger: "passion",
      },
    };

    const userB = {
      interests: ["Cafés", "Books", "Art", "Live music"],
      age: 25,
      answers: {
        q_coffee_or_walk: "cozy",
        q_chat_style: "playful",
        q_spark_trigger: "passion",
      },
    };

    const result = calculateCompatibility(userA, userB);
    expect(result.score).toBeGreaterThanOrEqual(80);
    expect(result.sharedInterests).toEqual(expect.arrayContaining(["Cafés", "Books", "Art"]));
    expect(result.factors.length).toBeGreaterThan(0);
    expect(result.icebreakers.length).toBeGreaterThan(0);
    expect(result.dimensions.interests).toBeGreaterThan(50);
  });

  it("handles empty or complementary interests gracefully without crashing", () => {
    const result = calculateCompatibility(
      { interests: [] },
      { interests: ["Outdoors"] },
    );
    expect(result.score).toBeGreaterThanOrEqual(60);
    expect(result.factors).toBeDefined();
    expect(result.icebreakers).toHaveLength(3);
  });
});

