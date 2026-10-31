"use client";

import Link from "next/link";
import { useState } from "react";
import {
  Gamepad2,
  Heart,
  MessageCircle,
  MoreHorizontal,
  Sparkles,
  Video,
} from "lucide-react";
import { apiRequest } from "@/lib/api/browser-client";
import { LiveCallingModal } from "@/components/live-calling-modal";
import type { Match } from "@/types/roamora";

const reportReasons = [
  "Harassment or abuse",
  "Fake profile / impersonation",
  "Inappropriate or coercive behavior",
  "Spam or commercial solicitations",
  "Other safety concern",
];

export function MatchesList({
  people,
  currentUserId = "",
}: {
  people: Match[];
  currentUserId?: string;
}) {
  const [matches, setMatches] = useState(people);
  const [menuId, setMenuId] = useState("");
  const [reportId, setReportId] = useState("");
  const [reason, setReason] = useState(reportReasons[0]!);
  const [busy, setBusy] = useState("");
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  const [callingMatch, setCallingMatch] = useState<Match | null>(null);

  async function removeMatch(person: Match, block: boolean) {
    if (busy) return;
    const action = block ? "block this person" : "unmatch";
    if (!window.confirm(`Are you sure you want to ${action}?`)) return;
    setBusy(person.id);
    setError("");
    setNotice("");
    try {
      if (block) {
        await apiRequest("/blocks", {
          method: "POST",
          body: JSON.stringify({ targetUserId: person.otherUserId }),
        });
      } else {
        await apiRequest(`/matches/${encodeURIComponent(person.id)}`, {
          method: "DELETE",
        });
      }
      setMatches((current) => current.filter((match) => match.id !== person.id));
      setMenuId("");
      setNotice(
        block
          ? `${person.name} has been blocked.`
          : `You unmatched ${person.name}.`,
      );
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "This connection could not be updated.",
      );
    } finally {
      setBusy("");
    }
  }

  async function submitReport(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const person = matches.find((match) => match.id === reportId);
    if (!person || busy) return;
    setBusy(person.id);
    setError("");
    setNotice("");
    try {
      await apiRequest("/reports", {
        method: "POST",
        body: JSON.stringify({ targetUserId: person.otherUserId, reason }),
      });
      setReportId("");
      setNotice("Thank you for helping keep Pookie Match safe. Your report was sent for review.");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Your report could not be submitted.",
      );
    } finally {
      setBusy("");
    }
  }

  return (
    <>
      {(notice || error) && (
        <p
          aria-live="polite"
          className={error ? "operation-message error-text" : "operation-message"}
          role={error ? "alert" : "status"}
        >
          {error || notice}
        </p>
      )}

      <div className="match-list space-y-3">
        {matches.length === 0 ? (
          <div className="state-card state-empty">
            <div className="w-16 h-16 rounded-full bg-pink-50 text-coral flex items-center justify-center mx-auto mb-3 text-2xl shadow-inner">
              💖
            </div>
            <h2>No mutual matches yet</h2>
            <p>
              When you and another wanderer both like each other, your match will appear here!
            </p>
            <Link className="button button-coral mt-4 py-2.5 px-6 font-bold text-xs" href="/discover">
              Discover People
            </Link>
          </div>
        ) : (
          matches.map((person) => {
            const initials = person.name
              .trim()
              .split(/\s+/)
              .slice(0, 2)
              .map((part) => part[0])
              .join("")
              .toUpperCase();

            const compScore = person.compatibility?.score ?? 85;

            return (
              <article
                className="match-row p-4 bg-white rounded-2xl border border-pink-100 shadow-sm hover:shadow-md transition-shadow flex items-center justify-between gap-4"
                key={person.id}
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div
                    aria-label={`${person.name}'s profile`}
                    className="match-avatar match-avatar-placeholder w-14 h-14 rounded-2xl bg-cover bg-center shrink-0 shadow"
                    role="img"
                    style={person.image ? { backgroundImage: `url("${person.image}")` } : undefined}
                  >
                    {!person.image && initials}
                  </div>
                  <div className="match-info min-w-0">
                    <div className="match-name-line flex items-center gap-2">
                      <h2 className="font-bold text-base text-ink truncate">
                        {person.name}, {person.age}
                      </h2>
                      <span className="text-[11px] font-bold text-coral bg-pink-50 px-2 py-0.5 rounded-full shrink-0 flex items-center gap-1">
                        <Sparkles size={11} /> {compScore}% Match
                      </span>
                    </div>
                    <p className="text-xs text-muted truncate mt-0.5">{person.city}</p>
                    <small className="text-[11px] text-gray-500 line-clamp-1 mt-0.5">
                      {person.lastMessage
                        ? `${person.lastMessage.fromMe ? "You: " : ""}${person.lastMessage.text}`
                        : person.bio || person.interests.join(" · ")}
                    </small>
                  </div>
                </div>

                <div className="match-actions flex items-center gap-2 shrink-0">
                  <Link
                    className="button button-coral match-message py-2 px-3.5 text-xs font-bold shadow-sm"
                    href={`/chat?matchId=${encodeURIComponent(person.id)}`}
                  >
                    <MessageCircle size={15} /> Chat
                  </Link>
                  <button
                    type="button"
                    onClick={() => setCallingMatch(person)}
                    className="p-2 text-coral hover:text-coral-dark rounded-xl hover:bg-pink-50 transition-colors"
                    title="Live Video Call"
                  >
                    <Video size={18} />
                  </button>
                  <Link
                    href={`/games?matchId=${encodeURIComponent(person.id)}`}
                    className="p-2 text-ink hover:text-coral rounded-xl hover:bg-pink-50 transition-colors"
                    title="Play Mini-Game with Match"
                  >
                    <Gamepad2 size={18} />
                  </Link>

                  <button
                    aria-expanded={menuId === person.id}
                    aria-label={`Connection options for ${person.name}`}
                    className="icon-button p-2 text-gray-400 hover:text-ink"
                    disabled={busy === person.id}
                    onClick={() => {
                      setMenuId((current) => (current === person.id ? "" : person.id));
                      setReportId("");
                    }}
                    type="button"
                  >
                    <MoreHorizontal size={19} />
                  </button>

                  {menuId === person.id && (
                    <div className="match-menu absolute right-8 mt-24 bg-white border border-pink-100 rounded-2xl shadow-xl p-1 z-30 text-xs font-semibold">
                      <button
                        className="w-full text-left px-4 py-2 hover:bg-pink-50 rounded-xl text-ink"
                        disabled={busy === person.id}
                        onClick={() => void removeMatch(person, false)}
                        type="button"
                      >
                        Unmatch
                      </button>
                      <button
                        className="w-full text-left px-4 py-2 hover:bg-red-50 rounded-xl text-red-600"
                        disabled={busy === person.id}
                        onClick={() => void removeMatch(person, true)}
                        type="button"
                      >
                        Block user
                      </button>
                      <button
                        className="w-full text-left px-4 py-2 hover:bg-yellow-50 rounded-xl text-amber-700"
                        disabled={busy === person.id}
                        onClick={() => {
                          setReportId(person.id);
                          setReason(reportReasons[0]!);
                          setMenuId("");
                        }}
                        type="button"
                      >
                        Report user
                      </button>
                    </div>
                  )}
                </div>

                {reportId === person.id && (
                  <form className="report-form w-full col-span-full mt-3 p-4 bg-gray-50 rounded-xl text-xs" onSubmit={submitReport}>
                    <label className="font-bold block mb-1">
                      Reason for reporting {person.name}:
                      <select
                        onChange={(event) => setReason(event.target.value)}
                        value={reason}
                        className="mt-1 w-full p-2 border border-line rounded-lg"
                      >
                        {reportReasons.map((val) => (
                          <option key={val}>{val}</option>
                        ))}
                      </select>
                    </label>
                    <div className="mt-2.5 flex items-center gap-2">
                      <button
                        className="button button-coral button-small font-bold text-xs"
                        disabled={busy === person.id}
                        type="submit"
                      >
                        {busy === person.id ? "Sending…" : "Submit Report"}
                      </button>
                      <button
                        className="text-link text-xs"
                        onClick={() => setReportId("")}
                        type="button"
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                )}
              </article>
            );
          })
        )}
      </div>

      {callingMatch && (
        <LiveCallingModal
          match={callingMatch}
          currentUserId={currentUserId}
          onClose={() => setCallingMatch(null)}
        />
      )}
    </>
  );
}
