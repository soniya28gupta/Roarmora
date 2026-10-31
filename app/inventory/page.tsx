import { PageFrame } from "@/components/page-frame";
import { PageHeading } from "@/components/ui";
import { InventoryView } from "@/components/inventory-view";
import { liveApi } from "@/lib/api/live-client";
import { demoAchievements, demoCollectibles } from "@/data/demo";
import type { Achievement, UserInventoryItem } from "@/types/roamora";

export default async function InventoryPage() {
  let inventory: UserInventoryItem[] = [];
  let achievements: Achievement[] = [];
  let totalPoints = 0;

  try {
    const [invData, achData] = await Promise.all([
      liveApi.listInventory(),
      liveApi.listAchievements(),
    ]);
    inventory = invData;
    achievements = achData.achievements;
    totalPoints = achData.totalPoints;
  } catch {
    inventory = demoCollectibles.map((item, idx) => ({
      id: `inv-${idx}`,
      userId: "demo",
      itemId: item.id,
      quantity: 1,
      acquiredAt: new Date().toISOString(),
      item,
    }));
    achievements = demoAchievements;
    totalPoints = 75;
  }

  return (
    <PageFrame>
      <div className="content-page">
        <PageHeading
          eyebrow="VIRTUAL TREASURE CHEST"
          title={
            <>
              Collectibles & <em>Trophies.</em>
            </>
          }
          subtitle="Explore the city radar to claim coffee cups, golden hearts, and exploration badges."
          action={{ href: "/treasure-map", label: "Open Map" }}
        />
        <InventoryView
          inventory={inventory}
          achievements={achievements}
          totalPoints={totalPoints}
        />
      </div>
    </PageFrame>
  );
}
