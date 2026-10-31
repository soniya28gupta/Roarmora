"use client";

import { useRef, useState } from "react";
import Link from "next/link";
import {
  ArrowLeft,
  ArrowRight,
  ChevronLeft,
  ChevronRight,
  Heart,
  Info,
  MapPin,
  MessageCircle,
  Shield,
  Sparkles,
  X,
  Zap,
} from "lucide-react";
import confetti from "canvas-confetti";
import { apiRequest } from "@/lib/api/browser-client";
import type { Profile } from "@/types/roamora";

interface SwipeResult {
  matched: boolean;
  matchId?: string;
  celebration?: {
    title: string;
    message: string;
  };
}

export function SwipeDeck({ people }: { people: Profile[] }) {
  const [index, setIndex] = useState(0);
  const [currentPhotoIdx, setCurrentPhotoIdx] = useState(0);
  const [feedback, setFeedback] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [matchedModal, setMatchedModal] = useState<{ matchId: string; person: Profile } | null>(null);
  const [showCompModal, setShowCompModal] = useState(false);

  // Drag gesture states
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const dragStart = useRef<{ x: number; y: number } | null>(null);

  const active = people[index];
  const allPhotos = active
    ? (active.photos && active.photos.length > 0
        ? active.photos
        : active.image
        ? [active.image]
        : [])
    : [];

  const currentPhoto = allPhotos[currentPhotoIdx] || active?.image || null;

  async function choose(action: "PASS" | "LIKE") {
    if (!active || submitting) return;
    setSubmitting(true);
    setError("");
    setFeedback("");
    setDragOffset({ x: 0, y: 0 });

    try {
      const result = await apiRequest<SwipeResult>("/swipes", {
        method: "POST",
        body: JSON.stringify({ targetUserId: active.id, direction: action }),
      });

      if (result.matched && result.matchId) {
        // Trigger celebratory confetti
        try {
          confetti({
            particleCount: 120,
            spread: 75,
            origin: { y: 0.6 },
            colors: ["#FF5864", "#FD3A73", "#FFD700", "#FF69B4"],
          });
        } catch {
          // Ignore if confetti not supported
        }
        setMatchedModal({ matchId: result.matchId, person: active });
      } else {
        setFeedback(
          action === "LIKE"
            ? `Your spark was sent to ${active.name}! ✨`
            : `You passed on ${active.name}.`,
        );
        setIndex((current) => current + 1);
        setCurrentPhotoIdx(0);
      }
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Your choice could not be saved.");
    } finally {
      setSubmitting(false);
    }
  }

  function handlePointerDown(e: React.PointerEvent) {
    if (submitting) return;
    dragStart.current = { x: e.clientX, y: e.clientY };
    setIsDragging(true);
  }

  function handlePointerMove(e: React.PointerEvent) {
    if (!isDragging || !dragStart.current) return;
    const dx = e.clientX - dragStart.current.x;
    const dy = e.clientY - dragStart.current.y;
    setDragOffset({ x: dx, y: dy * 0.2 });
  }

  function handlePointerUp() {
    if (!isDragging || !dragStart.current) return;
    setIsDragging(false);
    const threshold = 110;
    if (dragOffset.x > threshold) {
      void choose("LIKE");
    } else if (dragOffset.x < -threshold) {
      void choose("PASS");
    } else {
      setDragOffset({ x: 0, y: 0 });
    }
    dragStart.current = null;
  }

  if (!active) {
    return (
      <div className="state-card state-empty">
        <div className="w-16 h-16 rounded-full bg-coral-pale text-coral flex items-center justify-center mx-auto mb-4">
          <Heart size={32} />
        </div>
        <h2>{people.length ? "You’re all caught up for today! ✨" : "No profiles to show right now"}</h2>
        <p className="max-w-md mx-auto mt-2 text-muted">
          New compatible pookies will appear as more people join or when you expand your discovery radius in preferences.
        </p>
        <div className="mt-6 flex flex-wrap gap-3 justify-center">
          <Link href="/treasure-map" className="button button-coral">
            <Sparkles size={16} /> Explore Adventure Map
          </Link>
          <Link href="/profile" className="button button-outline">
            Adjust Discovery Filters
          </Link>
        </div>
        {feedback && <p className="mt-4 text-xs font-semibold text-coral" aria-live="polite">{feedback}</p>}
      </div>
    );
  }

  const initials = active.name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase();

  const compScore = active.compatibility?.score ?? 85;
  const rotation = dragOffset.x * 0.08;
  const opacity = Math.max(0.7, 1 - Math.abs(dragOffset.x) / 600);

  return (
    <>
      <div className="discovery-layout">
        <section className="swipe-column">
          <div className="deck-count">
            <span>PEOPLE TO DISCOVER</span>
            <span>
              {String(index + 1).padStart(2, "0")}{" "}
              <i>/ {String(people.length).padStart(2, "0")}</i>
            </span>
          </div>

          <article
            className="profile-card relative select-none transition-transform"
            style={{
              transform: `translate3d(${dragOffset.x}px, ${dragOffset.y}px, 0) rotate(${rotation}deg)`,
              opacity,
              cursor: isDragging ? "grabbing" : "grab",
            }}
            onPointerDown={handlePointerDown}
            onPointerMove={handlePointerMove}
            onPointerUp={handlePointerUp}
            onPointerCancel={handlePointerUp}
          >
            {/* Swipe visual feedback stamps */}
            {dragOffset.x > 40 && (
              <div className="absolute top-8 left-8 z-30 px-4 py-2 border-4 border-green-500 text-green-500 font-black text-2xl rounded-xl rotate-[-15deg] uppercase tracking-wider bg-white/80 shadow-lg">
                LIKE 💚
              </div>
            )}
            {dragOffset.x < -40 && (
              <div className="absolute top-8 right-8 z-30 px-4 py-2 border-4 border-red-500 text-red-500 font-black text-2xl rounded-xl rotate-[15deg] uppercase tracking-wider bg-white/80 shadow-lg">
                PASS ✕
              </div>
            )}

            {/* Profile Photo & Carousel */}
            <div
              className="profile-photo relative"
              role="img"
              aria-label={`Profile photo of ${active.name}`}
              style={{
                backgroundImage: currentPhoto
                  ? `linear-gradient(180deg, rgba(23,18,24,0) 45%, rgba(23,18,24,0.85) 100%), url("${currentPhoto}")`
                  : "linear-gradient(180deg, #f3e8e7 25%, #493943 100%)",
              }}
            >
              {!currentPhoto && <span className="profile-initials">{initials}</span>}

              {/* Photo carousel indicators & arrows */}
              {allPhotos.length > 1 && (
                <>
                  <div className="absolute top-3 left-4 right-4 flex gap-1 z-20">
                    {allPhotos.map((_, pIdx) => (
                      <div
                        key={pIdx}
                        className={`h-1 flex-1 rounded-full transition-all ${
                          pIdx === currentPhotoIdx ? "bg-white shadow" : "bg-white/40"
                        }`}
                      />
                    ))}
                  </div>
                  <button
                    type="button"
                    className="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/30 hover:bg-black/60 text-white flex items-center justify-center z-20"
                    onClick={(e) => {
                      e.stopPropagation();
                      setCurrentPhotoIdx((c) => (c > 0 ? c - 1 : allPhotos.length - 1));
                    }}
                    aria-label="Previous photo"
                  >
                    <ChevronLeft size={20} />
                  </button>
                  <button
                    type="button"
                    className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-black/30 hover:bg-black/60 text-white flex items-center justify-center z-20"
                    onClick={(e) => {
                      e.stopPropagation();
                      setCurrentPhotoIdx((c) => (c < allPhotos.length - 1 ? c + 1 : 0));
                    }}
                    aria-label="Next photo"
                  >
                    <ChevronRight size={20} />
                  </button>
                </>
              )}

              {/* Top pill & Back button */}
              <div className="profile-photo-top">
                <span className="illustrative-pill bg-coral text-white font-bold flex items-center gap-1 shadow">
                  <Sparkles size={12} /> POOKIE CANDIDATE
                </span>
                <button
                  aria-label="Previous profile"
                  className="icon-button profile-back"
                  disabled={submitting || index === 0}
                  onClick={(e) => {
                    e.stopPropagation();
                    setIndex((current) => Math.max(0, current - 1));
                  }}
                  type="button"
                >
                  <ArrowLeft size={17} />
                </button>
              </div>

              {/* Caption */}
              <div className="profile-photo-caption">
                <div className="flex items-center justify-between">
                  <h2>
                    {active.name}, {active.age}
                  </h2>
                  {active.gender && (
                    <span className="text-xs bg-white/20 backdrop-blur px-2.5 py-1 rounded-full text-white font-medium">
                      {active.gender}
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-2 mt-1">
                  <span>
                    <MapPin size={14} className="inline mr-1" /> {active.city}
                  </span>
                  {active.distanceLabel && (
                    <span className="text-white/80 text-xs">· {active.distanceLabel}</span>
                  )}
                </div>
              </div>
            </div>

            {/* Profile details */}
            <div className="profile-card-details">
              {/* AI Compatibility Badge */}
              <div className="mb-3 p-3 bg-gradient-to-r from-pink-50 to-rose-50 border border-pink-200/80 rounded-xl flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 rounded-full bg-coral text-white flex items-center justify-center font-bold text-sm shadow">
                    {compScore}%
                  </div>
                  <div>
                    <span className="text-[10px] font-bold text-coral-dark uppercase tracking-wider block">
                      AI Compatibility
                    </span>
                    <span className="text-xs font-semibold text-ink">
                      {active.compatibility?.factors[0] || "Complementary vibe alignment"}
                    </span>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setShowCompModal(true)}
                  className="text-xs font-bold text-coral hover:text-coral-dark flex items-center gap-1 bg-white px-2.5 py-1 rounded-lg border border-pink-200 shadow-sm transition-all"
                >
                  <Info size={14} /> Breakdown
                </button>
              </div>

              <p className="profile-bio">“{active.bio}”</p>

              {/* Interests chips */}
              <div className="interest-list">
                {active.interests.map((interest) => (
                  <span className="interest-chip" key={interest}>
                    {interest}
                  </span>
                ))}
              </div>

              {/* Icebreaker preview */}
              {active.compatibility?.icebreakers && active.compatibility.icebreakers[0] && (
                <div className="mt-3 p-2.5 bg-gray-50 border border-gray-100 rounded-lg text-xs text-muted flex items-start gap-2">
                  <Zap size={15} className="text-amber-500 shrink-0 mt-0.5" />
                  <span>
                    <strong className="text-ink">Icebreaker idea:</strong> {active.compatibility.icebreakers[0]}
                  </span>
                </div>
              )}

              {/* Swipe Action Buttons */}
              <div className="swipe-actions mt-4 flex items-center justify-center gap-6">
                <button
                  aria-label="Pass profile"
                  className="swipe-action pass-action transform hover:scale-110 active:scale-95 transition-all"
                  disabled={submitting}
                  onClick={() => void choose("PASS")}
                  type="button"
                >
                  <X size={24} />
                </button>
                <button
                  aria-label="Send a like"
                  className="swipe-action like-action transform hover:scale-110 active:scale-95 transition-all shadow-lg"
                  disabled={submitting}
                  onClick={() => void choose("LIKE")}
                  type="button"
                >
                  <Heart size={26} fill="currentColor" />
                </button>
              </div>

              <div
                aria-live="polite"
                className={error ? "swipe-feedback error-text" : "swipe-feedback"}
                role={error ? "alert" : "status"}
              >
                {submitting ? "Checking spark chemistry…" : error || feedback || "Drag the card or tap Like to connect."}
              </div>
            </div>
          </article>

          <p className="swipe-hint flex items-center justify-center gap-2 mt-3 text-xs text-muted">
            <ArrowLeft size={14} /> Swipe left to pass · Swipe right to like <ArrowRight size={14} />
          </p>
        </section>

        {/* Sidebar info */}
        <aside className="discover-aside">
          <div className="aside-kicker">
            <Sparkles size={14} className="text-coral" /> POOKIE MATCHING ENGINE
          </div>
          <h2>Explore deeper chemistry with AI Compatibility.</h2>
          <p>
            Pookie Match combines your shared interests, lifestyle quiz rhythms, and location exploration history to rank your most harmonious matches.
          </p>

          <div className="p-4 bg-coral-pale/60 border border-pink-200/60 rounded-xl my-4">
            <h4 className="font-bold text-xs uppercase text-coral-dark mb-1">Adventure Sync</h4>
            <p className="text-xs text-ink/80 leading-relaxed">
              Matched users unlock private live audio/video calling, interactive Vibe Check trivia, and virtual gift gifting!
            </p>
          </div>

          <div className="aside-divider" />
          <div className="privacy-callout">
            <Shield size={16} className="text-coral" />
            <div>
              <strong>Privacy-First Location</strong>
              <p>Your coordinates are never revealed to other users without mutual consent.</p>
            </div>
          </div>
          <div className="aside-count">
            <span>{String(people.length).padStart(2, "0")}</span>
            <div>
              <strong>Profiles curated for you</strong>
              <small>Based on your age & interest filters</small>
            </div>
          </div>
        </aside>
      </div>

      {/* Mutual Match Modal */}
      {matchedModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-300">
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 text-center shadow-2xl border border-pink-100 transform animate-in zoom-in-95 duration-300">
            <div className="w-20 h-20 mx-auto rounded-full bg-gradient-to-tr from-coral to-rose-400 text-white flex items-center justify-center text-3xl shadow-lg mb-4">
              💖
            </div>
            <span className="text-xs font-bold tracking-widest text-coral uppercase block">
              MUTUAL ATTRACTION
            </span>
            <h3 className="text-2xl font-black text-ink mt-1">
              It’s a Pookie Match!
            </h3>
            <p className="text-sm text-muted mt-2">
              You and <strong className="text-ink">{matchedModal.person.name}</strong> both swiped right. The conversation door is unlocked!
            </p>

            <div className="my-5 p-3.5 bg-pink-50/70 border border-pink-200 rounded-xl text-left">
              <span className="text-[11px] font-bold text-coral-dark block mb-1">
                Suggested Icebreaker:
              </span>
              <p className="text-xs text-ink font-medium italic">
                “{matchedModal.person.compatibility?.icebreakers[0] || "Hey, so glad we matched! What kind of coffee or music are you into lately?"}”
              </p>
            </div>

            <div className="flex flex-col gap-2.5">
              <Link
                href={`/chat?matchId=${matchedModal.matchId}`}
                className="button button-coral w-full py-3 text-sm font-bold shadow-md"
              >
                <MessageCircle size={16} /> Say Hello Now
              </Link>
              <button
                type="button"
                onClick={() => {
                  setMatchedModal(null);
                  setIndex((c) => c + 1);
                  setCurrentPhotoIdx(0);
                }}
                className="button button-outline w-full py-2.5 text-xs font-semibold"
              >
                Keep Swiping
              </button>
            </div>
          </div>
        </div>
      )}

      {/* AI Compatibility Breakdown Modal */}
      {showCompModal && active.compatibility && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-pink-100">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <Sparkles size={18} className="text-coral" />
                <h3 className="font-bold text-ink">AI Compatibility Breakdown</h3>
              </div>
              <button
                type="button"
                onClick={() => setShowCompModal(false)}
                className="text-gray-400 hover:text-gray-600 p-1"
              >
                <X size={20} />
              </button>
            </div>

            <div className="my-4 text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-coral-pale text-coral font-black text-2xl border-2 border-pink-200 shadow-inner">
                {active.compatibility.score}%
              </div>
              <h4 className="font-bold text-base mt-2">Overall Chemistry Index</h4>
              <p className="text-xs text-muted max-w-xs mx-auto mt-1">
                Calculated using interest intersections, lifestyle rhythms, and quiz answers.
              </p>
            </div>

            <div className="space-y-3 my-4">
              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span>Interests & Hobbies</span>
                  <span className="text-coral">{active.compatibility.dimensions.interests}%</span>
                </div>
                <div className="w-full bg-gray-100 h-2 rounded-full overflow-hidden">
                  <div
                    className="bg-coral h-full rounded-full transition-all duration-500"
                    style={{ width: `${active.compatibility.dimensions.interests}%` }}
                  />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span>Communication Style</span>
                  <span className="text-coral">{active.compatibility.dimensions.communication}%</span>
                </div>
                <div className="w-full bg-gray-100 h-2 rounded-full overflow-hidden">
                  <div
                    className="bg-coral h-full rounded-full transition-all duration-500"
                    style={{ width: `${active.compatibility.dimensions.communication}%` }}
                  />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span>Lifestyle & Weekend Flow</span>
                  <span className="text-coral">{active.compatibility.dimensions.lifestyle}%</span>
                </div>
                <div className="w-full bg-gray-100 h-2 rounded-full overflow-hidden">
                  <div
                    className="bg-coral h-full rounded-full transition-all duration-500"
                    style={{ width: `${active.compatibility.dimensions.lifestyle}%` }}
                  />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span>City Adventure Sync</span>
                  <span className="text-coral">{active.compatibility.dimensions.adventure}%</span>
                </div>
                <div className="w-full bg-gray-100 h-2 rounded-full overflow-hidden">
                  <div
                    className="bg-coral h-full rounded-full transition-all duration-500"
                    style={{ width: `${active.compatibility.dimensions.adventure}%` }}
                  />
                </div>
              </div>
            </div>

            <div className="bg-gray-50 rounded-xl p-3.5 mb-4">
              <span className="text-[11px] font-bold text-ink uppercase block mb-1.5">
                Key Chemistry Factors
              </span>
              <ul className="text-xs text-muted space-y-1">
                {active.compatibility.factors.map((f, i) => (
                  <li key={i} className="flex items-start gap-1.5">
                    <span className="text-coral font-bold">•</span> {f}
                  </li>
                ))}
              </ul>
            </div>

            <button
              type="button"
              onClick={() => setShowCompModal(false)}
              className="button button-outline w-full py-2.5 text-xs font-bold"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </>
  );
}
