"use client";

import { useState } from "react";
import Link from "next/link";
import {
  Bell,
  Check,
  CheckCheck,
  Flame,
  Gamepad2,
  Gift,
  Heart,
  MessageCircle,
  Radio,
  Sparkles,
  Trophy,
  Video,
} from "lucide-react";
import { apiRequest } from "@/lib/api/browser-client";
import type { AppNotification } from "@/types/roamora";

export function NotificationsView({
  initialNotifications,
}: {
  initialNotifications: AppNotification[];
}) {
  const [notifications, setNotifications] = useState(initialNotifications);
  const [filter, setFilter] = useState<"all" | "unread">("all");

  const unreadCount = notifications.filter((n) => !n.read).length;
  const filtered = filter === "all" ? notifications : notifications.filter((n) => !n.read);

  async function markAsRead(id: string) {
    try {
      await apiRequest(`/notifications/${id}/read`, { method: "PATCH" });
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, read: true } : n)),
      );
    } catch {
      // Fallback
    }
  }

  async function markAllAsRead() {
    try {
      await apiRequest(`/notifications/read-all`, { method: "POST" });
      setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
    } catch {
      // Fallback
    }
  }

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case "MATCH":
        return <Heart size={18} className="text-coral" fill="currentColor" />;
      case "MESSAGE":
        return <MessageCircle size={18} className="text-blue-500" />;
      case "COLLECTIBLE":
        return <Gift size={18} className="text-amber-500" />;
      case "ACHIEVEMENT":
        return <Trophy size={18} className="text-purple-500" />;
      case "CALL":
        return <Video size={18} className="text-green-500" />;
      case "INVITE":
        return <Gamepad2 size={18} className="text-pink-500" />;
      default:
        return <Bell size={18} className="text-coral" />;
    }
  };

  return (
    <div className="notifications-center max-w-2xl mx-auto my-6">
      <div className="flex items-center justify-between pb-4 border-b border-line mb-6">
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setFilter("all")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              filter === "all"
                ? "bg-coral text-white shadow-sm"
                : "bg-gray-100 text-ink hover:bg-gray-200"
            }`}
          >
            All Alerts ({notifications.length})
          </button>
          <button
            type="button"
            onClick={() => setFilter("unread")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              filter === "unread"
                ? "bg-coral text-white shadow-sm"
                : "bg-gray-100 text-ink hover:bg-gray-200"
            }`}
          >
            Unread ({unreadCount})
          </button>
        </div>

        {unreadCount > 0 && (
          <button
            type="button"
            onClick={markAllAsRead}
            className="text-xs font-bold text-coral hover:text-coral-dark flex items-center gap-1.5"
          >
            <CheckCheck size={16} /> Mark all read
          </button>
        )}
      </div>

      {filtered.length === 0 ? (
        <div className="bg-white rounded-3xl p-8 border border-pink-100 shadow-sm text-center">
          <div className="w-16 h-16 rounded-full bg-pink-50 text-coral flex items-center justify-center text-3xl mx-auto mb-3 shadow-inner">
            🔔
          </div>
          <h3 className="text-lg font-bold text-ink">
            {filter === "unread" ? "No unread alerts" : "No notifications yet"}
          </h3>
          <p className="text-xs text-muted max-w-sm mx-auto mt-1 mb-5">
            You will be notified when you get a mutual match, receive a message, or discover a nearby collectible drop.
          </p>
          <Link href="/discover" className="button button-coral py-2.5 px-6 font-bold text-xs shadow">
            Discover People
          </Link>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((item) => (
            <div
              key={item.id}
              className={`p-4 rounded-2xl border transition-all flex items-start gap-4 ${
                item.read
                  ? "bg-white border-gray-100"
                  : "bg-gradient-to-r from-pink-50/70 to-rose-50/40 border-pink-200 shadow-sm"
              }`}
            >
              <div className="p-2.5 rounded-xl bg-white shadow-sm border border-pink-100 shrink-0">
                {getNotificationIcon(item.type)}
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between gap-2">
                  <h4 className="font-bold text-sm text-ink truncate">{item.title}</h4>
                  <span className="text-[10px] text-gray-400 shrink-0">
                    {new Date(item.createdAt).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}
                  </span>
                </div>
                <p className="text-xs text-muted mt-0.5 leading-relaxed">{item.message}</p>

                <div className="mt-2.5 flex items-center gap-3">
                  {item.link && (
                    <Link
                      href={item.link}
                      onClick={() => void markAsRead(item.id)}
                      className="text-xs font-bold text-coral hover:text-coral-dark"
                    >
                      View Details →
                    </Link>
                  )}
                  {!item.read && (
                    <button
                      type="button"
                      onClick={() => void markAsRead(item.id)}
                      className="text-[11px] font-semibold text-gray-400 hover:text-ink flex items-center gap-1"
                    >
                      <Check size={12} /> Mark read
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

