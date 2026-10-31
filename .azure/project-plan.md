# Project Plan

**Status**: In Progress
**Created**: 2026-10-31
**Mode**: NEW

---

## 1. Project Overview

**Goal**: Build Roamora, a welcoming dating and local-exploration web app. Phase 1 is a polished, responsive Next.js frontend using clearly labeled sample data for onboarding, discovery, exploration drops, profiles, matches, and chat previews; it does not use a backend, database, or live GPS. Later phases add the API and persistence, consent-based GPS drops, mutual-interest matching, and private chat in that order. Keep the modules independently testable.

**App Type**: SPA + API

**API Login**: Yes

**Mode**: NEW

**Deployment Plan**: No deployment plan found

---

## 2. Roamora API — Backend (later phase)

| Component | Technology |
|-----------|-----------|
| **Language** | TypeScript |
| **Runtime** | Node.js |
| **Package Manager** | npm |
| **Framework** | Express.js |
| **Test Runner** | Vitest |
| **Mocking Library** | vi.mock |
| **Test Command** | npm test |
| **Orchestration** | docker-compose |

This service follows the frontend phase. Introduce account and profile capabilities first, then persisted drops and opt-in location discovery, mutual matching, and private chat. Use PostgreSQL with PostGIS and Prisma migrations. Require explicit location consent, minimize precision and retention, and provide blocking and reporting controls before enabling location-based social features.

---

## 3. Roamora Web — Frontend

| Component | Technology |
|-----------|-----------|
| **Language** | TypeScript |
| **Framework** | Next.js (App Router) |
| **Styling** | Tailwind CSS |
| **Package Manager** | npm |
| **Test Runner** | vitest |
| **Mocking Library** | vi.mock |
| **Test Command** | npm test |

Phase 1 is frontend-first: responsive login and registration screens, swipeable profile cards, Discover and Explore pages, a treasure-map interface, and demo Matches and Chat screens. Keep mock content behind replaceable typed data modules. Clearly label seeded/demo content. Do not request device location or imply that sample people, drops, matches, or places are live. Matching and chat interactions remain demo-only until their backend phases.

---

## 4. Services Required

| Azure Service | Role in App | Environment Variable | Default Value (Local) | Classification |
|---------------|------------|---------------------|----------------------|----------------|
| Azure Static Web Apps | Host the Phase 1 Next.js frontend | — | Next.js local dev server | Essential |
| Azure Container Apps | Host the Express API in a later phase | PORT | 8080 | Essential |
| PostgreSQL Flexible Server | Persist accounts, profiles, preferences, drops, matches, and chat data in later phases | DATABASE_URL | postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/roamora | Essential |
| Blob Storage | Store user-selected profile and drop media in later phases | STORAGE_CONNECTION_STRING | UseDevelopmentStorage=true | Essential |

Phase 1 uses local, clearly identified sample data and requires no Azure database or storage connection. Add these data services only when the corresponding later-phase features are implemented.

---

## 5. Prerequisites

### Run

| Tool | Service(s) | Installed | Version |
|------|------------|-----------|---------|
| Node.js | frontend | ✅ | 20.19.0 |
| npm | frontend | ✅ | 10.8.2 |
| PostgreSQL with PostGIS | backend (later phase) | ❓ | Unknown |

### Debug

| Tool | Service(s) | Installed | Version |
|------|------------|-----------|---------|
| Docker | backend and data-store emulators (later phase) | ❓ | Unknown |
| Docker Compose | backend and data-store emulators (later phase) | ❓ | Unknown |
| Google Chrome | frontend | ✅ | 156.0.8078.76 |

Double-check and install any tools marked ❓ before using the later-phase backend or local data-store emulators.

---

## 6. Design System & UI

**Component Library**: Reusable React components styled with Tailwind CSS
**Style Direction**: A crisp white, editorial exploration journal with coral-pink accents, generous spacing, softly rounded surfaces, and photo-led destination cards. Keep the dating context respectful and calm rather than gamified; use clear privacy cues and make sample content visibly illustrative.
**Typography**: Inter, system-ui

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#F06B72` | Roamora brand, primary actions, selected discovery filters |
| `accent` | `#F06B72` | Drop highlights, heart/connection accents, and key calls to action |
| `surface` | `#FFFFFF` | White page background behind discovery and profile content |
| `text` | `#292536` | Primary headings, place names, profile details |
| `muted` | `#777182` | Distance captions, timing, secondary labels |
| `border` | `#E9E0E2` | Quiet dividers, card outlines, and form boundaries |

### Pages

| Page | Route | Purpose | Layout |
|------|-------|---------|--------|
| Discover | `/` | Introduce Roamora's sample nearby places and community drops | `header, nav, hero, card-list, actions, footer` |
| Explore | `/explore` | Browse curated places and activity suggestions without live location | `header, nav, tabs, grid, card-list, footer` |
| Treasure Map | `/treasure-map` | Preview illustrative treasure drops on a map-like interface without live GPS | `header, nav, map, drop-markers, detail-card` |
| Matches | `/matches` | Preview demo matches and connection states | `header, nav, list, profile-cards, footer` |
| Chat | `/chat` | Preview a demo conversation with sample messages | `header, nav, conversation, composer, footer` |
| Login | `/login` | Present a responsive sign-in form without a live auth service | `header, form, actions, footer` |
| Registration | `/register` | Present an account creation form without a live auth service | `header, form, actions, footer` |
| Profile | `/profile` | Present a demo profile, interests, and privacy-first product cues | `header, nav, two-column(media+meta), tabs, actions, footer` |

### Sample Content

Discover — place and drop:
| Name | Area | Distance | Detail |
|------|------|----------|--------|
| The Reading Room | Hauz Khas Village | 1.2 km | Quiet tables and a courtyard |
| Sunder Nursery | Nizamuddin | 3.8 km | Garden paths and weekend walks |
| Sunday sketch walk | Lodhi Garden | Today, 4:30 PM | 4 demo spots |

Explore — destination:
| Place | Category | Suggested plan | State |
|-------|----------|----------------|-------|
| Lodhi Garden | Outdoors | Slow loop past the tombs · 2.4 km | Curated |
| Champa Gali | Cafés | Coffee and independent shops · 5.1 km | Curated |
| National Crafts Museum | Culture | Galleries and tea break · 6.0 km | Curated |

Drops — illustrative activity:
| Drop | Host | When | Interest |
|------|------|------|----------|
| Chai & book swap | Mira S. | Today · 5:00 PM | Books |
| Golden-hour photo walk | Aarav K. | Saturday · 4:45 PM | Photography |
| Sunday sketch walk | Naina R. | Sunday · 10:00 AM | Art |

Profile — demo profile:
| Name | Age | Base | Interests |
|------|-----|------|-----------|
| Mira S. | 28 | New Delhi | Coffee, bookstores, city walks |
| Profile note | — | — | “Always up for a new neighborhood.” |
| Privacy cue | — | — | Sample profile only; no live location shared |

Profile defaults: Discovery interests: Cafés · Outdoors · Art · Books; location access: Off; matching and chat: Coming in later phases.

---

## 7. Project Structure

```text
roamora/
├── app/                          # Next.js App Router routes and layouts
├── components/                   # Reusable Tailwind-styled UI
├── data/                         # Replaceable typed sample-data modules
├── public/                       # Static assets
├── package.json
├── api/                          # Node.js + Express + Prisma API
│   ├── src/
│   ├── prisma/
│   └── tests/
├── infra/                        # Later phase: Azure deployment definitions
└── .azure/
    ├── requirements.json
    └── project-plan.md
```

---

## 8. Route Definitions

The Phase 1 frontend routes use sample data only and remain unconnected to the standalone API. The API route implementation is documented in [`api/README.md`](../api/README.md); database-backed operations require a configured PostgreSQL/PostGIS service.

| Page | Path | Phase 1 behavior |
|------|------|------------------|
| Landing / Discover | `/` | Responsive introduction and sample discovery cards |
| Login | `/login` | Demo form UI; no authentication |
| Registration | `/register` | Demo form UI; no account creation |
| Discover | `/discover` | Swipeable sample profile cards |
| Explore | `/explore` | Curated sample places and activities |
| Treasure Map | `/treasure-map` | Illustrative drop map; no device location |
| Matches | `/matches` | Sample match list; no mutual matching |
| Chat | `/chat` | Sample conversation; no message delivery |
| Profile | `/profile` | Demo profile and interests |

Backend routes use the `/api/v1` prefix for account, profile, preferences, discovery, swipes, matches, places, drops, messages, blocks, and reports. The health endpoint is `/health`. The frontend continues to use demo content until API client integration is implemented.

---

## 9. Next Steps

1. Phase 1 frontend scaffold is implemented and uses clearly labeled sample data.
2. A standalone Express API, Prisma schema, and PostGIS migration are implemented under `api/`; configure PostgreSQL/PostGIS and run integration tests before relying on database operations.
3. Connect the web client to the API, then add email verification/password recovery, media storage, trusted device-location integration, real-time message delivery, push notifications, and moderation/admin workflows.
4. Run **azure-debug-plan** → **azure-debug-generate** when local backend and data-store emulators are introduced.
5. Run the **azure-deploy** agent when ready for Azure architecture, cost estimation, IaC generation, provisioning, and health verification.
