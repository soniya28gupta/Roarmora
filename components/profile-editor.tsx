"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  AlertTriangle,
  Check,
  Compass,
  Edit3,
  MapPin,
  Radio,
  ShieldCheck,
  Trash2,
  User,
  Zap,
} from "lucide-react";
import { apiRequest } from "@/lib/api/browser-client";
import type { AccountProfile } from "@/types/roamora";

const availableInterests = [
  "Cafés",
  "Outdoors",
  "Art",
  "Books",
  "Photography",
  "Live music",
  "Food",
  "Gaming",
  "Fitness",
  "Travel",
];

const genderOptions = ["Woman", "Man", "Non-binary", "Prefer not to say"];
const lookingForOptions = ["Everyone", "Women", "Men", "Non-binary people"];

export function ProfileEditor({ user }: { user: AccountProfile }) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState(user.displayName);
  const [city, setCity] = useState(user.city);
  const [bio, setBio] = useState(user.bio);
  const [selected, setSelected] = useState(user.interests);
  const [gender, setGender] = useState(user.gender || "Prefer not to say");
  const [lookingFor, setLookingFor] = useState(user.lookingFor || "Everyone");
  const [discoverable, setDiscoverable] = useState(user.discoverable);
  const [locationConsent, setLocationConsent] = useState(user.locationConsent);
  const [globalExploreMode, setGlobalExploreMode] = useState(user.globalExploreMode ?? false);
  const [discoveryRadius, setDiscoveryRadius] = useState(user.discoveryRadiusMeters ?? 500);

  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleting, setDeleting] = useState(false);

  function toggleInterest(interest: string) {
    setMessage("");
    setSelected((current) =>
      current.includes(interest)
        ? current.filter((value) => value !== interest)
        : [...current, interest],
    );
  }

  function cancelEdit() {
    setDisplayName(user.displayName);
    setCity(user.city);
    setBio(user.bio);
    setSelected(user.interests);
    setGender(user.gender || "Prefer not to say");
    setLookingFor(user.lookingFor || "Everyone");
    setDiscoverable(user.discoverable);
    setLocationConsent(user.locationConsent);
    setGlobalExploreMode(user.globalExploreMode ?? false);
    setDiscoveryRadius(user.discoveryRadiusMeters ?? 500);
    setEditing(false);
    setError("");
    setMessage("");
  }

  async function saveProfile() {
    if (saving) return;
    setSaving(true);
    setError("");
    setMessage("");
    try {
      await apiRequest("/profile", {
        method: "PATCH",
        body: JSON.stringify({
          displayName,
          city,
          bio,
          interests: selected,
          gender,
          lookingFor,
          discoverable,
        }),
      });
      await apiRequest("/preferences", {
        method: "PUT",
        body: JSON.stringify({
          locationConsent,
          globalExploreMode,
          discoveryRadiusMeters: discoveryRadius,
        }),
      });
      setEditing(false);
      setMessage("Your Pookie Match profile and discovery preferences have been saved! ✨");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Your profile could not be saved.",
      );
    } finally {
      setSaving(false);
    }
  }

  async function handleDeleteAccount() {
    if (deleting) return;
    setDeleting(true);
    setError("");
    try {
      await apiRequest("/account", { method: "DELETE" });
      router.push("/login?deleted=true");
    } catch (err: any) {
      setError(err.message || "Failed to delete account. Please try again.");
      setDeleting(false);
      setShowDeleteModal(false);
    }
  }

  const initials = displayName
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase();

  return (
    <>
      <div className="profile-page-grid">
        <section className="profile-editor-card">
          <div className="profile-cover">
            <div className="profile-cover-photo" />
            <div
              aria-label={`${displayName}'s profile`}
              className="profile-avatar-large shadow-lg"
              role="img"
              style={user.imageUrl ? { backgroundImage: `url("${user.imageUrl}")` } : undefined}
            >
              {!user.imageUrl && <span>{initials}</span>}
            </div>
          </div>

          <div className="profile-editor-body">
            <div className="profile-name-display">
              <div>
                {editing ? (
                  <div className="profile-edit-fields space-y-3">
                    <label>
                      Display name
                      <input
                        maxLength={80}
                        onChange={(event) => setDisplayName(event.target.value)}
                        required
                        value={displayName}
                      />
                    </label>
                    <label>
                      City
                      <input
                        maxLength={120}
                        onChange={(event) => setCity(event.target.value)}
                        required
                        value={city}
                      />
                    </label>
                    <div className="grid grid-cols-2 gap-3">
                      <label>
                        My Gender
                        <select
                          value={gender}
                          onChange={(e) => setGender(e.target.value)}
                          className="mt-1 w-full p-2 border border-line rounded-lg text-xs"
                        >
                          {genderOptions.map((g) => (
                            <option key={g} value={g}>
                              {g}
                            </option>
                          ))}
                        </select>
                      </label>
                      <label>
                        Looking for
                        <select
                          value={lookingFor}
                          onChange={(e) => setLookingFor(e.target.value)}
                          className="mt-1 w-full p-2 border border-line rounded-lg text-xs"
                        >
                          {lookingForOptions.map((lf) => (
                            <option key={lf} value={lf}>
                              {lf}
                            </option>
                          ))}
                        </select>
                      </label>
                    </div>
                  </div>
                ) : (
                  <>
                    <h2>{displayName}</h2>
                    <span className="flex items-center gap-1.5 text-xs text-muted">
                      <MapPin size={14} className="text-coral" />
                      {city} · {gender} · Looking for {lookingFor}
                    </span>
                  </>
                )}
              </div>
              <button
                className="button button-outline button-small"
                disabled={saving}
                onClick={() => {
                  if (editing) cancelEdit();
                  else {
                    setEditing(true);
                    setError("");
                  }
                }}
                type="button"
              >
                <Edit3 size={14} /> {editing ? "Cancel" : "Edit profile"}
              </button>
            </div>

            <div className="profile-bio-block">
              <span className="eyebrow">A LITTLE ABOUT ME</span>
              {editing ? (
                <textarea
                  maxLength={500}
                  onChange={(event) => setBio(event.target.value)}
                  rows={4}
                  value={bio}
                  placeholder="Share what makes you smile, your favorite city spots, and ideal weekend walks…"
                />
              ) : (
                <p>{bio || "Add a little introduction about yourself."}</p>
              )}
            </div>

            <div className="profile-interests-block">
              <span className="eyebrow">MY PASSIONS & INTERESTS</span>
              <div className="interest-list editable-interests">
                {[...new Set([...availableInterests, ...user.interests])].map((interest) => {
                  const active = selected.includes(interest);
                  return (
                    <button
                      aria-pressed={active}
                      className={active ? "interest-chip selected" : "interest-chip"}
                      disabled={!editing || saving}
                      key={interest}
                      onClick={() => toggleInterest(interest)}
                      type="button"
                    >
                      {active && <Check size={12} />}
                      {interest}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="profile-save-row">
              <span aria-live="polite" role={error ? "alert" : "status"}>
                {error || message || (editing ? "Your updates are saved to your account." : user.email)}
              </span>
              {editing && (
                <button
                  className="button button-coral button-small font-bold shadow"
                  disabled={saving || !displayName.trim() || !city.trim()}
                  onClick={saveProfile}
                  type="button"
                >
                  {saving ? "Saving…" : "Save changes"}
                </button>
              )}
            </div>
          </div>
        </section>

        {/* Aside Privacy & Location Settings */}
        <aside className="profile-sidebar space-y-4">
          <div className="privacy-card">
            <span className="privacy-shield">
              <ShieldCheck size={19} />
            </span>
            <span className="eyebrow">YOUR PRIVACY & SAFETY</span>
            <h2>You control your visibility.</h2>
            <p>
              Your exact coordinates are never shown to other users. Only approximate distance is displayed with your consent.
            </p>

            <div className="privacy-setting">
              <span>Profile Discovery</span>
              <button
                aria-pressed={discoverable}
                className="privacy-toggle"
                disabled={saving}
                onClick={() => {
                  setDiscoverable((current) => !current);
                  setEditing(true);
                  setMessage("");
                }}
                type="button"
              >
                {discoverable ? "On" : "Off"}
              </button>
            </div>

            <div className="privacy-setting">
              <span>Location Radar Consent</span>
              <button
                aria-pressed={locationConsent}
                className="privacy-toggle"
                disabled={saving}
                onClick={() => {
                  setLocationConsent((current) => !current);
                  setEditing(true);
                  setMessage("");
                }}
                type="button"
              >
                {locationConsent ? "On" : "Off"}
              </button>
            </div>

            <div className="privacy-setting">
              <span>Remote Explorer Mode</span>
              <button
                aria-pressed={globalExploreMode}
                className="privacy-toggle"
                disabled={saving}
                onClick={() => {
                  setGlobalExploreMode((current) => !current);
                  setEditing(true);
                  setMessage("");
                }}
                type="button"
              >
                {globalExploreMode ? "On" : "Off"}
              </button>
            </div>

            <div className="mt-3 pt-3 border-t border-line text-xs">
              <span className="font-bold text-ink block mb-1">Discovery Radius</span>
              <select
                value={discoveryRadius}
                onChange={(e) => {
                  setDiscoveryRadius(Number(e.target.value));
                  setEditing(true);
                }}
                className="w-full p-2 border border-line rounded-lg text-xs"
              >
                <option value={250}>250 meters (Walking neighborhood)</option>
                <option value={500}>500 meters (Nearby parks & cafés)</option>
                <option value={1000}>1 kilometer (Local district)</option>
                <option value={5000}>5 kilometers (Citywide)</option>
                <option value={50000}>50 kilometers (Metro region)</option>
              </select>
            </div>
          </div>

          {/* Account Deletion Control (Requirements 2 & 12) */}
          <div className="p-4 bg-red-50/70 border border-red-200 rounded-2xl">
            <span className="text-[10px] font-bold text-red-700 uppercase tracking-wider block mb-1">
              DANGER ZONE
            </span>
            <strong className="text-xs text-ink block">Permanent Account Deletion</strong>
            <p className="text-[11px] text-muted mt-0.5 mb-3 leading-relaxed">
              Permanently delete your profile, messages, matches, and inventory. This cannot be undone.
            </p>
            <button
              type="button"
              onClick={() => setShowDeleteModal(true)}
              className="text-xs font-bold text-red-600 hover:text-red-700 flex items-center gap-1.5"
            >
              <Trash2 size={13} /> Delete My Account…
            </button>
          </div>
        </aside>
      </div>

      {/* Account Deletion Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-white rounded-3xl max-w-sm w-full p-6 text-center shadow-2xl border border-red-100">
            <div className="w-14 h-14 mx-auto rounded-full bg-red-100 text-red-600 flex items-center justify-center mb-3">
              <AlertTriangle size={28} />
            </div>
            <h3 className="text-lg font-bold text-ink">Delete Account Permanently?</h3>
            <p className="text-xs text-muted mt-2 leading-relaxed">
              This action will permanently delete your account, swipe history, mutual matches, chat messages, and collected items.
            </p>

            <div className="mt-5 flex flex-col gap-2">
              <button
                type="button"
                disabled={deleting}
                onClick={handleDeleteAccount}
                className="button bg-red-600 hover:bg-red-700 text-white w-full py-2.5 font-bold text-xs"
              >
                {deleting ? "Deleting Account…" : "Yes, Permanently Delete"}
              </button>
              <button
                type="button"
                onClick={() => setShowDeleteModal(false)}
                className="button button-outline w-full py-2 text-xs font-semibold"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
