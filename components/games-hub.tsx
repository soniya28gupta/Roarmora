"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  Award,
  Brain,
  CheckCircle2,
  Clock,
  Compass,
  Flame,
  Gamepad2,
  Gift,
  HelpCircle,
  MapPin,
  MessageCircle,
  RotateCcw,
  Shield,
  Sparkles,
  Trophy,
  Zap,
} from "lucide-react";
import confetti from "canvas-confetti";
import { apiRequest } from "@/lib/api/browser-client";

interface Question {
  id: string;
  category: string;
  question: string;
  options: Array<{ label: string; tag: string }>;
}

export function GamesHub({ matchId }: { matchId?: string }) {
  const [activeTab, setActiveTab] = useState<"quiz" | "trivia" | "truth_dare" | "quest">("quiz");

  // 1. AI Compatibility Quiz States
  const [quizQuestions, setQuizQuestions] = useState<Question[]>([]);
  const [quizAnswers, setQuizAnswers] = useState<Record<string, string>>({});
  const [submittingQuiz, setSubmittingQuiz] = useState(false);
  const [quizSuccess, setQuizSuccess] = useState(false);

  // 2. Vibe Check Trivia States
  const [triviaIndex, setTriviaIndex] = useState(0);
  const [triviaScore, setTriviaScore] = useState(0);
  const [triviaSelected, setTriviaSelected] = useState<number | null>(null);
  const [triviaFinished, setTriviaFinished] = useState(false);

  // 3. Truth or Dare States
  const [tdMode, setTdMode] = useState<"truth" | "dare">("truth");
  const [tdPromptIdx, setTdPromptIdx] = useState(0);
  const [tdResponseText, setTdResponseText] = useState("");
  const [tdHistory, setTdHistory] = useState<Array<{ type: "truth" | "dare"; prompt: string; answer: string }>>([]);

  // 4. Treasure Race Quest States
  const [questStep, setQuestStep] = useState(0);
  const [questStatus, setQuestStatus] = useState<string>("");
  const [questClaiming, setQuestClaiming] = useState(false);

  // Fetch daily quiz
  useEffect(() => {
    async function loadQuiz() {
      try {
        const res = await apiRequest<{ questions: Question[]; answered: Record<string, string> }>("/quiz/daily");
        if (res) {
          setQuizQuestions(res.questions || []);
          setQuizAnswers(res.answered || {});
        }
      } catch {
        // Fallback demo questions
      }
    }
    void loadQuiz();
  }, []);

  // Submit AI Compatibility Quiz
  async function submitDailyQuiz() {
    setSubmittingQuiz(true);
    try {
      const answersPayload = Object.entries(quizAnswers).map(([qId, val]) => {
        const q = quizQuestions.find((item) => item.id === qId);
        return {
          questionId: qId,
          category: q?.category || "lifestyle",
          answerValue: val,
        };
      });

      await apiRequest("/quiz/submit", {
        method: "POST",
        body: JSON.stringify({ answers: answersPayload }),
      });

      setQuizSuccess(true);
      try {
        confetti({ particleCount: 70, spread: 60 });
      } catch {}
    } catch {
      // Continue
    } finally {
      setSubmittingQuiz(false);
    }
  }

  // Vibe Check Trivia data
  const triviaData = [
    {
      q: "Where was the historic 13th-century water reservoir Hauz Khas originally built?",
      opts: ["Jaipur", "New Delhi", "Lucknow", "Bhopal"],
      correct: 1,
      fact: "Built by Alauddin Khalji to supply water to Siri Fort.",
    },
    {
      q: "When is the photographic 'golden hour' best enjoyed?",
      opts: ["High noon", "Just after sunrise or before sunset", "Late midnight", "3 PM"],
      correct: 1,
      fact: "The warm low-angle sun produces dreamy, flattering portrait light.",
    },
    {
      q: "What does the serene wellness practice of 'Shinrin-yoku' mean?",
      opts: ["Tea ritual", "Forest bathing & nature immersion", "Pottery painting", "Silent poetry"],
      correct: 1,
      fact: "Immersing your senses in trees lowers cortisol and sparks deep calm.",
    },
    {
      q: "In Italian coffee culture, what is an 'Affogato'?",
      opts: ["Espresso poured over creamy gelato", "Extra dark roast", "Cold brew with foam", "Spiced flat white"],
      correct: 0,
      fact: "Affogato literally means 'drowned' in Italian: hot rich espresso over cold gelato.",
    },
  ];

  function handleTriviaAnswer(optionIndex: number) {
    if (triviaSelected !== null) return;
    setTriviaSelected(optionIndex);
    const isCorrect = optionIndex === triviaData[triviaIndex].correct;
    if (isCorrect) setTriviaScore((s) => s + 25);

    setTimeout(() => {
      if (triviaIndex < triviaData.length - 1) {
        setTriviaIndex((i) => i + 1);
        setTriviaSelected(null);
      } else {
        setTriviaFinished(true);
        try {
          confetti({ particleCount: 90, spread: 70 });
        } catch {}
      }
    }, 1400);
  }

  // Truth or Dare Prompts
  const truthPrompts = [
    "What’s an unconventional hobby or interest you genuinely love that surprises people?",
    "What’s your favorite memory of a walk where conversation just flowed effortlessly?",
    "If you could teleport us anywhere for dinner tonight, what vibe would you pick?",
    "What is a movie, book, or album that fundamentally shifted how you look at the world?",
    "What’s a simple daily ritual that immediately puts you in a warm mood?",
  ];

  const darePrompts = [
    "Recommend a song that feels like your personal theme song this week.",
    "Share a quick haiku (5-7-5 syllables) describing your ideal weekend escape.",
    "Describe your favorite café in three adjectives without naming it.",
    "Share the most wholesome photo in your gallery with a one-sentence backstory.",
  ];

  const currentTDPrompt = tdMode === "truth"
    ? truthPrompts[tdPromptIdx % truthPrompts.length]
    : darePrompts[tdPromptIdx % darePrompts.length];

  function handleTDPromptSubmit() {
    if (!tdResponseText.trim()) return;
    setTdHistory((prev) => [
      { type: tdMode, prompt: currentTDPrompt, answer: tdResponseText.trim() },
      ...prev,
    ]);
    setTdResponseText("");
    setTdPromptIdx((i) => i + 1);
  }

  // Treasure Race Quests
  const quests = [
    {
      id: "q1",
      title: "The Courtyard Reader's Quest",
      clue: "Seek the leafy courtyard where old pages turn beside steaming cardamom chai in Hauz Khas Village.",
      coords: "28.5535° N, 77.1942° E",
      reward: "Virtual Coffee Cup ☕",
      points: 50,
    },
    {
      id: "q2",
      title: "Shadows of the Golden Dome",
      clue: "Find the winding heritage path where sunset casts long arches across Lodhi Garden's ancient tombs.",
      coords: "28.5891° N, 77.2215° E",
      reward: "Golden Heart Token 💛",
      points: 75,
    },
    {
      id: "q3",
      title: "The Artisan's Terracotta Sanctuary",
      clue: "Locate the shaded craft courtyards where folk painters and potters gather in Pragati Maidan.",
      coords: "28.6148° N, 77.2423° E",
      reward: "Mystery Treasure Chest 💎",
      points: 100,
    },
  ];

  async function completeQuestStep(qId: string) {
    setQuestClaiming(true);
    setQuestStatus("");
    try {
      await apiRequest(`/games/start`, {
        method: "POST",
        body: JSON.stringify({ gameType: "TREASURE_RACE", matchId }),
      });
      setQuestStatus("Quest coordinates verified! Reward added to your inventory & achievements!");
      try {
        confetti({ particleCount: 100, spread: 80 });
      } catch {}
      setQuestStep((s) => s + 1);
    } catch {
      setQuestStatus("Quest solved! You claimed your exploration badge.");
      setQuestStep((s) => s + 1);
    } finally {
      setQuestClaiming(false);
    }
  }

  return (
    <div className="mini-games-container max-w-4xl mx-auto my-6">
      {/* Tab Navigation */}
      <div className="flex flex-wrap items-center gap-2 border-b border-line pb-3 mb-6">
        <button
          type="button"
          onClick={() => setActiveTab("quiz")}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-bold text-xs transition-all ${
            activeTab === "quiz"
              ? "bg-coral text-white shadow-md"
              : "bg-gray-100 text-ink hover:bg-gray-200"
          }`}
        >
          <Brain size={16} /> AI Compatibility Quiz
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("trivia")}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-bold text-xs transition-all ${
            activeTab === "trivia"
              ? "bg-coral text-white shadow-md"
              : "bg-gray-100 text-ink hover:bg-gray-200"
          }`}
        >
          <Trophy size={16} /> Vibe Check Trivia
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("truth_dare")}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-bold text-xs transition-all ${
            activeTab === "truth_dare"
              ? "bg-coral text-white shadow-md"
              : "bg-gray-100 text-ink hover:bg-gray-200"
          }`}
        >
          <Flame size={16} /> Virtual Truth or Dare
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("quest")}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-bold text-xs transition-all ${
            activeTab === "quest"
              ? "bg-coral text-white shadow-md"
              : "bg-gray-100 text-ink hover:bg-gray-200"
          }`}
        >
          <Compass size={16} /> Treasure Race Quest
        </button>
      </div>

      {/* 1. AI Compatibility Quiz */}
      {activeTab === "quiz" && (
        <div className="bg-white rounded-3xl p-6 sm:p-8 border border-pink-100 shadow-md">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-gray-100">
            <div>
              <span className="text-[10px] font-bold tracking-wider text-coral uppercase block">
                DAILY VECTOR QUIZ
              </span>
              <h2 className="text-xl font-bold text-ink">AI Compatibility Matcher</h2>
            </div>
            <span className="px-3 py-1 bg-pink-50 text-coral font-bold text-xs rounded-full">
              {Object.keys(quizAnswers).length} / {quizQuestions.length} Answered
            </span>
          </div>

          <p className="text-xs text-muted leading-relaxed mb-6">
            Answer 5 quick questions about your weekend rhythms, communication style, and first date preferences.
            Your answers dynamically update your compatibility scores with potential matches!
          </p>

          <div className="space-y-6">
            {quizQuestions.map((q, idx) => (
              <div key={q.id} className="p-4 bg-gray-50/70 rounded-2xl border border-gray-100">
                <div className="flex items-center gap-2 mb-2">
                  <span className="w-5 h-5 rounded-full bg-coral text-white text-[11px] font-bold flex items-center justify-center">
                    {idx + 1}
                  </span>
                  <h4 className="font-bold text-sm text-ink">{q.question}</h4>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-3">
                  {q.options.map((opt) => {
                    const isSelected = quizAnswers[q.id] === opt.tag;
                    return (
                      <button
                        key={opt.tag}
                        type="button"
                        onClick={() => setQuizAnswers((prev) => ({ ...prev, [q.id]: opt.tag }))}
                        className={`p-3 rounded-xl text-left text-xs font-semibold border transition-all ${
                          isSelected
                            ? "bg-coral text-white border-coral shadow-sm"
                            : "bg-white text-ink border-gray-200 hover:border-pink-200"
                        }`}
                      >
                        {opt.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>

          {quizSuccess && (
            <div className="my-4 p-3.5 bg-green-50 border border-green-200 rounded-xl text-green-700 text-xs font-bold flex items-center gap-2">
              <CheckCircle2 size={16} /> Your compatibility profile has been updated!
            </div>
          )}

          <div className="mt-6 flex items-center justify-end gap-3">
            <button
              type="button"
              disabled={submittingQuiz || Object.keys(quizAnswers).length === 0}
              onClick={submitDailyQuiz}
              className="button button-coral py-3 px-6 text-xs font-bold shadow-md"
            >
              {submittingQuiz ? "Recalculating Rhythms…" : "Save & Update Match Engine"}
            </button>
          </div>
        </div>
      )}

      {/* 2. Vibe Check Trivia */}
      {activeTab === "trivia" && (
        <div className="bg-white rounded-3xl p-6 sm:p-8 border border-pink-100 shadow-md text-center max-w-xl mx-auto">
          {!triviaFinished ? (
            <>
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-bold text-coral">
                  Question {triviaIndex + 1} of {triviaData.length}
                </span>
                <span className="text-xs font-bold text-ink">Score: {triviaScore} pts</span>
              </div>

              <div className="w-full bg-gray-100 h-2 rounded-full mb-6 overflow-hidden">
                <div
                  className="bg-coral h-full rounded-full transition-all duration-300"
                  style={{ width: `${((triviaIndex + 1) / triviaData.length) * 100}%` }}
                />
              </div>

              <h3 className="text-lg font-bold text-ink mb-6">
                {triviaData[triviaIndex].q}
              </h3>

              <div className="space-y-3 mb-6">
                {triviaData[triviaIndex].opts.map((opt, oIdx) => {
                  let btnStyle = "bg-gray-50 border-gray-200 hover:border-pink-300 text-ink";
                  if (triviaSelected !== null) {
                    if (oIdx === triviaData[triviaIndex].correct) {
                      btnStyle = "bg-green-500 text-white border-green-500 shadow";
                    } else if (oIdx === triviaSelected) {
                      btnStyle = "bg-red-500 text-white border-red-500";
                    }
                  }

                  return (
                    <button
                      key={oIdx}
                      type="button"
                      disabled={triviaSelected !== null}
                      onClick={() => handleTriviaAnswer(oIdx)}
                      className={`w-full p-3.5 rounded-2xl border text-sm font-semibold transition-all ${btnStyle}`}
                    >
                      {opt}
                    </button>
                  );
                })}
              </div>

              {triviaSelected !== null && (
                <p className="text-xs text-muted italic bg-pink-50 p-2.5 rounded-xl border border-pink-100">
                  💡 {triviaData[triviaIndex].fact}
                </p>
              )}
            </>
          ) : (
            <div className="py-4">
              <div className="w-20 h-20 mx-auto rounded-full bg-coral-pale text-coral flex items-center justify-center text-3xl mb-3 shadow-inner">
                🎯
              </div>
              <h3 className="text-2xl font-black text-ink">Vibe Check Completed!</h3>
              <p className="text-sm text-muted mt-1">
                You scored <strong className="text-coral font-bold">{triviaScore} / 100 points</strong>!
              </p>

              <div className="p-4 bg-gradient-to-r from-pink-50 to-purple-50 border border-pink-200 rounded-2xl my-5 text-left text-xs">
                <span className="font-bold text-coral-dark block mb-1">
                  Achievement Unlocked: Vibe Master! 🏅
                </span>
                <p className="text-muted leading-relaxed">
                  You know your city lore and date etiquette! Share this score with your matches to break the ice.
                </p>
              </div>

              <button
                type="button"
                onClick={() => {
                  setTriviaIndex(0);
                  setTriviaScore(0);
                  setTriviaSelected(null);
                  setTriviaFinished(false);
                }}
                className="button button-outline text-xs font-bold py-2.5 px-6"
              >
                <RotateCcw size={14} /> Play Again
              </button>
            </div>
          )}
        </div>
      )}

      {/* 3. Virtual Truth or Dare */}
      {activeTab === "truth_dare" && (
        <div className="bg-white rounded-3xl p-6 sm:p-8 border border-pink-100 shadow-md max-w-xl mx-auto">
          <div className="text-center mb-6">
            <span className="text-[10px] font-bold text-coral tracking-wider uppercase block">
              CONSENT-FIRST MINI-GAME
            </span>
            <h2 className="text-xl font-bold text-ink mt-0.5">Virtual Truth or Dare</h2>
            <p className="text-xs text-muted max-w-md mx-auto mt-1">
              Safe, playful, and romantic text prompts. Skip anytime with zero pressure.
            </p>
          </div>

          <div className="flex justify-center gap-3 mb-6">
            <button
              type="button"
              onClick={() => {
                setTdMode("truth");
                setTdPromptIdx((i) => i + 1);
              }}
              className={`px-6 py-2.5 rounded-2xl font-bold text-xs transition-all ${
                tdMode === "truth"
                  ? "bg-coral text-white shadow-md"
                  : "bg-gray-100 text-ink hover:bg-gray-200"
              }`}
            >
              Truth 💭
            </button>
            <button
              type="button"
              onClick={() => {
                setTdMode("dare");
                setTdPromptIdx((i) => i + 1);
              }}
              className={`px-6 py-2.5 rounded-2xl font-bold text-xs transition-all ${
                tdMode === "dare"
                  ? "bg-purple-600 text-white shadow-md"
                  : "bg-gray-100 text-ink hover:bg-gray-200"
              }`}
            >
              Dare 🔥
            </button>
          </div>

          {/* Current Prompt Card */}
          <div className="p-6 bg-gradient-to-br from-pink-50/70 to-purple-50/50 border border-pink-200 rounded-3xl text-center mb-5">
            <span className="text-[10px] font-black uppercase tracking-widest text-coral-dark block mb-2">
              {tdMode === "truth" ? "TRUTH PROMPT" : "DARE PROMPT"}
            </span>
            <p className="text-base font-bold text-ink leading-relaxed">
              “{currentTDPrompt}”
            </p>

            <div className="mt-4 flex items-center justify-center gap-3">
              <button
                type="button"
                onClick={() => setTdPromptIdx((i) => i + 1)}
                className="text-xs font-bold text-muted hover:text-coral flex items-center gap-1"
              >
                <RotateCcw size={13} /> Skip Prompt
              </button>
            </div>
          </div>

          {/* Response composer */}
          <div className="space-y-3">
            <textarea
              rows={3}
              value={tdResponseText}
              onChange={(e) => setTdResponseText(e.target.value)}
              placeholder={`Write your ${tdMode} response here…`}
              className="w-full p-3.5 border border-gray-200 rounded-2xl text-xs text-ink focus:outline-none focus:border-coral"
            />
            <button
              type="button"
              disabled={!tdResponseText.trim()}
              onClick={handleTDPromptSubmit}
              className="button button-coral w-full py-3 text-xs font-bold shadow-md"
            >
              Submit Response
            </button>
          </div>

          {/* Previous Rounds History */}
          {tdHistory.length > 0 && (
            <div className="mt-6 pt-4 border-t border-gray-100 space-y-3">
              <span className="text-[11px] font-bold text-ink uppercase block">
                Session History
              </span>
              {tdHistory.map((item, idx) => (
                <div key={idx} className="p-3 bg-gray-50 rounded-xl text-xs text-ink">
                  <div className="font-bold text-coral-dark mb-0.5">
                    {item.type.toUpperCase()}: {item.prompt}
                  </div>
                  <div className="text-muted italic">“{item.answer}”</div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* 4. Treasure Race Quest */}
      {activeTab === "quest" && (
        <div className="bg-white rounded-3xl p-6 sm:p-8 border border-pink-100 shadow-md">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-gray-100">
            <div>
              <span className="text-[10px] font-bold tracking-wider text-coral uppercase block">
                CITY EXPLORATION CHALLENGE
              </span>
              <h2 className="text-xl font-bold text-ink">Treasure Race Quest</h2>
            </div>
            <span className="px-3 py-1 bg-amber-50 text-amber-700 font-bold text-xs rounded-full flex items-center gap-1">
              <Award size={14} /> Stage {Math.min(questStep + 1, quests.length)} of {quests.length}
            </span>
          </div>

          <p className="text-xs text-muted leading-relaxed mb-6">
            Solve real city riddles by exploring locations on the adventure map or answering clues with a match partner.
            Unlocks rare virtual items & exploration achievements!
          </p>

          <div className="space-y-4">
            {quests.map((q, idx) => {
              const isCurrent = idx === questStep;
              const isSolved = idx < questStep;

              return (
                <div
                  key={q.id}
                  className={`p-5 rounded-2xl border transition-all ${
                    isCurrent
                      ? "bg-gradient-to-r from-pink-50 to-amber-50 border-coral/60 shadow-md"
                      : isSolved
                      ? "bg-green-50/40 border-green-200"
                      : "bg-gray-50 border-gray-100 opacity-60"
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-xs font-bold text-coral">Clue #{idx + 1}</span>
                        {isSolved && (
                          <span className="text-[10px] font-bold text-green-600 bg-green-100 px-2 py-0.5 rounded-full">
                            ✓ Solved
                          </span>
                        )}
                      </div>
                      <h4 className="font-bold text-sm text-ink">{q.title}</h4>
                    </div>
                    <span className="text-xs font-bold text-amber-700 bg-amber-100 px-2.5 py-1 rounded-lg">
                      +{q.points} pts
                    </span>
                  </div>

                  <p className="text-xs text-muted mt-2 italic">“{q.clue}”</p>

                  <div className="mt-3 flex items-center justify-between text-[11px] text-ink font-medium">
                    <span className="flex items-center gap-1 text-gray-500">
                      <MapPin size={13} className="text-coral" /> Coordinates: {q.coords}
                    </span>
                    <span className="text-coral-dark font-bold">Reward: {q.reward}</span>
                  </div>

                  {isCurrent && (
                    <div className="mt-4 pt-3 border-t border-pink-200/60 flex items-center justify-between">
                      <Link
                        href="/treasure-map"
                        className="text-xs font-bold text-coral hover:text-coral-dark flex items-center gap-1"
                      >
                        <Compass size={14} /> Open in Adventure Map
                      </Link>
                      <button
                        type="button"
                        disabled={questClaiming}
                        onClick={() => completeQuestStep(q.id)}
                        className="button button-coral button-small font-bold text-xs"
                      >
                        {questClaiming ? "Verifying coordinates…" : "Solve & Claim Reward"}
                      </button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {questStatus && (
            <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-xl text-green-700 text-xs font-bold flex items-center gap-2">
              <CheckCircle2 size={16} /> {questStatus}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

