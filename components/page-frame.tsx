import type { ReactNode } from "react";
import { SiteShell } from "@/components/site-shell";

export function PageFrame({ children, protectedPage = true }: { children: ReactNode; protectedPage?: boolean }) {
  return <SiteShell protectedPage={protectedPage}>{children}</SiteShell>;
}
