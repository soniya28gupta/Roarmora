import { PageFrame } from "@/components/page-frame";
import { PageHeading } from "@/components/ui";
import { NotificationsView } from "@/components/notifications-view";
import { liveApi } from "@/lib/api/live-client";
import type { AppNotification } from "@/types/roamora";

export default async function NotificationsPage() {
  let notifications: AppNotification[] = [];

  try {
    const data = await liveApi.listNotifications();
    notifications = data.notifications;
  } catch {
    notifications = [
      {
        id: "demo-notif-1",
        userId: "demo",
        type: "MATCH",
        title: "It's a Mutual Spark! ✨",
        message: "You and Mira Sharma liked each other! Start chatting now.",
        link: "/matches",
        read: false,
        createdAt: new Date().toISOString(),
      },
      {
        id: "demo-notif-2",
        userId: "demo",
        type: "COLLECTIBLE",
        title: "Nearby Item Detected! ☕",
        message: "A Virtual Coffee Cup is located within 150m of Hauz Khas Village.",
        link: "/treasure-map",
        read: false,
        createdAt: new Date(Date.now() - 3600000).toISOString(),
      },
    ];
  }

  return (
    <PageFrame>
      <div className="content-page">
        <PageHeading
          eyebrow="STAY IN SYNC"
          title={
            <>
              Notifications & <em>Proximity Alerts.</em>
            </>
          }
          subtitle="Real-time updates on mutual matches, incoming messages, and nearby discovery events."
          action={{ href: "/profile", label: "Preferences" }}
        />
        <NotificationsView initialNotifications={notifications} />
      </div>
    </PageFrame>
  );
}
