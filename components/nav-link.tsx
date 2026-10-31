"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Compass, Heart, MapPinned, MessageCircle, UserRound } from "lucide-react";
import type { ReactNode } from "react";

const icons = {
  discover: Heart,
  explore: Compass,
  map: MapPinned,
  matches: MessageCircle,
  profile: UserRound,
} as const;

export function NavLink({
  href,
  children,
  icon,
  count,
}: {
  href: string;
  children: ReactNode;
  icon: keyof typeof icons;
  count?: string;
}) {
  const pathname = usePathname();
  const active = href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(`${href}/`);
  const Icon = icons[icon];
  return (
    <Link aria-current={active ? "page" : undefined} className={active ? "side-link is-active" : "side-link"} href={href}>
      <Icon size={18} strokeWidth={1.8} /><span>{children}</span>
      {count && <span className="nav-count">{count}</span>}
    </Link>
  );
}
