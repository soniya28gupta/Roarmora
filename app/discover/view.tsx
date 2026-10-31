import { PageFrame } from "@/components/page-frame";
import { SwipeDeck } from "@/components/swipe-deck";
import { PageHeading } from "@/components/ui";
import { liveApi } from "@/lib/api/live-client";

export default async function DiscoverView() {
  const people = await liveApi.listProfiles();
  return (
    <PageFrame>
      <div className="content-page">
        <PageHeading
          eyebrow="SOCIAL DISCOVERY MODE"
          title={
            <>
              Find your <em>pookie</em> match.
            </>
          }
          subtitle="Swipe right to express interest. Transparent AI compatibility scoring shows exactly why you align."
          action={{ href: "/treasure-map", label: "Open Radar Map" }}
        />
        <SwipeDeck people={people} />
      </div>
    </PageFrame>
  );
}
