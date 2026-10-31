import { notFound } from "next/navigation";
import ChatView from "@/app/chat/view";
import DiscoverView from "@/app/discover/view";
import ExploreView from "@/app/explore/view";
import GamesView from "@/app/games/view";
import InventoryView from "@/app/inventory/view";
import LoginView from "@/app/login/view";
import MatchesView from "@/app/matches/view";
import NotificationsView from "@/app/notifications/view";
import ProfileView from "@/app/profile/view";
import RegisterView from "@/app/register/view";
import TreasureMapView from "@/app/treasure-map/view";

type RoutedPageProps = {
  params: Promise<{ segments: string[] }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

function getSingleQueryValue(
  query: Record<string, string | string[] | undefined>,
  key: string,
): string | undefined {
  const value = query[key];
  return Array.isArray(value) ? value[0] : value;
}

export default async function RoutedPage({ params, searchParams }: RoutedPageProps) {
  const { segments } = await params;
  const route = segments.join("/");

  switch (route) {
    case "chat": {
      const query = await searchParams;
      return <ChatView matchId={getSingleQueryValue(query, "matchId")} />;
    }
    case "discover":
      return <DiscoverView />;
    case "explore":
      return <ExploreView />;
    case "games": {
      const query = await searchParams;
      return <GamesView matchId={getSingleQueryValue(query, "matchId")} />;
    }
    case "inventory":
      return <InventoryView />;
    case "login":
      return <LoginView />;
    case "matches":
      return <MatchesView />;
    case "notifications":
      return <NotificationsView />;
    case "profile":
      return <ProfileView />;
    case "register":
      return <RegisterView />;
    case "treasure-map":
      return <TreasureMapView />;
    default:
      notFound();
  }
}
