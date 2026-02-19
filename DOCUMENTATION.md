# TrustProbe AI — Technical Documentation

> In-depth technical reference for the TrustProbe AI project. For a quick overview and setup guide, see [README.md](README.md).

---

## Table of Contents

- [1. System Overview](#1-system-overview)
- [2. Architecture Deep Dive](#2-architecture-deep-dive)
- [3. Service Layer Reference](#3-service-layer-reference)
- [4. Data Models](#4-data-models)
- [5. UI Components](#5-ui-components)
- [6. Detection Algorithm — Full Specification](#6-detection-algorithm--full-specification)
- [7. AI Integration (Llama 3.3 70B)](#7-ai-integration-llama-33-70b)
- [8. Device Identity & Data Ownership](#8-device-identity--data-ownership)
- [9. Firebase Firestore Schema](#9-firebase-firestore-schema)
- [10. Dependency Injection & Service Locator](#10-dependency-injection--service-locator)
- [11. Configuration Reference](#11-configuration-reference)
- [12. Error Handling & Graceful Degradation](#12-error-handling--graceful-degradation)
- [13. Security Considerations](#13-security-considerations)
- [14. Future Roadmap](#14-future-roadmap)
- [15. Troubleshooting](#15-troubleshooting)

---

## 1. System Overview

TrustProbe AI is a Flutter Web application that detects phishing URLs using a **hybrid two-stage engine**:

1. **Stage 1 — Heuristic Analysis**: A rule-based engine evaluates 12 risk factors (suspicious keywords, IP detection, brand impersonation, etc.) and produces a cumulative risk score (0–100%).
2. **Stage 2 — AI Threat Analysis**: The Llama 3.3 70B model (via Groq API) provides an in-depth threat narrative, risk factors, confidence level, and actionable recommendations.

The AI stage is **optional and non-blocking** — the app functions fully with heuristics alone if the Groq API key is not configured.

### Data Flow

```
User enters URL
       |
       v
+-------------------+
|  HomeViewModel     |  <-- Orchestrates services
+-------------------+
       |
       v
+-------------------+     +---------------+
| PhishingService   | --> |   AiService   |  (optional)
| (Heuristic Engine)|     | (Llama 3.3)   |
+-------------------+     +---------------+
       |
       v
+-------------------+
| ScanResult model  |  <-- Heuristic score + AI analysis + deviceId
+-------------------+
       |
       +--------+--------+
       |                  |
       v                  v
+-------------+   +------------------+
| ResultCard  |   | FirestoreService |
| (Display)   |   | (Persist)        |
+-------------+   +------------------+
```

---

## 2. Architecture Deep Dive

### Pattern: Stacked MVVM

TrustProbe AI uses the [Stacked](https://pub.dev/packages/stacked) framework, which implements MVVM (Model-View-ViewModel) with:

- **Reactive ViewModels** — Extend `BaseViewModel` and call `notifyListeners()` to trigger UI rebuilds.
- **Service Locator** — Uses `get_it` under the hood for dependency injection.
- **Code Generation** — Routes and locator registrations can be auto-generated from `app.dart`.

### Layer Separation

| Layer | Files | Rule |
|-------|-------|------|
| **View** | `home_view.dart`, `result_card.dart`, `search_history_table.dart` | No business logic. Only UI rendering and event forwarding to ViewModel. |
| **ViewModel** | `home_viewmodel.dart` | State management. Orchestrates services. No direct UI imports. |
| **Service** | `phishing_service.dart`, `ai_service.dart`, `firestore_service.dart`, `device_id_service.dart` | Single-responsibility units. No Flutter UI dependencies. |
| **Model** | `scan_result.dart` | Pure data classes with serialization. No side effects. |
| **Config** | `ai_config.dart` | Static constants. No runtime state. |

---

## 3. Service Layer Reference

### 3.1 PhishingService

**File:** `lib/services/phishing_service.dart` (419 lines)

The core detection engine. Orchestrates both heuristic and AI analysis.

**Key methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `analyzeUrl` | `Future<ScanResult> analyzeUrl(String url)` | Entry point. Normalizes URL, runs heuristics, optionally runs AI, returns `ScanResult`. |
| `_calculateRiskScore` | `(int, Map<String, int>) _calculateRiskScore(Uri url)` | Evaluates all 12 risk checks. Returns `(totalScore, breakdown)` using Dart record syntax. |
| `_getClassification` | `String _getClassification(int riskScore)` | Maps score to Safe/Suspicious/Malicious using switch expression. |
| `_generateReason` | `String _generateReason(Uri url, int riskScore)` | Produces human-readable explanation string. |

**Static data:**

| List | Count | Purpose |
|------|-------|---------|
| `_suspiciousKeywords` | 13 | Words like `bank`, `paypal`, `verify`, `login`, `password`, etc. |
| `_trustedDomains` | 12 | Whitelisted domains: Google, Facebook, GitHub, etc. |
| `_urlShorteners` | 5 | Known shorteners: `bit.ly`, `tinyurl.com`, etc. |

**URL normalization:**
- Auto-prepends `https://` if no scheme is provided.
- Validates host format using regex `^[a-zA-Z0-9\-\.]+$`.
- Invalid URLs get an immediate 100% risk score and "Malicious" classification.

---

### 3.2 AiService

**File:** `lib/services/ai_service.dart` (212 lines)

Integrates with the **Llama 3.3 70B** model via the **Groq API** for intelligent threat analysis.

**Key method:**

```dart
Future<AiAnalysisResult?> analyzeUrl({
  required String url,
  required int heuristicScore,
  required String heuristicClassification,
  required String heuristicReason,
})
```

**Behavior:**
1. Checks `AiConfig.isConfigured` — returns `null` if no API key.
2. Sends a structured prompt with heuristic results to the LLM.
3. Requests JSON response format (`response_format: {"type": "json_object"}`).
4. Uses `temperature: 0.3` for consistent, factual responses.
5. Timeout: 15 seconds (configurable via `AiConfig.timeoutSeconds`).

**AiAnalysisResult fields:**

| Field | Type | Description |
|-------|------|-------------|
| `threatSummary` | `String` | 1–2 sentence threat assessment |
| `riskFactors` | `List<String>` | 2–5 specific risk factors identified |
| `recommendation` | `String` | Actionable user guidance |
| `confidenceLevel` | `String` | `high` / `medium` / `low` |

**System prompt:** The LLM is instructed to act as "TrustProbe AI, an expert cybersecurity analyst" and respond with structured JSON. It handles safe, suspicious, and malicious URLs with appropriate depth.

---

### 3.3 FirestoreService

**File:** `lib/services/firestore_service.dart` (90 lines)

Manages CRUD operations on the `url_scans` Firestore collection, scoped by device ID.

| Method | Parameters | Description |
|--------|------------|-------------|
| `saveScanResult` | `ScanResult result` | Saves a scan document (includes `deviceId`) |
| `getPreviousScans` | `required String deviceId`, `int limit = 50` | Returns a real-time stream filtered by `deviceId`, ordered by timestamp descending |
| `getScanCount` | — | Returns total scan count across all devices (for analytics) |
| `deleteOldScans` | `int daysOld = 30` | Batch-deletes documents older than the specified days |

**Firestore query for `getPreviousScans`:**
```dart
_firestore
  .collection('url_scans')
  .where('deviceId', isEqualTo: deviceId)
  .orderBy('timestamp', descending: true)
  .limit(limit)
  .snapshots()
```

> **Note:** This compound query requires a **composite index** on `(deviceId ASC, timestamp DESC)`. Firestore auto-prompts for this on first run.

**Error handling:**
- 3-second timeout on stream — auto-closes if Firebase is unreachable.
- All errors are logged and swallowed to prevent app crashes.

---

### 3.4 DeviceIdService

**File:** `lib/services/device_id_service.dart` (50 lines)

Generates and persists a **UUID v4** per device using `SharedPreferences`.

| Method | Description |
|--------|-------------|
| `initialize()` | Called once at app startup. Loads existing ID or generates a new one. |
| `deviceId` (getter) | Returns the current device's UUID. Asserts that `initialize()` was called. |

**Storage key:** `trustprobe_device_id`

**Fallback:** If `SharedPreferences` fails (e.g., in a restrictive browser), a non-persistent UUID is generated so the app still functions — the device just won't have history persistence across sessions.

**Future auth migration path:**
When Firebase Auth is added, the device ID can be used to migrate anonymous scans to the authenticated user by:
1. Querying all scans with the device's `deviceId`.
2. Updating them to include the authenticated `userId`.
3. Switching queries to filter by `userId`.

---

## 4. Data Models

### ScanResult

**File:** `lib/models/scan_result.dart`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | `String` | ✅ | The analyzed URL |
| `riskScore` | `int` | ✅ | 0–100 risk percentage |
| `classification` | `String` | ✅ | `Safe`, `Suspicious`, or `Malicious` |
| `reason` | `String` | ✅ | Human-readable explanation |
| `timestamp` | `DateTime` | ✅ | When the scan was performed |
| `aiAnalysis` | `String?` | ❌ | Formatted AI analysis string (if available) |
| `deviceId` | `String?` | ❌ | UUID of the device that performed the scan |
| `scoreBreakdown` | `Map<String, int>` | ❌ | Maps each heuristic check name to its score contribution |

**Serialization methods:**
- `toMap()` — Converts to `Map<String, dynamic>` for Firestore.
- `ScanResult.fromFirestore(Map<String, dynamic>)` — Factory constructor from Firestore document.
- `copyWith(...)` — Immutable update pattern, used to attach `deviceId` before saving.

**Computed properties:**
- `riskColor` — Returns `green`, `yellow`, or `red` string.
- `riskLevel` — Returns `Low Risk`, `Medium Risk`, or `High Risk` label.

---

## 5. UI Components

### 5.1 HomeView

**File:** `lib/ui/views/home/home_view.dart` (419 lines)

The main screen containing three sections:

1. **Header** — App title with shield icon, gradient glow, and tagline.
2. **Input Section** — URL text field + "Analyze URL" button with loading state.
3. **Results Section** — `ResultCard` widget (visible only when analysis completes).
4. **History Section** — `SearchHistoryTable` (visible only when not analyzing).

**Reactive binding:** Uses `ViewModelBuilder<HomeViewModel>.reactive()` for automatic UI updates.

### 5.2 HomeViewModel

**File:** `lib/ui/views/home/home_viewmodel.dart` (108 lines)

| Property | Type | Description |
|----------|------|-------------|
| `urlInput` | `String` | Current text in the URL field |
| `currentResult` | `ScanResult?` | Latest analysis result |
| `errorMessage` | `String?` | Error message to display |
| `hasResult` | `bool` | Whether a result exists to show |
| `hasError` | `bool` | Whether an error exists to show |
| `previousScans` | `Stream<List<ScanResult>>` | **Cached** stream from Firestore (created once via `late final`) |

**Why `late final` for `previousScans`?**
Previously this was a getter that created a new Firestore stream on every call. Since `notifyListeners()` triggers a full widget rebuild, typing in the URL field caused the `StreamBuilder` to reset to `ConnectionState.waiting`, showing a loader flash. Using `late final` ensures the stream is created exactly once.

### 5.3 ResultCard

**File:** `lib/ui/widgets/result_card.dart` (914 lines)

An animated card displaying:
- URL section with risk color accent
- Circular risk score gauge with animated fill
- Classification badge (Safe/Suspicious/Malicious)
- Detailed explanation with individual risk reasons
- Expandable score breakdown dropdown (shows each heuristic check)
- AI Insights section (if AI analysis is available)
- Recommendation section

**Animations:** Uses `AnimationController` with `CurvedAnimation` for fade-in and slide-up entrance.

### 5.4 SearchHistoryTable

**File:** `lib/ui/widgets/search_history_table.dart` (376 lines)

A responsive table/list displaying past scans. Uses `StreamBuilder` to react to Firestore updates in real-time.

**States:**
- `ConnectionState.waiting` → Loading spinner
- `snapshot.hasError` → Error card with message
- Empty data → "No previous searches" empty state
- Has data → Table (desktop) or Card list (mobile)

**Responsive breakpoint:** `maxWidth < 600` switches to mobile layout.

**Click interaction:** `onScanTap` callback loads a previous scan into the `ResultCard`.

---

## 6. Detection Algorithm — Full Specification

### Risk Factor Table

| # | Check Name | Points | Trigger Condition | Implementation |
|---|-----------|--------|-------------------|----------------|
| 1 | Trusted Domain | −40 | Exact match or proper subdomain of whitelisted domain | `_trustedDomains.any(...)` |
| 2 | Suspicious Keywords (Domain) | +40 | Domain contains any of 13 suspicious words | `domain.contains(keyword)` |
| 3 | Suspicious Keywords (Path) | +20 | Path/query contains suspicious words (only if domain doesn't) | `path.contains(keyword)` |
| 4 | HTTPS Security | +25 | Scheme is `http` instead of `https` | `url.scheme == 'http'` |
| 5 | Domain Length | +30 | Domain exceeds 30 characters | `domain.length > 30` |
| 6 | Subdomain Complexity | +20 | More than 2 subdomain levels | `domain.split('.').length - 2 > 2` |
| 7 | IP Address Usage | +35 | Domain is a raw IPv4 address | Regex: `\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}` |
| 8 | URL Obfuscation (@) | +30 | URL contains `@` symbol | `fullUrl.contains('@')` |
| 9 | Excessive Dashes | +20 | More than 3 dashes in domain | `domain.split('-').length > 3` |
| 10 | URL Shortener | +25 | Known shortener domain with short path (<10 chars) | `_urlShorteners.any(...)` |
| 11 | Suspicious TLD | +25 | Ends with `.tk`, `.ml`, `.ga`, `.cf`, `.gq`, `.xyz`, `.top`, `.click`, `.link` | `domain.endsWith(tld)` |
| 12 | Brand Impersonation | +35 | Domain contains brand name but isn't the official domain | Brand list: paypal, facebook, google, amazon, apple, microsoft, bank |

### Score Normalization

The raw cumulative score is clamped to `0–100` using `score.clamp(0, 100)`.

### Classification Thresholds

| Score Range | Classification |
|-------------|---------------|
| 0 – 40 | Safe |
| 41 – 70 | Suspicious |
| 71 – 100 | Malicious |

---

## 7. AI Integration (Llama 3.3 70B)

### Provider: Groq API

- **Endpoint:** `https://api.groq.com/openai/v1/chat/completions`
- **Model:** `llama-3.3-70b-versatile`
- **Temperature:** `0.3` (low for consistent, factual analysis)
- **Max tokens:** `1024`
- **Response format:** JSON object (enforced)

### Prompt Design

The system prompt instructs the LLM to:
1. Act as an expert cybersecurity analyst.
2. Receive both the URL and the heuristic analysis results.
3. Respond with structured JSON containing 4 fields.
4. Tailor the response depth based on classification (Safe → brief, Malicious → detailed warnings).
5. Identify specific phishing techniques (typosquatting, homograph attacks, brand impersonation).

### Graceful Degradation

The AI analysis is:
- **Optional** — Skipped entirely if `AiConfig.groqApiKey` is the default placeholder.
- **Non-blocking** — Errors are caught and logged; the app returns heuristic results only.
- **Timeout-protected** — 15-second timeout prevents hanging.

---

## 8. Device Identity & Data Ownership

### How It Works

```
App Launch
    |
    v
DeviceIdService.initialize()
    |
    +-- SharedPreferences has ID? --> Use existing ID
    |
    +-- No ID stored? --> Generate UUID v4 --> Store in SharedPreferences
    |
    v
deviceId is available to all services via locator
```

### Storage

- **Key:** `trustprobe_device_id`
- **Backend:** `shared_preferences` (uses `localStorage` on web, platform storage on mobile)
- **Format:** UUID v4 (e.g., `550e8400-e29b-41d4-a716-446655440000`)

### Data Scoping

All Firestore operations are scoped by `deviceId`:
- **Writes:** Every `ScanResult` includes the device's UUID in the `deviceId` field.
- **Reads:** `getPreviousScans()` filters with `.where('deviceId', isEqualTo: deviceId)`.
- **Result:** Each device only sees its own scan history.

---

## 9. Firebase Firestore Schema

### Collection: `url_scans`

Each document represents one URL scan:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `url` | `string` | The analyzed URL | `"https://google.com"` |
| `riskScore` | `number` | 0–100 risk percentage | `15` |
| `classification` | `string` | Safe / Suspicious / Malicious | `"Safe"` |
| `reason` | `string` | Human-readable explanation | `"Recognized as a trusted domain"` |
| `timestamp` | `string` | ISO 8601 timestamp | `"2026-02-19T06:30:00.000"` |
| `deviceId` | `string` | UUID of the device | `"550e8400-e29b-..."` |
| `aiAnalysis` | `string` (optional) | Formatted AI analysis text | `"AI Threat Summary: ..."` |
| `scoreBreakdown` | `map` (optional) | Check name → score | `{"Trusted Domain": -40, ...}` |

### Required Composite Index

```
Collection: url_scans
Fields: deviceId (Ascending), timestamp (Descending)
Query scope: Collection
```

Firestore will auto-prompt for this index on the first query. Click the link in the browser console to create it.

### Recommended Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /url_scans/{document=**} {
      // Anyone can read (no auth yet)
      allow read: if true;
      // Writes must include required fields
      allow write: if request.resource.data.keys()
        .hasAll(['url', 'riskScore', 'classification', 'deviceId']);
    }
  }
}
```

---

## 10. Dependency Injection & Service Locator

### Registration (app.locator.dart)

All services are registered as **lazy singletons** — instantiated once on first access:

| Service | Registration |
|---------|-------------|
| `AiService` | `locator.registerLazySingleton(() => AiService())` |
| `PhishingService` | `locator.registerLazySingleton(() => PhishingService())` |
| `FirestoreService` | `locator.registerLazySingleton(() => FirestoreService())` |
| `DeviceIdService` | `locator.registerLazySingleton(() => DeviceIdService())` |
| `NavigationService` | Stacked built-in |
| `DialogService` | Stacked built-in |
| `SnackbarService` | Stacked built-in |

### Initialization Order (main.dart)

```dart
1. WidgetsFlutterBinding.ensureInitialized()
2. Firebase.initializeApp(...)          // Firebase must be first
3. setupLocator()                       // Register all services
4. locator<DeviceIdService>().initialize()  // Load/generate device ID
5. runApp(const MyApp())               // Start the app
```

> **Important:** `DeviceIdService.initialize()` must be called **after** `setupLocator()` but **before** `runApp()` to ensure the device ID is ready before any ViewModel accesses it.

---

## 11. Configuration Reference

### AiConfig (lib/config/ai_config.dart)

| Constant | Default | Description |
|----------|---------|-------------|
| `groqApiKey` | `'YOUR_GROQ_API_KEY_HERE'` | Groq API key. Replace with your key. |
| `baseUrl` | `'https://api.groq.com/openai/v1/chat/completions'` | Groq API endpoint |
| `model` | `'llama-3.3-70b-versatile'` | LLM model identifier |
| `timeoutSeconds` | `15` | HTTP request timeout |
| `maxTokens` | `1024` | Maximum response tokens |
| `isConfigured` | (computed) | Returns `true` if `groqApiKey` is not the placeholder |

### Alternative models (supported by Groq):
- `mixtral-8x7b-32768` — Faster, smaller, good for simple analysis
- `gemma2-9b-it` — Google's open model, balanced performance

---

## 12. Error Handling & Graceful Degradation

TrustProbe AI is designed to **never crash** even when external services are unavailable:

| Scenario | Behavior |
|----------|----------|
| **Firebase not configured** | App runs without history. Firestore stream times out in 3s and closes. |
| **Groq API key missing** | AI analysis is skipped. Only heuristic results are shown. |
| **Groq API call fails** | Error is logged. Heuristic results are returned as-is. |
| **Firestore save fails** | Error is logged. Result is still displayed to the user. |
| **SharedPreferences fails** | Fallback UUID is generated in memory (non-persistent). |
| **Invalid URL entered** | Returns 100% risk score with "Invalid URL format" message. |
| **Network offline** | Heuristic analysis works fully offline. Firestore/AI gracefully fail. |

---

## 13. Security Considerations

### API Key Protection
- The Groq API key is stored in `ai_config.dart` as a placeholder.
- **Production recommendation:** Use environment variables, Flutter's `--dart-define`, or a backend proxy to avoid exposing the key in client-side code.

### Firestore Security
- Default test-mode rules allow all reads/writes — **not suitable for production**.
- Use the security rules in [Section 9](#recommended-security-rules) as a starting point.
- Consider adding rate limiting via Firebase App Check.

### Device ID Privacy
- The UUID is random and contains no personally identifiable information.
- It is stored locally in `SharedPreferences` / `localStorage`.
- On web, clearing browser data will reset the device ID.

### URL Handling
- All URLs are normalized and parsed using Dart's `Uri.parse()`.
- Invalid URLs are immediately classified as malicious to prevent exploitation.
- No URLs are actually visited — only the URL string structure is analyzed.

---

## 14. Future Roadmap

| Feature | Complexity | Description |
|---------|------------|-------------|
| **Firebase Authentication** | Medium | Add email/Google login. Migrate device scans via `deviceId`. |
| **URL Screenshot Preview** | Medium | Capture webpage screenshots for visual verification. |
| **Browser Extension** | High | Chrome/Firefox extension for inline URL checking. |
| **Bulk URL Scanning** | Low | Accept CSV/text file with multiple URLs. |
| **Custom Trusted Domains** | Low | Let users whitelist their own domains. |
| **Phishing Feed Integration** | Medium | Integrate with PhishTank, OpenPhish for known-bad URL databases. |
| **Export Reports** | Low | PDF/CSV export of scan results. |
| **Dark/Light Theme Toggle** | Low | User preference for theme. |

---

## 15. Troubleshooting

### "Firestore composite index required" error

On first run, you'll see a console error with a link to create the index. Click the link to auto-create the `(deviceId, timestamp)` composite index in Firebase Console.

### AI analysis returns null

1. Check that `AiConfig.groqApiKey` is set to a valid key (not the placeholder).
2. Verify the key at [console.groq.com](https://console.groq.com).
3. Check browser console for timeout or API errors.

### History not showing

1. Verify Firebase is configured with correct `FirebaseOptions` in `main.dart`.
2. Check that the Firestore composite index exists (see above).
3. Open Firebase Console → Firestore → `url_scans` to check if documents have `deviceId`.

### Loader flashing when typing

This was fixed by caching the stream as `late final` in `HomeViewModel`. If it reappears, ensure `previousScans` is not recreated on rebuild:
```dart
// Correct — cached, created once
late final Stream<List<ScanResult>> previousScans = ...;

// Wrong — creates new stream on every access
Stream<List<ScanResult>> get previousScans => ...;
```

### Build errors after pulling changes

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

<p align="center">
  <em>TrustProbe AI — Built with Flutter 💙 and Llama 3.3 🦙</em>
</p>
