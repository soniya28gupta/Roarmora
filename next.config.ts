import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  poweredByHeader: false,
  distDir: process.env.ROAMORA_NEXT_DIST_DIR ?? ".next",
  outputFileTracingRoot: process.cwd(),
};

export default nextConfig;
