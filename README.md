<p align="center">
  <img src="https://img.shields.io/badge/TrustProbe_AI-Phishing_Detection-00d2ff?style=for-the-badge&logo=shield&logoColor=white" alt="TrustProbe AI" />
</p>

<h1 align="center">🛡️ TrustProbe AI</h1>

<p align="center">
  <strong>AI-Powered Phishing URL Risk Analyzer</strong><br/>
  Protect yourself from phishing attacks with real-time, intelligent URL analysis
</p>

<p align="center">
  <a href="#features"><img src="https://img.shields.io/badge/Features-12+-00d2ff?style=flat-square" alt="Features" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/AI-Llama_3.3_70B-8B5CF6?style=flat-square&logo=meta&logoColor=white" alt="AI Model" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
  <img src="https://img.shields.io/badge/Platform-Web-FF6F00?style=flat-square" alt="Platform" />
</p>

---

## 📖 Overview

**TrustProbe AI** is a modern Flutter Web application that analyzes URLs for phishing risks using a **hybrid detection engine** — combining rule-based heuristic analysis with AI-powered threat intelligence from **Llama 3.3 70B** (via Groq API).

Enter any URL and get an instant risk assessment with a detailed breakdown of why a URL is classified as **Safe**, **Suspicious**, or **Malicious**, along with actionable recommendations.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔍 **Real-time URL Analysis** | Instant phishing risk detection with detailed score breakdown |
| 🤖 **AI-Powered Threat Intelligence** | Llama 3.3 70B provides in-depth security analysis beyond rule-based checks |
| 📊 **Risk Scoring (0–100%)** | Continuous risk score with color-coded indicators (Green/Yellow/Red) |
| 🏷️ **Smart Classification** | Clear **Safe** / **Suspicious** / **Malicious** categorization |
| 📝 **Human-Readable Explanations** | Detailed reasoning for every classification decision |
| 🧮 **Score Breakdown** | Transparent breakdown showing exactly which checks contributed to the score |
| 📚 **Search History** | Previous scans stored and streamed in real-time from Firebase Firestore |
| 🎨 **Modern UI/UX** | Dark theme with gradient backgrounds, glassmorphism effects, and smooth animations |
| 📱 **Fully Responsive** | Optimized for desktop, tablet, and mobile viewports |
| � **Brand Impersonation Detection** | Identifies domains mimicking trusted brands |
| 🌐 **URL Shortener Detection** | Flags shortened URLs that may hide malicious destinations |
| ⚡ **Graceful Degradation** | Works without AI/Firebase — core heuristic engine runs independently |

---

## 🏗️ Architecture

TrustProbe AI follows the **Stacked MVVM (Model-View-ViewModel)** architecture pattern with clean separation of concerns:

```
+-----------------------------------------------------+
|                      UI Layer                        |
|  +-----------+  +------------+  +--------------+     |
|  | HomeView  |  | ResultCard |  | HistoryTable |     |
|  +-----+-----+  +-----+------+  +------+------+     |
|        |               |               |             |
|        +---------------+---------------+             |
|                        |                             |
+------------------------+-----------------------------+
|                 ViewModel Layer                      |
|            +--------------------+                    |
|            |   HomeViewModel    |                    |
|            |  (State + Logic)   |                    |
|            +--------+-----------+                    |
|                     |                                |
+---------------------+-------------------------------+
|                  Service Layer                       |
|  +--------------+  +----------------+  +-----------+ |
|  | AiService    |  | PhishingService|  | Firestore | |
|  | (Llama 3.3)  |  | (Heuristics)  |  | Service   | |
|  +--------------+  +----------------+  +-----------+ |
+-----------------------------------------------------+
```

### Layer Responsibilities

| Layer | Component | Responsibility |
|-------|-----------|----------------|
| **View** | `HomeView`, `ResultCard`, `SearchHistoryTable` | Pure UI rendering — no business logic |
| **ViewModel** | `HomeViewModel` | State management, orchestrates services, handles user interactions |
| **Service** | `PhishingService` | Core phishing detection engine (heuristic + AI) |
| **Service** | `AiService` | LLM integration via Groq API (Llama 3.3 70B) |
| **Service** | `FirestoreService` | Firebase Firestore CRUD for scan history |
| **Model** | `ScanResult` | Data structure for URL scan results with serialization |
| **Config** | `AiConfig` | Centralized AI/API configuration |

---

## 📁 Project Structure

```
TrustProbeAI/
├── lib/
│   ├── app/
│   │   ├── app.dart                     # Stacked app configuration (routes + DI)
│   │   ├── app.locator.dart             # Dependency injection (auto-generated)
│   │   └── app.router.dart              # Navigation routes (auto-generated)
│   │
│   ├── config/
│   │   └── ai_config.dart               # Groq API key, model, and timeout settings
│   │
│   ├── models/
│   │   └── scan_result.dart             # ScanResult data model with Firestore serialization
│   │
│   ├── services/
│   │   ├── ai_service.dart              # Llama 3.3 70B integration via Groq API
│   │   ├── phishing_service.dart        # Core phishing detection engine
│   │   └── firestore_service.dart       # Firebase Firestore operations
│   │
│   ├── ui/
│   │   ├── views/
│   │   │   └── home/
│   │   │       ├── home_view.dart       # Main UI (input, results, history)
│   │   │       └── home_viewmodel.dart  # Business logic & state management
│   │   │
│   │   └── widgets/
│   │       ├── result_card.dart         # Animated result display with score breakdown
│   │       └── search_history_table.dart # Responsive history table/card view
│   │
│   └── main.dart                        # App entry point (Firebase init + Stacked setup)
│
├── test/
│   ├── phishing_service_test.dart       # Unit tests for the detection engine
│   └── widget_test.dart                 # Widget tests
│
├── web/
│   └── index.html                       # HTML template with SEO meta tags
│
├── pubspec.yaml                         # Dependencies & project metadata
├── analysis_options.yaml                # Dart linter configuration
├── CONTRIBUTING.md                      # Contribution guidelines
├── LICENSE                              # MIT License
└── README.md                            # This file
```

---

## 🔬 Detection Algorithm

TrustProbe AI uses a **two-stage hybrid detection engine**:

### Stage 1 — Heuristic Analysis (Rule-Based)

The engine evaluates URLs against **12 risk factors** and produces a cumulative score:

#### 🔴 Risk Factors (Increase Score)

| Check | Points | Trigger Condition |
|-------|--------|-------------------|
| **Suspicious Keywords (Domain)** | +40 | Domain contains words like `bank`, `paypal`, `verify`, `login`, `password`, `wallet`, etc. |
| **Suspicious Keywords (Path)** | +20 | URL path/query contains suspicious keywords (only if domain doesn't) |
| **IP Address Usage** | +35 | Domain is a raw IP address (e.g., `192.168.1.1`) |
| **Brand Impersonation** | +35 | Domain contains brand name but isn't the real brand (e.g., `paypal-secure.xyz`) |
| **Domain Length** | +30 | Domain exceeds 30 characters |
| **URL Obfuscation (@)** | +30 | URL contains `@` symbol (redirects before `@` are ignored by browsers) |
| **HTTPS Security** | +25 | Uses insecure `http://` instead of `https://` |
| **URL Shortener** | +25 | Known shortener (bit.ly, tinyurl, etc.) with short path |
| **Suspicious TLD** | +25 | Ends with `.tk`, `.ml`, `.ga`, `.cf`, `.gq`, `.xyz`, `.top`, `.click`, `.link` |
| **Subdomain Complexity** | +20 | More than 2 subdomain levels |
| **Excessive Dashes** | +20 | More than 3 dashes in domain |

#### 🟢 Trust Factors (Decrease Score)

| Check | Points | Trigger Condition |
|-------|--------|-------------------|
| **Trusted Domain** | −40 | Exact match or proper subdomain of known trusted domains (Google, Facebook, GitHub, etc.) |

#### Classification Thresholds

| Score Range | Classification | Color |
|-------------|---------------|-------|
| 0 – 40% | ✅ **Safe** | 🟢 Green |
| 41 – 70% | ⚠️ **Suspicious** | 🟡 Yellow |
| 71 – 100% | 🚨 **Malicious** | 🔴 Red |

### Stage 2 — AI Threat Analysis (Llama 3.3 70B)

When configured, the AI engine receives the heuristic results and provides:
- **Threat Summary** — Concise assessment of the URL's danger level
- **Specific Risk Factors** — Detailed list of identified threats (typosquatting, homograph attacks, etc.)
- **Actionable Recommendation** — Clear guidance for the user
- **Confidence Level** — High / Medium / Low confidence in the assessment

> 💡 AI analysis is optional and non-blocking. The app functions fully with heuristics alone.

### Example Analysis

**Input:** `secure-bank-login.example.com`

| Check | Result | Points |
|-------|--------|--------|
| Suspicious Keywords (Domain) | `bank`, `login` detected | +40 |
| Excessive Dashes | 3 dashes in domain | 0 |
| Brand Impersonation | `bank` brand but not `bank.com` | +35 |
| **Total** | | **75%** |
| **Classification** | | 🚨 **Malicious** |

---

## 🛠️ Tech Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Framework** | Flutter Web | Cross-platform UI |
| **Language** | Dart 3.10+ | Type-safe development |
| **Architecture** | Stacked MVVM | State management & DI |
| **AI Model** | Llama 3.3 70B (open-source) | Intelligent threat analysis |
| **AI Provider** | Groq API | Ultra-fast LLM inference |
| **Database** | Cloud Firestore | Real-time scan history |
| **Firebase** | Firebase Core | Backend infrastructure |
| **Typography** | Google Fonts (Poppins, Inter) | Modern UI typography |
| **Design System** | Material Design 3 | UI components |
| **HTTP Client** | `package:http` | API communication |
| **Testing** | `flutter_test` | Unit & widget tests |

---

## ⚙️ Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.10.0 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Chrome** browser (for web development)
- **Firebase** account — [Create Free Account](https://firebase.google.com)
- **Groq API key** (optional, for AI features) — [Get Free Key](https://console.groq.com)

### 1. Clone the Repository

```bash
git clone https://github.com/akshaychandt/TrustProbe-AI.git
cd TrustProbe-AI
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Stacked Files

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/) → Create a new project
2. Enable **Cloud Firestore** → Start in test mode
3. Add a **Web App** and copy the Firebase configuration
4. Update `lib/main.dart` with your config:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID",
  ),
);
```

### 5. Configure AI (Optional)

To enable AI-powered analysis, get a free API key from [Groq Console](https://console.groq.com) and update `lib/config/ai_config.dart`:

```dart
static const groqApiKey = 'YOUR_GROQ_API_KEY';
```

### 6. Run the App

```bash
flutter run -d chrome
```

The app will launch in Chrome at `http://localhost:<port>`.

---

## 🚀 Deployment

### Build for Production

```bash
flutter build web --release
```

Output will be in the `build/web/` directory.

### Deploy to Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login & initialize
firebase login
firebase init hosting  # Set public directory to build/web

# Deploy
firebase deploy
```

---

## 🧪 Testing

### Run Unit Tests

```bash
flutter test
```

### Test URLs

| URL | Expected | Score |
|-----|----------|-------|
| `google.com` | ✅ Safe | < 40% |
| `https://github.com` | ✅ Safe | < 40% |
| `facebook.com` | ✅ Safe | < 40% |
| `secure-bank-login.example.com` | 🚨 Malicious | > 70% |
| `http://paypal-verify.suspicious.com` | 🚨 Malicious | > 60% |
| `http://192.168.1.1/login` | 🚨 Malicious | > 60% |

### Verify Firestore

1. Analyze a few URLs in the app
2. Open Firebase Console → Firestore Database
3. Check that `url_scans` collection has documents
4. Refresh app — previous scans should appear

---

## 🎨 UI Highlights

- **🌙 Dark Theme** — Sleek gradient backgrounds with navy-to-purple transitions
- **💎 Glassmorphism** — Semi-transparent cards with backdrop blur effects
- **🎬 Smooth Animations** — Fade-in and slide transitions for result cards
- **🎯 Color-Coded Risk** — Intuitive green/yellow/red indicators
- **📊 Score Breakdown** — Visual bar showing each heuristic check's contribution
- **📋 Responsive Tables** — Desktop table view transforms to mobile card view
- **⚡ Real-time Updates** — Firestore `StreamBuilder` for live scan history

---

## � Extending the Detection Engine

### Adding a New Risk Factor

Edit `lib/services/phishing_service.dart` → `_calculateRiskScore()`:

```dart
// Example: Detect encoded characters in URL
if (fullUrl.contains('%') && fullUrl.split('%').length > 3) {
  breakdown['URL Encoding'] = 20;
  score += 20;
} else {
  breakdown['URL Encoding'] = 0;
}
```

Then add a corresponding human-readable reason in `_generateReason()`.

### Adding a Trusted Domain

```dart
static const List<String> _trustedDomains = [
  'google.com',
  'facebook.com',
  // Add your domain here:
  'yourtrusted.com',
];
```

---

## 🔒 Security Notes

- **API Keys**: Never commit real API keys. Use environment variables or `.env` files in production.
- **Firestore Rules**: The default test-mode rules allow all reads/writes. For production:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /url_scans/{document=**} {
      allow read: if true;
      allow write: if request.resource.data.keys().hasAll(['url', 'riskScore', 'classification']);
    }
  }
}
```

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'feat: add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Akshay Chand T**
- GitHub: [@akshaychandt](https://github.com/akshaychandt)
- Email: akshaychand.t@gmail.com

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) — Cross-platform UI framework
- [Stacked](https://pub.dev/packages/stacked) — MVVM architecture by FilledStacks
- [Firebase](https://firebase.google.com) — Backend infrastructure
- [Groq](https://groq.com) — Ultra-fast LLM inference
- [Meta Llama 3.3](https://ai.meta.com/llama/) — Open-source large language model
- [Google Fonts](https://fonts.google.com) — Typography

---

<p align="center">
  Made with ❤️ and Flutter 💙
</p>
