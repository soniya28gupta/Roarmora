"use client";

import Link from "next/link";
import { useEffect, useState, type FormEvent } from "react";
import {
  ArrowLeft,
  Gamepad2,
  Gift,
  Phone,
  Send,
  ShieldCheck,
  Sparkles,
  Video,
} from "lucide-react";
import { apiRequest } from "@/lib/api/browser-client";
import { LiveCallingModal } from "@/components/live-calling-modal";
import type { CallSession, ChatMessage, Match, UserInventoryItem } from "@/types/roamora";

interface MessageResponse {
  id: string;
  senderId: string;
  body: string;
  createdAt: string;
}

export function ChatThread({
  person,
  initialMessages,
  currentUserId,
}: {
  person: Match;
  initialMessages: ChatMessage[];
  currentUserId: string;
}) {
  const [messages, setMessages] = useState(initialMessages);
  const [text, setText] = useState("");
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  const [sending, setSending] = useState(false);

  // Calling & Game States
  const [activeCallModal, setActiveCallModal] = useState(false);
  const [incomingCall, setIncomingCall] = useState<CallSession | null>(null);
  const [showGiftModal, setShowGiftModal] = useState(false);
  const [inventory, setInventory] = useState<UserInventoryItem[]>([]);
  const [gifting, setGifting] = useState(false);

  // Poll for new messages & incoming calls every 4s
  useEffect(() => {
    const interval = setInterval(async () => {
      try {
        const [latestMsgs, activeCall] = await Promise.all([
          apiRequest<MessageResponse[]>(`/matches/${encodeURIComponent(person.id)}/messages`),
          apiRequest<CallSession | null>(`/calls/active?matchId=${person.id}`),
        ]);

        if (latestMsgs && latestMsgs.length > 0) {
          setMessages(
            latestMsgs.map((m) => ({
              id: m.id,
              from: m.senderId === currentUserId ? "you" : "other",
              text: m.body,
              time: new Date(m.createdAt).toLocaleTimeString([], {
                hour: "numeric",
                minute: "2-digit",
              }),
            })),
          );
        }

        if (activeCall && activeCall.status === "CALLING" && activeCall.calleeId === currentUserId) {
          setIncomingCall(activeCall);
          setActiveCallModal(true);
        }
      } catch {
        // Continue silently
      }
    }, 4000);

    return () => clearInterval(interval);
  }, [person.id, currentUserId]);

  // Load user inventory for gifting
  async function loadInventory() {
    try {
      const items = await apiRequest<UserInventoryItem[]>("/inventory");
      setInventory(items || []);
      setShowGiftModal(true);
    } catch {
      setError("Could not load your inventory. Collect items in Adventure Mode first!");
    }
  }

  // Send a virtual gift to match
  async function sendGift(itemId: string) {
    if (gifting) return;
    setGifting(true);
    setError("");
    try {
      await apiRequest(`/inventory/${itemId}/use`, {
        method: "POST",
        body: JSON.stringify({ targetMatchId: person.id }),
      });
      setShowGiftModal(false);
      setNotice("Gift sent! ✨");
      // Refresh messages
      const updated = await apiRequest<MessageResponse[]>(`/matches/${encodeURIComponent(person.id)}/messages`);
      if (updated) {
        setMessages(
          updated.map((m) => ({
            id: m.id,
            from: m.senderId === currentUserId ? "you" : "other",
            text: m.body,
            time: new Date(m.createdAt).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }),
          })),
        );
      }
    } catch (err: any) {
      setError(err.message || "Failed to send gift.");
    } finally {
      setGifting(false);
    }
  }

  async function sendMessage(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmed = text.trim();
    if (!trimmed || sending) {
      if (!trimmed) setNotice("Add a note before sending.");
      return;
    }
    setSending(true);
    setError("");
    setNotice("");
    try {
      const message = await apiRequest<MessageResponse>(
        `/matches/${encodeURIComponent(person.id)}/messages`,
        {
          method: "POST",
          body: JSON.stringify({ body: trimmed }),
        },
      );
      setMessages((current) => [
        ...current,
        {
          id: message.id,
          from: message.senderId === currentUserId ? "you" : "other",
          text: message.body,
          time: new Date(message.createdAt).toLocaleTimeString([], {
            hour: "numeric",
            minute: "2-digit",
          }),
        },
      ]);
      setText("");
      setNotice("Message sent.");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Your message could not be sent.",
      );
    } finally {
      setSending(false);
    }
  }

  const initials = person.name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase();

  return (
    <>
      <div className="chat-panel">
        <header className="chat-header">
          <Link aria-label="Back to matches" className="icon-button chat-back" href="/matches">
            <ArrowLeft size={18} />
          </Link>
          <div
            aria-label={`${person.name}'s profile`}
            className="chat-person-avatar match-avatar-placeholder"
            role="img"
            style={person.image ? { backgroundImage: `url("${person.image}")` } : undefined}
          >
            {!person.image && initials}
          </div>
          <div className="chat-person">
            <strong>{person.name}</strong>
            <span className="flex items-center gap-1 text-[11px] text-pink-600 font-semibold">
              <Sparkles size={11} /> Mutual Match · {person.compatibility?.score ?? 85}% Chemistry
            </span>
          </div>

          {/* Action buttons: Call, Video, Gift, Game */}
          <div className="ml-auto flex items-center gap-2">
            <button
              type="button"
              onClick={loadInventory}
              className="p-2 text-ink hover:text-coral rounded-xl hover:bg-pink-50 transition-colors"
              title="Send a Virtual Gift from your Inventory"
            >
              <Gift size={19} />
            </button>
            <Link
              href={`/games?matchId=${person.id}`}
              className="p-2 text-ink hover:text-coral rounded-xl hover:bg-pink-50 transition-colors"
              title="Play Mini-Game with Match"
            >
              <Gamepad2 size={19} />
            </Link>
            <button
              type="button"
              onClick={() => {
                setIncomingCall(null);
                setActiveCallModal(true);
              }}
              className="p-2 text-coral hover:text-coral-dark rounded-xl hover:bg-pink-50 transition-colors"
              title="Start Live Video Call"
            >
              <Video size={20} />
            </button>
          </div>
        </header>

        <div className="chat-privacy">
          <ShieldCheck size={16} />
          <span>End-to-end encrypted session. Only you and your mutual match can communicate here.</span>
        </div>

        {/* Icebreaker Suggestions if conversation is fresh */}
        {messages.length === 0 && person.compatibility?.icebreakers && (
          <div className="mx-4 my-2 p-3.5 bg-gradient-to-r from-pink-50 to-rose-50 border border-pink-200/80 rounded-2xl">
            <span className="text-[11px] font-bold text-coral-dark uppercase tracking-wider block mb-1.5">
              💡 Spark Starters for {person.name}
            </span>
            <div className="flex flex-col gap-1.5">
              {person.compatibility.icebreakers.slice(0, 2).map((starter, i) => (
                <button
                  key={i}
                  type="button"
                  onClick={() => setText(starter)}
                  className="text-left text-xs bg-white/90 hover:bg-white text-ink p-2 rounded-xl border border-pink-100 shadow-sm transition-all text-ellipsis overflow-hidden"
                >
                  “{starter}”
                </button>
              ))}
            </div>
          </div>
        )}

        <div aria-live="polite" className="conversation">
          {messages.length === 0 && (
            <div className="conversation-date">YOUR CONVERSATION STARTS HERE</div>
          )}
          {messages.map((message) => (
            <div
              className={message.from === "you" ? "message-row mine" : "message-row"}
              key={message.id}
            >
              {message.from === "other" && (
                <div className="message-avatar match-avatar-placeholder" aria-hidden="true">
                  {initials}
                </div>
              )}
              <div className="message-content">
                <div className="message-bubble">{message.text}</div>
                <span>{message.time}</span>
              </div>
            </div>
          ))}
          {messages.length > 0 && (
            <div className="conversation-footer">
              Good chemistry grows with genuine curiosity <span>💖</span>
            </div>
          )}
        </div>

        <div className="chat-compose-area">
          <form className="chat-composer" onSubmit={(event) => void sendMessage(event)}>
            <input
              aria-label="Write a message"
              maxLength={2000}
              onChange={(event) => setText(event.target.value)}
              placeholder="Write a warm note or question…"
              value={text}
            />
            <button
              aria-label="Send message"
              className="send-button"
              disabled={sending || !text.trim()}
              type="submit"
            >
              {sending ? "…" : <Send size={17} />}
            </button>
          </form>
          <p
            aria-live="polite"
            className={error ? "chat-feedback error-text" : "chat-feedback"}
            role={error ? "alert" : "status"}
          >
            {error || notice || "Only you and your mutual match can see this thread."}
          </p>
        </div>
      </div>

      {/* Live Calling Modal */}
      {activeCallModal && (
        <LiveCallingModal
          match={person}
          currentUserId={currentUserId}
          initialCall={incomingCall}
          onClose={() => {
            setActiveCallModal(false);
            setIncomingCall(null);
          }}
        />
      )}

      {/* Send Virtual Gift Modal */}
      {showGiftModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in">
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 shadow-2xl border border-pink-100">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100 mb-4">
              <h3 className="font-bold text-ink flex items-center gap-2">
                <Gift size={18} className="text-coral" /> Send Virtual Gift
              </h3>
              <button
                type="button"
                onClick={() => setShowGiftModal(false)}
                className="text-gray-400 hover:text-ink"
              >
                ✕
              </button>
            </div>

            {inventory.length === 0 ? (
              <div className="text-center py-6">
                <div className="w-12 h-12 rounded-2xl bg-pink-50 text-coral flex items-center justify-center mx-auto mb-2 text-2xl">
                  🎒
                </div>
                <h4 className="font-bold text-sm text-ink">Your backpack is empty</h4>
                <p className="text-xs text-muted mt-1 mb-4">
                  Explore the Adventure Map to discover coffee cups, golden hearts, and mystery tokens!
                </p>
                <Link href="/treasure-map" className="button button-coral text-xs font-bold py-2">
                  Go to Adventure Map
                </Link>
              </div>
            ) : (
              <div className="space-y-2.5 max-h-64 overflow-y-auto pr-1">
                {inventory.map((inv) => (
                  <div
                    key={inv.id}
                    className="p-3 bg-pink-50/50 hover:bg-pink-50 rounded-2xl border border-pink-200/60 flex items-center justify-between gap-3"
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-2xl">{inv.item.icon}</span>
                      <div>
                        <strong className="text-xs text-ink block">{inv.item.name}</strong>
                        <span className="text-[10px] text-muted block">Qty: {inv.quantity}</span>
                      </div>
                    </div>
                    <button
                      type="button"
                      disabled={gifting}
                      onClick={() => void sendGift(inv.item.id)}
                      className="button button-coral button-small text-[11px] font-bold py-1 px-3"
                    >
                      {gifting ? "Sending…" : "Send"}
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
