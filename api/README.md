# Pookie Match API

Independent Node.js/Express/TypeScript REST backend for **Pookie Match**.

Handles authentication, profile management, Tinder-style swipe discovery, mutual matching, messages, blocks, reports, Pokémon GO-style drops, virtual collectibles inventory, achievements, AI compatibility quizzes, mini-games, and WebRTC call signaling.

---

## REST Endpoints (v1)

All endpoints reside under `/api/v1` and authenticated routes use the HttpOnly session cookie.

### Authentication & Account
| Method | Path | Description |
|---|---|---|
| GET | `/health` | Database readiness check; reports `status: ok, platform: Pookie Match` |
| POST | `/auth/register` | Register new account (18+ validation, bcrypt hashing) |
| POST | `/auth/login` | Email/password sign-in and session cookie issuance |
| POST | `/auth/logout` | Revoke active session |
| GET | `/me` | Get current user profile, preferences, and stats |
| PATCH | `/profile` | Update display name, city, bio, interests, photos, gender, lookingFor |
| PUT | `/preferences` | Update age range, distance, discovery radius, global explore mode |
| DELETE | `/account` | Permanently delete account and all associated data |

### Tinder-Style Matchmaking
| Method | Path | Description |
|---|---|---|
| GET | `/profiles` | Unswiped discoverable profiles with AI compatibility scoring |
| POST | `/swipes` | Send LIKE or PASS; creates mutual match on mutual like |
| GET | `/matches` | Active mutual matches with chemistry scores and last messages |
| DELETE | `/matches/:matchId` | Unmatch connection |
| POST | `/blocks` | Block user and delete active match |
| POST | `/reports` | Submit safety report for review |

### Adventure Mode & Map
| Method | Path | Description |
|---|---|---|
| GET | `/places` | Curated discovery spots |
| GET | `/drops` | Upcoming community drops with distance filtering |
| POST | `/drops` | Create community drop with location consent |
| POST | `/drops/:dropId/collect` | Collect drop with verified client coordinates |

### Virtual Collectibles & Backpack
| Method | Path | Description |
|---|---|---|
| GET | `/collectibles` | Active collectible items with coordinates and rarity |
| POST | `/collectibles/:itemId/collect` | Server-validated claim within proximity radius |
| GET | `/inventory` | Current user backpack inventory and quantities |
| POST | `/inventory/:itemId/use` | Gift collectible item directly inside a match chat |

### AI Compatibility Matcher & Mini-Games
| Method | Path | Description |
|---|---|---|
| GET | `/quiz/daily` | 5 daily lifestyle vector questions |
| POST | `/quiz/submit` | Save answers to update compatibility algorithm |
| GET | `/compatibility/:targetUserId` | Multidimensional chemistry breakdown & icebreakers |
| GET | `/games` | Active mini-game sessions |
| POST | `/games/start` | Launch Vibe Check, Truth or Dare, or Treasure Race |
| GET | `/games/:sessionId` | Get game state and questions |
| POST | `/games/:sessionId/action` | Submit answer or claim quest clue |

### WebRTC Audio & Video Calling
| Method | Path | Description |
|---|---|---|
| POST | `/calls/initiate` | Initiate call to mutual match with SDP offer |
| GET | `/calls/active` | Check for incoming or active calls |
| POST | `/calls/:callId/answer` | Callee accepts with SDP answer |
| POST | `/calls/:callId/candidate` | Exchange ICE candidate |
| POST | `/calls/:callId/end` | Hang up and record call duration |

### Notifications & Achievements
| Method | Path | Description |
|---|---|---|
| GET | `/notifications` | List user notifications and unread count |
| PATCH | `/notifications/:id/read` | Mark notification read |
| POST | `/notifications/read-all` | Mark all notifications read |
| GET | `/achievements` | List achievements and user unlock status |

---

## Database & Scripts

```bash
# Push schema changes to PostgreSQL
npm run db:generate
npx prisma db push

# Seed demo profiles, items, achievements, and places
npm run db:seed

# Run tests
npm test

# Build TypeScript to dist/
npm run build
```
