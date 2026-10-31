# Pookie Match — AI-Powered Gamified Dating & Real-World Exploration

**Pookie Match** is a premium, production-oriented gamified dating platform that combines Tinder-style matchmaking, Pokémon GO-inspired location exploration, AI compatibility matching, collectible virtual items, interactive mini-games, and privacy-focused live WebRTC communication.

---

## 🌟 What's Inside

1. **Social Discovery Mode (Tinder-Style Matchmaking)**
   - Smooth swipe gestures on mobile touch and desktop mouse drag.
   - Like, Pass, and Mutual-Match detection.
   - Multi-photo carousel galleries.
   - Transparent AI Compatibility index with multidimensional breakdown (Interests, Communication, Lifestyle, Adventure).
   - Personalized conversation icebreakers.
   - Celebratory match confetti animations.
   - Unmatch, block, and report moderation tools.

2. **Adventure Mode (Pokémon GO-Style City Exploration)**
   - Interactive Leaflet & OpenStreetMap location radar.
   - Consent-first GPS access with configurable proximity radius (500m default).
   - Themed virtual collectibles (Virtual Coffee Cup ☕, Golden Heart 💛, Music Note Badge 🎵, Treasure Chest 💎, Adventure Compass 🧭, Lucky Star ⭐).
   - Server-side distance and coordinate validation to prevent client spoofing.
   - Global / Remote Explorer mode for exploring without physical walking.
   - Community-hosted activity drops.

3. **Virtual Collectibles & Inventory**
   - User backpack inventory with rarity levels (Common, Rare, Epic, Legendary).
   - Gifting mechanism: send virtual coffee cups or golden hearts directly inside mutual match chats.
   - Unlockable dating perks and achievements.

4. **In-App Mini-Games Hub**
   - **AI Compatibility Quiz**: Daily 5-question lifestyle vector quiz that dynamically tunes matching scores.
   - **Vibe Check Trivia**: Culture and date trivia with scoring and cosmetic "Vibe Master" badge awards.
   - **Virtual Truth or Dare**: Consent-based, wholesome & romantic text mini-game with skip and report options.
   - **Treasure Race Quest**: Real-world coordinate riddle solving across the city map.

5. **Live Audio & Video Calling**
   - WebRTC encrypted calling exclusively between mutually matched users.
   - Incoming call notification interface with Accept and Decline controls.
   - Microphone mute, camera toggle, and immediate hang-up controls.
   - Romance Glow, Soft Blur, Sepia Dream, and Cyberpunk visual effect filters.

6. **Proximity Alerts & Notification Center**
   - In-app notification center tracking matches, incoming calls, messages, collectible discoveries, and game invites.
   - Read / unread filters and quick mark-all-read actions.

7. **Security, Privacy & Architecture**
   - Minimum age 18 validation with strict UTC date-of-birth checking.
   - Inclusive gender and discovery preferences.
   - Account deletion control with cascading data purge.
   - PostgreSQL database with PostGIS enabled for spatial support.
   - Passwords hashed with bcrypt cost 12.
   - HttpOnly, SameSite cookies for sessions.

---

## 🚀 Running Locally

### Prerequisites
- Node.js 20.19+ and npm.
- PostgreSQL 15+ (Local or managed, e.g. Supabase).

### 1. Start the API Backend
```bash
cd backend
npm ci
# Copy .env.example to .env and set DATABASE_URL to your real PostgreSQL connection string.
npm run db:generate
# After verifying the target database, apply the checked-in migrations if needed:
# npm run db:migrate
npm run dev
```
The API server listens at `http://localhost:8081`. Verify database readiness at `http://localhost:8081/health`.

### 2. Start the Frontend
In another terminal, from the project root:
```bash
npm install
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## 🧪 Testing and Verification

Run the frontend and backend test suites:
```bash
npm test
npm --prefix backend test
```

Run production builds:
```bash
# Frontend Next.js build
npm run build

# Backend API build
npm --prefix backend run build
```

### Deployment configuration

Deploy the Next.js frontend from the repository root on Vercel. Set the server-side
environment variable `ROAMORA_API_URL` to the Render service origin only (for example,
`https://<your-render-service>.onrender.com`, without `/api/v1`). The checked-in
`app/api/v1/[...segments]/route.ts` proxies browser API calls to that service.
Application pages share a catch-all route entry so the deployment stays within
Vercel Hobby's serverless function limit while keeping their existing URL paths.

Deploy the Express API from the `backend` directory on Render. Use
`npm ci && npm run build` as the build command and `npm start` as the start command.
Render supplies `PORT`; configure `DATABASE_URL` with the actual PostgreSQL connection
string, and set `WEB_ORIGIN` to the deployed frontend origin. Do not copy placeholder
credentials or apply migrations until the database target has been verified.
