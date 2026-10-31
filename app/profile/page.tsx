import { PageFrame } from "@/components/page-frame";
import { ProfileEditor } from "@/components/profile-editor";
import { PageHeading } from "@/components/ui";
import { liveApi } from "@/lib/api/live-client";

export default async function ProfilePage() {
  const user = await liveApi.getCurrentUser();
  return (
    <PageFrame>
      <div className="content-page profile-page">
        <PageHeading eyebrow="A LITTLE BIT OF YOU" title={<>Make it <em>your own.</em></>} subtitle="Manage your profile and decide what you want to share." action={{ href: "/discover", label: "Discover people" }} />
        <ProfileEditor user={user} />
      </div>
    </PageFrame>
  );
}
