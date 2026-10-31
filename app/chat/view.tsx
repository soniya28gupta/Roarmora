import Link from "next/link";
import { MessageCircle } from "lucide-react";
import { ChatThread } from "@/components/chat-thread";
import { PageFrame } from "@/components/page-frame";
import { PageHeading } from "@/components/ui";
import { liveApi } from "@/lib/api/live-client";
import type { AccountProfile, ChatMessage, Match } from "@/types/roamora";

export default async function ChatView({ matchId }: { matchId?: string }) {
  let people: Match[] = [];
  let user: AccountProfile | null = null;
  let messages: ChatMessage[] = [];

  try {
    const [matches, me] = await Promise.all([
      liveApi.listMatches(),
      liveApi.getCurrentUser(),
    ]);
    people = matches;
    user = me;
    const person = people.find((match) => match.id === matchId);
    if (person && user) {
      messages = await liveApi.listMessages(person.id, user.id);
    }
  } catch {
    // If not authenticated or error
  }

  const person = people.find((match) => match.id === matchId);

  return (
    <PageFrame>
      <div className="content-page chat-page">
        <PageHeading
          eyebrow="PRIVATE & ENCRYPTED CHAT"
          title={
            <>
              Connect with your <em>match.</em>
            </>
          }
          subtitle="Real-time messaging, WebRTC video calling, mini-games, and virtual gift exchanges."
          action={{ href: "/matches", label: "Back to matches" }}
        />
        {person && user ? (
          <ChatThread
            currentUserId={user.id}
            initialMessages={messages}
            person={person}
          />
        ) : (
          <div className="state-card state-empty">
            <MessageCircle size={22} className="text-coral mx-auto mb-2" />
            <h2>Choose a mutual match to chat</h2>
            <p>
              Select a connection from your Matches page. Private messaging and live calling are exclusively unlocked after mutual likes.
            </p>
            <Link className="button button-coral mt-4 py-2.5 px-6 font-bold text-xs" href="/matches">
              View Matches
            </Link>
          </div>
        )}
      </div>
    </PageFrame>
  );
}
