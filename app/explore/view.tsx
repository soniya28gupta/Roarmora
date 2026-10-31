import { ArrowUpRight, MapPin } from "lucide-react";
import Link from "next/link";
import { DemoStateSurface } from "@/components/demo-state";
import { ExploreContent } from "@/components/explore-content";
import { PageFrame } from "@/components/page-frame";
import { PageHeading } from "@/components/ui";
import { api } from "@/lib/api";

export default async function ExploreView() {
  const places = await api.listPlaces();
  return (
    <PageFrame>
      <div className="content-page">
        <PageHeading eyebrow="THE CITY IS YOURS" title={<>A little <em>exploring</em><br className="desktop-break" /> goes a long way.</>} subtitle="Small discoveries, good coffee, and corners worth taking the scenic route for." action={{ href: "/treasure-map", label: "Open treasure map" }} />
        <div className="explore-location-note"><span><MapPin size={16} /></span><div><strong>Looking around New Delhi</strong><small>Sample city preview · We never ask for your location</small></div><Link href="/treasure-map" aria-label="Open illustrative map"><ArrowUpRight size={17} /></Link></div>
        <DemoStateSurface emptyTitle="No places on this little list" emptyCopy="Try broadening your search or exploring another category.">
          <ExploreContent places={places} />
        </DemoStateSurface>
      </div>
    </PageFrame>
  );
}
