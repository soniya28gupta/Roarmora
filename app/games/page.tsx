import { PageFrame } from "@/components/page-frame";
import { PageHeading } from "@/components/ui";
import { GamesHub } from "@/components/games-hub";

export default async function GamesPage({
  searchParams,
}: {
  searchParams: Promise<{ matchId?: string }>;
}) {
  const { matchId } = await searchParams;
  return (
    <PageFrame>
      <div className="content-page">
        <PageHeading
          eyebrow="PLAYFUL CONNECTIONS"
          title={
            <>
              Mini-Games & <em>Vibe Checks.</em>
            </>
          }
          subtitle="Test chemistry, solve city treasure race clues, and explore fun romantic trivia."
          action={{ href: "/matches", label: "View matches" }}
        />
        <GamesHub matchId={matchId} />
      </div>
    </PageFrame>
  );
}

