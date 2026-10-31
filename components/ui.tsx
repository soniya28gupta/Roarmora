import Link from "next/link";
import type { ReactNode } from "react";
import { ArrowUpRight, MapPin } from "lucide-react";

export function Eyebrow({ children, dot = false }: { children: ReactNode; dot?: boolean }) {
  return <div className="eyebrow">{dot && <span className="eyebrow-dot" />}{children}</div>;
}

export function PageHeading({
  eyebrow,
  title,
  subtitle,
  action,
}: {
  eyebrow: string;
  title: ReactNode;
  subtitle: string;
  action?: { href: string; label: string };
}) {
  return (
    <div className="page-heading">
      <div>
        <Eyebrow dot>{eyebrow}</Eyebrow>
        <h1>{title}</h1>
        <p>{subtitle}</p>
      </div>
      {action && <Link className="text-link heading-action" href={action.href}>{action.label}<ArrowUpRight size={16} /></Link>}
    </div>
  );
}

export function Photo({
  src,
  alt,
  className = "",
}: {
  src: string;
  alt: string;
  className?: string;
}) {
  return (
    <div
      aria-label={alt}
      className={`photo ${className}`}
      role="img"
      style={{ backgroundImage: `linear-gradient(180deg, rgba(28, 22, 30, 0) 48%, rgba(28, 22, 30, .35) 100%), url("${src}")` }}
    />
  );
}

export function PlaceCard({
  place,
}: {
  place: {
    id: string;
    name: string;
    category: string;
    neighborhood: string;
    description: string;
    distance: string;
    image: string;
    tag: string;
  };
}) {
  return (
    <article className="place-card">
      <Link aria-label={`Explore ${place.name}`} className="place-image-link" href="/explore">
        <Photo alt={place.name} className="place-photo" src={place.image} />
        <span className="place-tag">{place.tag}</span>
      </Link>
      <div className="place-card-body">
        <div className="place-card-meta"><span>{place.category}</span><span>{place.distance}</span></div>
        <h3>{place.name}</h3>
        <div className="place-neighborhood"><MapPin size={13} />{place.neighborhood}</div>
        <p>{place.description}</p>
      </div>
    </article>
  );
}

export function SectionTitle({
  title,
  link,
}: {
  title: string;
  link?: { href: string; label: string };
}) {
  return (
    <div className="section-title">
      <h2>{title}</h2>
      {link && <Link className="text-link" href={link.href}>{link.label}<ArrowUpRight size={15} /></Link>}
    </div>
  );
}
