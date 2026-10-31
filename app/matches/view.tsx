import { MatchesList } from "@/components/matches-list";
import { PageFrame } from "@/components/page-frame";
import { PageHeading } from "@/components/ui";
import { liveApi } from "@/lib/api/live-client";
import type { Match } from "@/types/roamora";

export default async function MatchesView() {
  let people: Match[] = [];
  let currentUserId = "";

  try {
    const [matches, me] = await Promise.all([
      liveApi.listMatches(),
      liveApi.getCurrentUser(),
    ]);
    people = matches;
    currentUserId = me.id;
  } catch {
    people = [];
  }

  return (
    <PageFrame>
      <div className="content-page matches-page">
        <PageHeading
          eyebrow="MUTUAL SPARKS & CONNECTIONS"
          title={
            <>
              Your <em>pookie matches.</em>
            </>
          }
          subtitle="Mutual connections unlocked for live video calling, chat, mini-games, and gift sharing."
          action={{ href: "/discover", label: "Discover people" }}
        />
        <MatchesList people={people} currentUserId={currentUserId} />
      </div>
    </PageFrame>
  );
}
