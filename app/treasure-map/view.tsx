import { Compass, MapPinned, Radio, Sparkles } from "lucide-react";
import { DemoStateSurface } from "@/components/demo-state";
import { MapView } from "@/components/map-view";
import { PageFrame } from "@/components/page-frame";
import { PageHeading } from "@/components/ui";
import { liveApi } from "@/lib/api/live-client";
import { demoCollectibles, drops as sampleDrops } from "@/data/demo";
import type { CollectibleItem, Drop } from "@/types/roamora";

export default async function TreasureMapView() {
  let drops: Drop[] = [];
  let collectibles: CollectibleItem[] = [];

  try {
    const [dropsData, collData] = await Promise.all([
      liveApi.listDrops(),
      liveApi.listCollectibles(),
    ]);
    drops = dropsData;
    collectibles = collData;
  } catch {
    drops = sampleDrops;
    collectibles = demoCollectibles;
  }

  return (
    <PageFrame>
      <div className="content-page map-page">
        <PageHeading
          eyebrow="ADVENTURE MODE & REAL-WORLD EXPLORATION"
          title={
            <>
              Explore the Map & <em>Claim Drops.</em>
            </>
          }
          subtitle="Discover nearby virtual items, coffee invitations, and spontaneous community meetups in your city."
          action={{ href: "/inventory", label: "My Backpack" }}
        />

        <div className="p-4 bg-gradient-to-r from-pink-50 via-rose-50 to-amber-50 border border-pink-200 rounded-2xl flex items-center justify-between gap-4 text-xs mb-4">
          <div className="flex items-center gap-3">
            <span className="p-2 bg-coral text-white rounded-xl shadow">
              <Compass size={18} />
            </span>
            <div>
              <strong className="text-ink block">Interactive Location Radar</strong>
              <p className="text-muted text-[11px]">
                Consent-first GPS proximity discovery. Enable Remote Mode if exploring from afar.
              </p>
            </div>
          </div>
          <span className="text-coral-dark font-bold shrink-0 hidden sm:inline">
            500m Discovery Radius
          </span>
        </div>

        <MapView items={drops} collectibles={collectibles} />
      </div>
    </PageFrame>
  );
}
