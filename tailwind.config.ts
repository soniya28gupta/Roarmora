import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        coral: "#F06B72",
        ink: "#292536",
        muted: "#777182",
        line: "#E9E0E2",
        blush: "#FFF4F3",
      },
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
      },
      boxShadow: {
        soft: "0 16px 42px rgba(41, 37, 54, 0.08)",
      },
    },
  },
  plugins: [],
};

export default config;
