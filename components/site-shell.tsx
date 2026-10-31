"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState, useEffect } from "react";
import {
  Bell,
  Compass,
  Gamepad2,
  Gift,
  Heart,
  MapPinned,
  MessageCircle,
  Sparkles,
  UserRound,
} from "lucide-react";
import { DemoStateProvider, DemoStateSwitcher } from "@/components/demo-state";
import { NavLink } from "@/components/nav-link";
import { SessionGuard } from "@/components/session-guard";
import { SignOutButton } from "@/components/sign-out-button";
import { apiRequest } from "@/lib/api/browser-client";

const navigation = [
  { href: "/discover", label: "Discover", icon: Heart, iconKey: "discover" },
  { href: "/treasure-map", label: "Adventure Map", icon: MapPinned, iconKey: "map" },
  { href: "/matches", label: "Matches", icon: MessageCircle, iconKey: "matches" },
  { href: "/games", label: "Mini-Games", icon: Gamepad2, iconKey: "games" },
  { href: "/inventory", label: "Collectibles", icon: Gift, iconKey: "inventory" },
  { href: "/notifications", label: "Alerts", icon: Bell, iconKey: "notifications" },
  { href: "/profile", label: "Profile", icon: UserRound, iconKey: "profile" },
] as const;

export function SiteShell({
  children,
  protectedPage = true,
}: {
  children: React.ReactNode;
  protectedPage?: boolean;
}) {
  const pathname = usePathname();
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (!protectedPage) return;
    let mounted = true;
    const fetchAlerts = async () => {
      try {
        const res = await apiRequest<{ unreadCount: number }>("/notifications");
        if (mounted && res?.unreadCount !== undefined) {
          setUnreadCount(res.unreadCount);
        }
      } catch {
        // Fallback silently
      }
    };
    void fetchAlerts();
    const interval = setInterval(fetchAlerts, 15000);
    return () => {
      mounted = false;
      clearInterval(interval);
    };
  }, [protectedPage, pathname]);

  const content = protectedPage ? <SessionGuard>{children}</SessionGuard> : children;

  return (
    <DemoStateProvider previewMode={!protectedPage}>
      <div className="site-frame">
        <header className="topbar">
          <Link aria-label="Pookie Match home" className="brand" href="/">
            <span className="brand-mark">
              <Sparkles size={18} strokeWidth={2.4} />
            </span>
            <span className="brand-title">
              Pookie Match<span className="brand-period">.</span>
            </span>
          </Link>
          <div className="topbar-center">
            <span className="topbar-sparkle">💖</span>
            <span>Gamified Dating & Real-World City Quests</span>
          </div>
          <div className="topbar-actions">
            {protectedPage ? (
              <div className="flex items-center gap-4">
                <Link
                  href="/notifications"
                  className="relative p-2 text-ink hover:text-coral transition-colors"
                  aria-label="View notifications"
                >
                  <Bell size={20} />
                  {unreadCount > 0 && (
                    <span className="absolute -top-1 -right-1 bg-coral text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center animate-pulse">
                      {unreadCount > 9 ? "9+" : unreadCount}
                    </span>
                  )}
                </Link>
                <SignOutButton />
              </div>
            ) : (
              <>
                <Link className="topbar-link" href="/login">
                  Log in
                </Link>
                <Link className="button button-coral button-small" href="/register">
                  Join Pookie Match <span>↗</span>
                </Link>
              </>
            )}
          </div>
        </header>

        <div className="app-layout">
          <aside className="sidebar">
            <div className="sidebar-label">POOKIE QUEST</div>
            <nav aria-label="Main navigation" className="side-nav">
              {navigation.map(({ href, label, iconKey, icon: Icon }) => {
                const isActive = pathname === href;
                return (
                  <Link
                    key={href}
                    href={href}
                    className={`side-link ${isActive ? "is-active" : ""}`}
                  >
                    <Icon size={18} />
                    <span>{label}</span>
                    {iconKey === "notifications" && unreadCount > 0 && (
                      <span className="nav-count">{unreadCount}</span>
                    )}
                  </Link>
                );
              })}
            </nav>

            <div className="sidebar-note">
              <span className="note-icon">
                <Compass size={17} />
              </span>
              <strong>Adventure Mode</strong>
              <p>Explore your city radar, find virtual coffee cups, and meet matches nearby.</p>
              <Link href="/treasure-map">
                Open Radar Map <span>→</span>
              </Link>
            </div>
            <div className="sidebar-foot">
              {protectedPage ? "🔒 End-to-end privacy · Consent-first location" : "Sample preview mode"}
            </div>
          </aside>

          <main className="main-content">
            <div className="mobile-brand-row">
              <Link className="brand" href="/">
                <span className="brand-mark">
                  <Sparkles size={18} />
                </span>
                <span>
                  Pookie Match<span className="brand-period">.</span>
                </span>
              </Link>
              {protectedPage && (
                <Link
                  href="/notifications"
                  className="relative p-2"
                  aria-label="Notifications"
                >
                  <Bell size={20} />
                  {unreadCount > 0 && (
                    <span className="absolute top-1 right-1 bg-coral text-white text-[9px] font-bold w-4 h-4 rounded-full flex items-center justify-center">
                      {unreadCount}
                    </span>
                  )}
                </Link>
              )}
            </div>
            {content}
          </main>
        </div>

        <nav aria-label="Mobile navigation" className="mobile-nav">
          {navigation.slice(0, 5).map(({ href, label, icon: Icon }) => (
            <Link
              href={href}
              key={href}
              className={pathname === href ? "active-mobile-link" : ""}
            >
              <Icon size={19} strokeWidth={1.8} />
              <span>{label}</span>
            </Link>
          ))}
        </nav>
        {!protectedPage && <DemoStateSwitcher />}
      </div>
    </DemoStateProvider>
  );
}
