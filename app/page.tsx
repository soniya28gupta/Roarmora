import Link from "next/link";
import {
  ArrowDownRight,
  ArrowUpRight,
  Brain,
  Compass,
  Gift,
  Heart,
  MapPin,
  Sparkles,
  Trophy,
  Video,
  Zap,
} from "lucide-react";
import { DemoStateSurface } from "@/components/demo-state";
import { PageFrame } from "@/components/page-frame";
import { PlaceCard, SectionTitle } from "@/components/ui";
import { api } from "@/lib/api";

export default async function HomePage() {
  const [user, places, drops] = await Promise.all([
    api.getCurrentUser(),
    api.listPlaces(),
    api.listDrops(),
  ]);

  return (
    <PageFrame protectedPage={false}>
      <div className="home-page">
        {/* Hero Section */}
        <section className="welcome-strip">
          <div className="welcome-copy">
            <span className="eyebrow">
              <span className="eyebrow-dot" /> AI-POWERED GAMIFIED DATING & CITY QUESTS
            </span>
            <h1>
              Find your <em>pookie</em> through real-world <em>adventure.</em>
            </h1>
            <p>
              Tinder-style matchmaking meets Pokémon GO city exploration. Discover genuine connections through shared passions, interactive mini-games, virtual collectibles, and privacy-focused live calling.
            </p>
            <div className="welcome-actions">
              <Link className="button button-coral shadow-lg" href="/discover">
                Start Swiping <ArrowUpRight size={17} />
              </Link>
              <Link className="button button-outline" href="/treasure-map">
                <Compass size={15} /> Explore Map Radar
              </Link>
            </div>
            <div className="welcome-foot">
              <MapPin size={14} /> Set in New Delhi (Hauz Khas & Lodhi Garden) · <span>Consent-first GPS radar</span>
            </div>
          </div>

          <div className="welcome-art" role="img" aria-label="Illustrative photo of a sunlit garden exploration">
            <div className="art-note">
              <span className="art-note-icon">
                <Sparkles size={16} />
              </span>
              <div>
                <strong>Pookie Match Discovery</strong>
                <small>Coffee cups & sparks nearby</small>
              </div>
              <span className="art-note-arrow">↗</span>
            </div>
            <span className="art-scribble">explore together 💖</span>
          </div>

          <div className="welcome-stats">
            <div>
              <strong>01</strong>
              <span>
                Social Discovery
                <br />
                Swipe left/right with AI compatibility
              </span>
            </div>
            <i />
            <div>
              <strong>02</strong>
              <span>
                Adventure Mode
                <br />
                Collect items & solve city quests
              </span>
            </div>
          </div>
        </section>

        {/* 4 Feature Pillars Grid */}
        <section className="my-10 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="p-5 bg-white border border-pink-100 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
            <div className="w-10 h-10 rounded-xl bg-pink-50 text-coral flex items-center justify-center mb-3">
              <Heart size={20} fill="currentColor" />
            </div>
            <h3 className="font-bold text-sm text-ink mb-1">Tinder-Style Swiping</h3>
            <p className="text-xs text-muted leading-relaxed">
              Touch and mouse drag gesture profile cards with photo galleries, distance indicators, and mutual-spark detection.
            </p>
          </div>

          <div className="p-5 bg-white border border-pink-100 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
            <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center mb-3">
              <Compass size={20} />
            </div>
            <h3 className="font-bold text-sm text-ink mb-1">Adventure Mode Radar</h3>
            <p className="text-xs text-muted leading-relaxed">
              Interactive Leaflet maps with 500m proximity radar, virtual coffee cups, golden hearts, and remote exploration.
            </p>
          </div>

          <div className="p-5 bg-white border border-pink-100 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
            <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center mb-3">
              <Brain size={20} />
            </div>
            <h3 className="font-bold text-sm text-ink mb-1">AI Compatibility Engine</h3>
            <p className="text-xs text-muted leading-relaxed">
              Daily lifestyle vector quiz, multidimensional chemistry breakdown, and personalized icebreaker starters.
            </p>
          </div>

          <div className="p-5 bg-white border border-pink-100 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-3">
              <Video size={20} />
            </div>
            <h3 className="font-bold text-sm text-ink mb-1">Live Audio/Video Calls</h3>
            <p className="text-xs text-muted leading-relaxed">
              Encrypted WebRTC calling exclusively between mutual matches, complete with romance glow visual filters.
            </p>
          </div>
        </section>

        {/* Places & Drops Section */}
        <DemoStateSurface emptyTitle="A quiet moment in the city" emptyCopy="Your next favorite spot is just a wander away.">
          <section className="home-section">
            <div className="section-title-row">
              <div>
                <span className="eyebrow">CURATED ADVENTURE SPOTS</span>
                <SectionTitle title="A good place to meet your pookie." />
              </div>
              <Link className="text-link" href="/explore">
                See all places <ArrowUpRight size={15} />
              </Link>
            </div>
            <div className="place-grid home-place-grid">
              {places.slice(0, 3).map((place) => (
                <PlaceCard key={place.id} place={place} />
              ))}
            </div>
          </section>

          {/* Bottom Callout Banners */}
          <section className="home-bottom-grid">
            <div className="drop-feature">
              <span className="drop-feature-icon">
                <Gift size={17} />
              </span>
              <div className="drop-feature-content">
                <span className="eyebrow">COLLECTIBLE DROPS · ACTIVE NOW</span>
                <h2>{drops[0]?.title || "Chai & book swap"}</h2>
                <p>A few bookish wanderers, a courtyard table, and coffee tokens waiting on the radar map.</p>
                <div className="drop-feature-meta">
                  <span>
                    <MapPin size={13} />
                    {drops[0]?.area || "Hauz Khas Village"}
                  </span>
                  <span>{drops[0]?.startsAt || "Today · 5:00 PM"}</span>
                </div>
              </div>
              <Link aria-label="Explore the adventure map" className="round-arrow" href="/treasure-map">
                <ArrowUpRight size={19} />
              </Link>
            </div>

            <div className="people-feature">
              <div className="people-feature-copy">
                <span className="eyebrow">SHARED VIBES & ADVENTURES</span>
                <h2>Someone nearby is eager to explore the city with you.</h2>
                <Link className="text-link" href="/discover">
                  Find your match <ArrowUpRight size={15} />
                </Link>
              </div>
              <div className="people-stack" aria-label={`Illustrative profile of ${user.name}`}>
                <span className="stack-person person-one" />
                <span className="stack-person person-two" />
                <span className="stack-person person-three" />
                <span className="stack-heart">
                  <Heart size={16} fill="currentColor" />
                </span>
              </div>
            </div>
          </section>
        </DemoStateSurface>

        <footer className="page-footer">
          <span>
            Pookie Match<span className="brand-period">.</span> AI-Powered Gamified Dating & Real-World Exploration.
          </span>
          <span>
            Privacy-First · 18+ Only · <Link href="/profile">Consent Settings</Link>
          </span>
        </footer>
      </div>
    </PageFrame>
  );
}
