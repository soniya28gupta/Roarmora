"use client";

import { useEffect, useState } from "react";
import { AlertCircle, CheckCircle2, Loader2, RefreshCw, User, UserX } from "lucide-react";
import { apiRequest } from "@/lib/api/browser-client";

export type BlockedUser = {
  id: string;
  name: string;
  avatarUrl: string;
  city?: string;
  blockedAt?: string;
};

export function BlockedUsersManager() {
  const [blockedUsers, setBlockedUsers] = useState<BlockedUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [userToUnblock, setUserToUnblock] = useState<BlockedUser | null>(null);
  const [unblocking, setUnblocking] = useState(false);

  async function loadBlockedUsers() {
    setLoading(true);
    setError("");
    try {
      const data = await apiRequest<BlockedUser[]>("/blocks");
      setBlockedUsers(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load blocked users.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadBlockedUsers();
  }, []);

  async function handleConfirmUnblock() {
    if (!userToUnblock || unblocking) return;
    setUnblocking(true);
    setError("");
    setNotice("");
    try {
      await apiRequest(`/blocks/${encodeURIComponent(userToUnblock.id)}`, {
        method: "DELETE",
      });

      const unblockedName = userToUnblock.name;
      setBlockedUsers((current) => current.filter((u) => u.id !== userToUnblock.id));
      setUserToUnblock(null);
      setNotice(`${unblockedName} has been unblocked. They can now appear in your Discover results.`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to unblock user.");
    } finally {
      setUnblocking(false);
    }
  }

  return (
    <div className="mt-4 pt-4 border-t border-line">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="p-1 rounded bg-rose-50 text-rose-600">
            <UserX size={15} />
          </span>
          <h3 className="text-xs font-bold text-ink uppercase tracking-wider">Blocked Users</h3>
          {blockedUsers.length > 0 && (
            <span className="px-1.5 py-0.5 text-[10px] font-bold rounded-full bg-rose-100 text-rose-700">
              {blockedUsers.length}
            </span>
          )}
        </div>
        <button
          type="button"
          onClick={loadBlockedUsers}
          disabled={loading}
          aria-label="Refresh blocked users"
          className="text-muted hover:text-ink p-1 rounded transition-colors"
          title="Refresh"
        >
          <RefreshCw size={13} className={loading ? "animate-spin" : ""} />
        </button>
      </div>

      <p className="text-[11px] text-muted mb-3 leading-relaxed">
        Blocked users cannot match with you, send messages, or see your activity. You can unblock them anytime to restore discovery.
      </p>

      {notice && (
        <div className="mb-3 p-2.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs flex items-center gap-2 animate-in fade-in">
          <CheckCircle2 size={14} className="shrink-0 text-emerald-600" />
          <span className="flex-1">{notice}</span>
          <button
            type="button"
            onClick={() => setNotice("")}
            className="text-emerald-700 hover:text-emerald-900 text-xs font-bold px-1"
          >
            ×
          </button>
        </div>
      )}

      {error && (
        <div className="mb-3 p-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-center gap-2">
          <AlertCircle size={14} className="shrink-0 text-rose-600" />
          <span className="flex-1">{error}</span>
          <button
            type="button"
            onClick={loadBlockedUsers}
            className="text-xs font-bold underline hover:no-underline"
          >
            Retry
          </button>
        </div>
      )}

      {loading ? (
        <div className="py-4 flex items-center justify-center gap-2 text-xs text-muted">
          <Loader2 size={15} className="animate-spin text-coral" />
          <span>Loading blocked users…</span>
        </div>
      ) : blockedUsers.length === 0 ? (
        <div className="py-3 px-3.5 rounded-xl bg-white/70 border border-line text-center">
          <p className="text-xs text-muted">No blocked users</p>
          <span className="text-[10px] text-muted/70 block mt-0.5">
            Your blocklist is currently empty.
          </span>
        </div>
      ) : (
        <ul className="space-y-2 max-h-56 overflow-y-auto pr-1">
          {blockedUsers.map((user) => (
            <li
              key={user.id}
              className="flex items-center justify-between p-2 rounded-xl bg-white border border-line shadow-xs hover:border-coral/30 transition-colors"
            >
              <div className="flex items-center gap-2.5 min-w-0">
                <div className="w-8 h-8 rounded-full overflow-hidden bg-rose-100 flex items-center justify-center shrink-0 border border-line">
                  {user.avatarUrl ? (
                    <img
                      src={user.avatarUrl}
                      alt={user.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <span className="text-xs font-bold text-rose-600">
                      {user.name.charAt(0).toUpperCase() || <User size={13} />}
                    </span>
                  )}
                </div>
                <div className="min-w-0">
                  <h4 className="text-xs font-bold text-ink truncate">{user.name}</h4>
                  {user.city && (
                    <span className="text-[10px] text-muted block truncate">{user.city}</span>
                  )}
                </div>
              </div>

              <button
                type="button"
                onClick={() => {
                  setError("");
                  setUserToUnblock(user);
                }}
                className="button button-outline text-[11px] py-1 px-2.5 font-bold text-ink hover:text-coral hover:border-coral shrink-0 transition-colors"
              >
                Unblock
              </button>
            </li>
          ))}
        </ul>
      )}

      {/* Confirmation Dialog Modal */}
      {userToUnblock && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in"
        >
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 text-center shadow-2xl border border-line">
            <div className="w-12 h-12 mx-auto rounded-full bg-rose-100 text-rose-600 flex items-center justify-center mb-3">
              <UserX size={24} />
            </div>

            <h3 className="text-base font-bold text-ink">Unblock {userToUnblock.name}?</h3>

            <p className="text-xs text-muted mt-2 leading-relaxed">
              {userToUnblock.name} will be removed from your blocklist. They will become eligible to appear in your Discover recommendations again subject to your normal discovery preferences.
            </p>

            <div className="mt-5 flex flex-col gap-2">
              <button
                type="button"
                disabled={unblocking}
                onClick={handleConfirmUnblock}
                className="button button-primary w-full py-2.5 text-xs font-bold flex items-center justify-center gap-2"
              >
                {unblocking ? (
                  <>
                    <Loader2 size={14} className="animate-spin" />
                    <span>Unblocking…</span>
                  </>
                ) : (
                  "Yes, Unblock"
                )}
              </button>

              <button
                type="button"
                disabled={unblocking}
                onClick={() => setUserToUnblock(null)}
                className="button button-outline w-full py-2 text-xs font-semibold"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

