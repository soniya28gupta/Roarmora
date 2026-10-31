"use client";

import { useState } from "react";
import Link from "next/link";
import {
  Award,
  Compass,
  Gift,
  HelpCircle,
  MapPin,
  MessageCircle,
  Sparkles,
  Trophy,
  Zap,
} from "lucide-react";
import type { Achievement, CollectibleItem, UserInventoryItem } from "@/types/roamora";

interface InventoryViewProps {
  inventory: UserInventoryItem[];
  achievements: Achievement[];
  totalPoints: number;
}

export function InventoryView({
  inventory,
  achievements,
  totalPoints,
}: InventoryViewProps) {
  const [activeTab, setActiveTab] = useState<"items" | "achievements">("items");
  const [selectedItem, setSelectedItem] = useState<CollectibleItem | null>(
    inventory[0]?.item ?? null,
  );

  const getRarityBadge = (rarity: string) => {
    switch (rarity) {
      case "LEGENDARY":
        return "bg-amber-500 text-white";
      case "EPIC":
        return "bg-purple-600 text-white";
      case "RARE":
        return "bg-blue-500 text-white";
      default:
        return "bg-emerald-600 text-white";
    }
  };

  return (
    <div className="inventory-dashboard my-6">
      {/* Top Stats Banner */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <div className="p-5 bg-gradient-to-br from-pink-50 to-rose-50 border border-pink-200/80 rounded-2xl flex items-center gap-4 shadow-sm">
          <div className="w-12 h-12 rounded-2xl bg-coral text-white flex items-center justify-center text-2xl shadow">
            🎒
          </div>
          <div>
            <span className="text-xs font-bold text-coral-dark uppercase tracking-wider block">
              Backpack Items
            </span>
            <strong className="text-2xl font-black text-ink">{inventory.length} Collectibles</strong>
          </div>
        </div>

        <div className="p-5 bg-gradient-to-br from-amber-50 to-yellow-50 border border-amber-200/80 rounded-2xl flex items-center gap-4 shadow-sm">
          <div className="w-12 h-12 rounded-2xl bg-amber-500 text-white flex items-center justify-center text-2xl shadow">
            🏆
          </div>
          <div>
            <span className="text-xs font-bold text-amber-800 uppercase tracking-wider block">
              Exploration Badges
            </span>
            <strong className="text-2xl font-black text-ink">
              {achievements.filter((a) => a.unlocked).length} / {achievements.length} Unlocked
            </strong>
          </div>
        </div>

        <div className="p-5 bg-gradient-to-br from-purple-50 to-indigo-50 border border-purple-200/80 rounded-2xl flex items-center gap-4 shadow-sm">
          <div className="w-12 h-12 rounded-2xl bg-purple-600 text-white flex items-center justify-center text-2xl shadow">
            ⭐
          </div>
          <div>
            <span className="text-xs font-bold text-purple-800 uppercase tracking-wider block">
              Exploration Score
            </span>
            <strong className="text-2xl font-black text-ink">{totalPoints} Points</strong>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-3 border-b border-line pb-3 mb-6">
        <button
          type="button"
          onClick={() => setActiveTab("items")}
          className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-xs transition-all ${
            activeTab === "items"
              ? "bg-coral text-white shadow"
              : "bg-gray-100 text-ink hover:bg-gray-200"
          }`}
        >
          <Gift size={16} /> My Collectibles ({inventory.length})
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("achievements")}
          className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-xs transition-all ${
            activeTab === "achievements"
              ? "bg-coral text-white shadow"
              : "bg-gray-100 text-ink hover:bg-gray-200"
          }`}
        >
          <Trophy size={16} /> Achievements & Badges
        </button>
      </div>

      {/* Items Tab */}
      {activeTab === "items" && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            {inventory.length === 0 ? (
              <div className="bg-white rounded-3xl p-8 border border-pink-100 shadow-sm text-center">
                <div className="w-16 h-16 rounded-full bg-pink-50 text-coral flex items-center justify-center text-3xl mx-auto mb-3 shadow-inner">
                  ☕
                </div>
                <h3 className="text-lg font-bold text-ink">No collectibles yet</h3>
                <p className="text-xs text-muted max-w-sm mx-auto mt-1 mb-5">
                  Walk near designated city coordinates on the Adventure Map to discover Virtual Coffee Cups, Golden Hearts, and Mystery Chests!
                </p>
                <Link href="/treasure-map" className="button button-coral py-2.5 px-6 font-bold text-xs shadow">
                  <Compass size={15} /> Open Adventure Map
                </Link>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {inventory.map((inv) => (
                  <div
                    key={inv.id}
                    onClick={() => setSelectedItem(inv.item)}
                    className={`p-4 rounded-2xl border cursor-pointer transition-all ${
                      selectedItem?.id === inv.item.id
                        ? "bg-pink-50/70 border-coral shadow-md"
                        : "bg-white border-pink-100/80 hover:border-pink-300 shadow-sm"
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <span className="text-3xl p-2 bg-pink-50 rounded-2xl border border-pink-100 inline-block">
                        {inv.item.icon}
                      </span>
                      <span
                        className={`text-[9px] font-black uppercase px-2 py-0.5 rounded-full ${getRarityBadge(
                          inv.item.rarity,
                        )}`}
                      >
                        {inv.item.rarity}
                      </span>
                    </div>

                    <h4 className="font-bold text-sm text-ink mt-3">{inv.item.name}</h4>
                    <p className="text-xs text-muted line-clamp-2 mt-1">
                      {inv.item.description}
                    </p>

                    <div className="mt-3 pt-2.5 border-t border-pink-100/60 flex items-center justify-between text-[11px]">
                      <span className="font-bold text-coral-dark">Quantity: x{inv.quantity}</span>
                      <span className="text-gray-400">
                        {new Date(inv.acquiredAt).toLocaleDateString([], { month: "short", day: "numeric" })}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Item details card */}
          <div className="bg-white rounded-3xl p-6 border border-pink-100 shadow-sm h-fit">
            {selectedItem ? (
              <div>
                <span
                  className={`text-[9px] font-black uppercase px-2 py-0.5 rounded-full inline-block mb-3 ${getRarityBadge(
                    selectedItem.rarity,
                  )}`}
                >
                  {selectedItem.rarity} VIRTUAL REWARD
                </span>

                <div className="w-20 h-20 mx-auto rounded-3xl bg-pink-50 flex items-center justify-center text-4xl shadow-inner border border-pink-200 mb-3">
                  {selectedItem.icon}
                </div>

                <h3 className="font-bold text-lg text-ink text-center">{selectedItem.name}</h3>
                <p className="text-xs text-muted text-center mt-1 leading-relaxed">
                  {selectedItem.description}
                </p>

                {selectedItem.perkDescription && (
                  <div className="my-4 p-3 bg-amber-50/80 border border-amber-200 rounded-xl text-xs">
                    <span className="font-bold text-amber-900 block mb-0.5">Special Perk:</span>
                    <span className="text-amber-800">{selectedItem.perkDescription}</span>
                  </div>
                )}

                <div className="mt-4 pt-3 border-t border-gray-100 text-xs text-muted space-y-1">
                  <div>
                    <strong>Category:</strong> {selectedItem.category}
                  </div>
                  <div>
                    <strong>Usage:</strong> Giftable in active match chats to trigger custom animations and icebreakers.
                  </div>
                </div>

                <Link
                  href="/matches"
                  className="button button-coral w-full py-2.5 text-xs font-bold mt-5 shadow"
                >
                  <MessageCircle size={15} /> Gift to a Match
                </Link>
              </div>
            ) : (
              <div className="text-center py-8 text-xs text-muted">
                Select an item to view its rarity and special dating perks.
              </div>
            )}
          </div>
        </div>
      )}

      {/* Achievements Tab */}
      {activeTab === "achievements" && (
        <div className="bg-white rounded-3xl p-6 sm:p-8 border border-pink-100 shadow-md">
          <div className="mb-6">
            <h3 className="text-lg font-bold text-ink">Exploration & Romance Badges</h3>
            <p className="text-xs text-muted mt-1">
              Complete milestones by exploring coordinates, connecting with matches, and answering quizzes.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {achievements.map((ach) => (
              <div
                key={ach.id}
                className={`p-4 rounded-2xl border transition-all ${
                  ach.unlocked
                    ? "bg-gradient-to-tr from-pink-50/50 to-white border-pink-200 shadow-sm"
                    : "bg-gray-50 border-gray-200 opacity-60"
                }`}
              >
                <div className="flex items-start justify-between">
                  <div
                    className="w-11 h-11 rounded-2xl flex items-center justify-center text-2xl shadow-sm border"
                    style={{
                      borderColor: ach.badgeColor,
                      backgroundColor: ach.unlocked ? `${ach.badgeColor}15` : "#f3f4f6",
                    }}
                  >
                    {ach.icon}
                  </div>
                  <span
                    className="text-[10px] font-bold px-2 py-0.5 rounded-full"
                    style={{
                      backgroundColor: ach.unlocked ? `${ach.badgeColor}20` : "#e5e7eb",
                      color: ach.unlocked ? ach.badgeColor : "#6b7280",
                    }}
                  >
                    +{ach.points} pts
                  </span>
                </div>

                <h4 className="font-bold text-sm text-ink mt-3">{ach.title}</h4>
                <p className="text-xs text-muted mt-1 leading-relaxed">{ach.description}</p>

                <div className="mt-3 pt-2 border-t border-gray-100 flex items-center justify-between text-[10px] font-bold">
                  <span className="uppercase text-gray-400">{ach.category}</span>
                  <span className={ach.unlocked ? "text-green-600" : "text-gray-400"}>
                    {ach.unlocked ? "✓ Unlocked" : "Locked"}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

