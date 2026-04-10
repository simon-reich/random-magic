# External Integrations

**Analysis Date:** 2026-04-10

## APIs & External Services

**Card Data:**
- Scryfall REST API - Sole external data source; provides random card fetching with filter support
  - SDK/Client: `dio` 5.9.2 via `ScryfallApiClient` in `lib/features/card_discovery/data/scryfall_api_client.dart`
  - Auth: None required
  - Base URL: `https://api.scryfall.com` (defined in `lib/core/constants/api_constants.dart`)
  - Rate limit: 10 req/s max (enforced by Scryfall server-side; no client-side throttling implemented yet)
  - User-Agent: `RandomMagicApp/1.0` (sent on every request via Dio `BaseOptions`)
  - Endpoint used: `GET /cards/random?q=<query>`
  - Error codes handled: 404 → `CardNotFoundFailure`, 422 → `InvalidQueryFailure`, network/timeout → `NetworkFailure`
  - All failures are typed via the sealed `AppFailure` hierarchy in `lib/shared/failures.dart`

**Image CDN:**
- Scryfall image CDN - Card images at multiple resolutions (`small`, `normal`, `large`, `png`, `art_crop`, `border_crop`)
  - SDK/Client: `cached_network_image` 3.4.1 (image URLs are fields on `MagicCard.imageUris`)
  - Auth: None required
  - URLs are embedded in card JSON responses; no separate CDN API call needed

## Data Storage

**Databases:**
- Hive CE (local, on-device) - Stores favourites and filter presets
  - Package: `hive_ce` 2.19.3 + `hive_ce_flutter` 2.3.4
  - Connection: No connection string; Hive CE opens box files in the app's documents directory
  - Schema changes require a migration strategy note (type adapter version bump)
  - Relevant feature directories: `lib/features/favourites/data/` and `lib/features/filters/data/`

**File Storage:**
- Local filesystem only (via Hive CE box files); no cloud file storage service

**Caching:**
- Network image cache via `cached_network_image` (disk + memory)
- No explicit API response caching; each swipe triggers a fresh Scryfall request

## Authentication & Identity

**Auth Provider:**
- None — Scryfall requires no authentication
- No user accounts, sessions, or identity management in the app

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Crashlytics, or similar service integrated

**Logs:**
- No structured logging library; errors surface as typed `AppFailure` values propagated via `Result<T>` to the UI layer

## CI/CD & Deployment

**Hosting:**
- No server hosting; app is distributed as a native mobile binary
- Target stores: iOS App Store and Google Play (not yet configured for release builds)

**CI Pipeline:**
- GitHub Actions — `.github/workflows/ci.yml`
- Runs `flutter analyze --fatal-infos`, `flutter test`, and `flutter build apk --debug` on every push/PR to `main`
- Uses `subosito/flutter-action@v2` with `channel: stable` and caching enabled

## Environment Configuration

**Required env vars:**
- None — all configuration is compile-time constants; no secrets required

**Secrets location:**
- No secrets; Scryfall API is public and unauthenticated

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None; app only makes outbound GET requests to Scryfall

## Scryfall Query Integration

**Query Building:**
- Filter queries are assembled in `lib/features/filters/data/` via `ScryfallQueryBuilder` (planned; not yet implemented)
- Query syntax: `color:W/U/B/R/G/C/m`, `type:Creature/Instant/...`, `rarity:common/uncommon/rare/mythic`, `date>=YYYY-MM-DD`, `date<=YYYY-MM-DD`
- Multiple values joined with ` OR ` (e.g. `color:R OR color:G`)
- Empty/null query omits the `q` parameter entirely — Scryfall returns a fully unrestricted random card

**Error Response Mapping** (implemented in `lib/features/card_discovery/data/scryfall_api_client.dart`):

| HTTP Status | Typed Failure | UI Expectation |
|---|---|---|
| 404 | `CardNotFoundFailure` | "No cards found" empty state |
| 422 | `InvalidQueryFailure` | "Invalid filter settings" error + reset prompt |
| Timeout/network | `NetworkFailure` | "Could not reach Scryfall" + retry button |

---

*Integration audit: 2026-04-10*
