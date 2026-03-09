# Chart Guardian 🛡️

> **Your Professional Forex Companion** — Real-time news, TradingView charts, smart price alerts, trading journal, and a curated forex store. All in one dark-themed Flutter app.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Firebase Setup](#firebase-setup)
  - [Running the App](#running-the-app)
- [App Flow](#app-flow)
- [Key Screens](#key-screens)
- [Architecture](#architecture)
- [Services](#services)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Chart Guardian** is a professional-grade forex trading companion built with Flutter. It brings together the tools every trader needs in a single, beautifully designed dark-themed app:

- Stay informed with **live ForexFactory economic news** filtered by your favourite currency pairs
- Open **TradingView-powered charts** for any major pair and save your analysis as images
- Set **price alerts** on any pair and receive push notifications the moment price hits your target
- Track every trade in a **personal trading journal** with emotion tagging and P&L calculation
- Access a **forex store** stocked with books, courses, signals, bots, and tools
- Monitor **live market sessions** (Sydney, Tokyo, London, New York) from the dashboard

---

## Features

### 🏠 Dashboard
- Greeting based on time of day
- **Economic Calendar Carousel** — horizontal scrollable news tiles fetched from ForexFactory's public JSON feed (`nfs.faireconomy.media`)
- News filtered automatically by currencies in your favourite pairs
- Impact colour-coding: 🔴 High · 🟠 Medium · 🟡 Low
- Forecast vs Previous values displayed on each tile
- **Favourite Pairs Carousel** — tap any pair to jump straight into its TradingView chart
- Add / remove favourite pairs with a full searchable selector (30+ pairs including commodities & crypto)
- **Market Sessions Clock** — live UTC-based open/close status for Sydney, Tokyo, London, and New York
- Pull-to-refresh on the entire dashboard

### 📈 Charts
- Full list of your favourite pairs, each with its TradingView symbol
- **TradingView WebView** — embedded professional chart with all native tools (indicators, drawing tools, timeframes, replay mode)
- Chart runs in **dark theme** matching the app
- **Save Analysis** — captures the chart as a PNG and saves it to the device's documents folder
- **Set Price Alert** — directly from inside the chart view, with Above/Below toggle and notification tone selector

### 🔔 Alerts
- Full list of active price alerts with colour-coded Above (green) / Below (red) direction
- Swipe to delete any alert
- **Add Alert** bottom sheet — choose pair, enter target price, set direction
- **Background price checker** (ported from the original Java prototype) — runs a `Timer.periodic` every 60 seconds while the app is open, fetches live rates from `api.exchangerate-api.com`, fires a push notification when any alert condition is met
- Supports all major pairs including cross-rates and commodities (XAU/USD, XAG/USD)

### 🛒 Store
- Searchable product catalogue with category filters: **All · Books · Courses · Signals · Bots · Tools**
- Real book cover images: ICT Trading Strategy, Smart Money Concepts, Liquidity Mastery, Fundamentals series
- Product detail bottom sheet with full description, price, and subscription badge
- Categories:
  - **Books** — Trading psychology, ICT, SMC, Liquidity, Fundamentals
  - **Courses** — Price Action Mastery, Forex Fundamentals with live Q&A
  - **Signals** — Premium FX Signals, Gold & Crypto Signals (subscription)
  - **Bots** — EA Scalper Pro, Trend Rider Bot (MT4/MT5 Expert Advisors)
  - **Tools** — Position Size Calculator, Trade Journal Pro

### 📓 Journal
- Log every trade: pair, direction (Buy/Sell), entry price, exit price, emotion, notes, outcome
- Auto-calculates **P&L** from entry/exit prices and direction
- **Stats bar**: Total Trades · Win Rate · Total P&L — updates live as entries are added
- Colour-coded entry cards: green border = win, red border = loss
- Emotion tagging: Confident · Neutral · Nervous · Fearful
- Swipe-to-delete with Dismissible
- All entries persisted locally with SharedPreferences

### 🔑 Authentication
- **Firebase Auth** integration — Email/password login and sign-up
- Graceful fallback to local session (SharedPreferences) if Firebase is not configured
- Password reset via email
- Persistent login — app remembers session across restarts
- Secure logout with confirmation dialog

### 🎨 Onboarding
- 4-page onboarding carousel with smooth page transitions and dot indicator
- Page 1: Welcome — app name, logo, tagline
- Page 2: Stay Informed & Manage Risk — News, Charts, Alerts, Journal features
- Page 3: Grow & Trade Smarter — Education, Bots, Signals, Market Clock features
- Page 4: Get Started — Login / Create Account / Continue as Guest
- Skip button available on pages 1–3
- Onboarding shown only once; subsequent launches go directly to Login or Home

---

## Tech Stack

| Category | Package | Version |
|----------|---------|---------|
| Framework | Flutter | ≥ 3.3.2 |
| Language | Dart | ≥ 3.3.2 |
| Navigation | `go_router` | ^7.1.1 |
| Charts | `webview_flutter` (TradingView) | ^4.4.0 |
| Auth | `firebase_auth` | ^4.17.7 |
| Database | `cloud_firestore` | ^4.15.7 |
| Local Storage | `shared_preferences` | ^2.2.2 |
| Notifications | `flutter_local_notifications` | ^16.3.2 |
| HTTP | `http` | ^1.2.1 |
| Fonts | `google_fonts` (Inter) | ^6.2.1 |
| Icons | `font_awesome_flutter` | ^10.6.0 |
| Images | `cached_network_image` | ^3.3.1 |
| Pagination | `smooth_page_indicator` | ^1.1.0 |
| Animations | `flutter_animate` | ^4.1.1 |
| State | `provider` | ^6.1.2 |
| File I/O | `path_provider` | ^2.0.14 |
| Internationalisation | `intl` | ^0.18.1 |

---

## Project Structure

```
chart_gaurdian/
├── lib/
│   ├── main.dart                        # Entry point — Firebase init, GoRouter, price checker start
│   ├── app_theme.dart                   # AppColors + AppTheme (dark forex theme, gold accent)
│   │
│   ├── Intropage.dart                   # 4-page onboarding carousel
│   ├── loginpage.dart                   # Firebase Auth login screen
│   ├── signuppage.dart                  # Firebase Auth sign-up screen
│   ├── homepage.dart                    # HomeScreen — 5-tab BottomNavigationBar shell
│   ├── alertsscreen.dart                # Alerts list + Add Alert sheet + Alert model
│   ├── addfav.dart                      # Currency pair selector (30+ pairs)
│   ├── chartpage.dart                   # Legacy stub (superseded by charts_screen.dart)
│   │
│   ├── screens/
│   │   ├── dashboard_screen.dart        # Dashboard — news carousel, pair tiles, market clock
│   │   ├── charts_screen.dart           # Charts list + ChartDetailScreen (TradingView WebView)
│   │   ├── store_screen.dart            # Forex store — books, courses, signals, bots, tools
│   │   └── journal_screen.dart          # Trading journal — log, stats, P&L, emotion tagging
│   │
│   └── services/
│       └── price_checker_service.dart   # Timer-based price alert checker + push notifications
│
├── assets/
│   └── images/                          # Book covers, strategy charts, background photos
│       ├── bull_logo.jpg
│       ├── fundamentalsbook.png
│       ├── fundamentalsbook2.png
│       ├── fundamentalsbook3.png
│       ├── ICT-Trading-Strategy.png
│       ├── liquidity.png
│       ├── liquiditybook.png
│       ├── smc.png
│       ├── smcbook.png
│       └── ...
│
├── android/                             # Android platform config
├── ios/                                 # iOS platform config
├── web/                                 # Web platform config
├── windows/                             # Windows platform config
├── pubspec.yaml                         # Dependencies and assets
└── README.md                            # This file
```

---

## Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.3.2 ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK** ≥ 3.3.2 (bundled with Flutter)
- **Android Studio** or **VS Code** with Flutter extension
- **Git**
- A **Firebase project** (optional — app runs without it using local auth)

For **Windows desktop** builds, enable Developer Mode:
```
start ms-settings:developers
```

---

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd "Chart Guardian/chart_gaurdian"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify setup**
   ```bash
   flutter doctor
   flutter analyze
   ```

---

### Firebase Setup

Firebase Auth and Firestore are optional — the app falls back to local SharedPreferences auth if Firebase is not configured. To enable Firebase:

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)

2. Enable **Authentication → Email/Password**

3. **Android**: Download `google-services.json` → place in `android/app/`

4. **iOS**: Download `GoogleService-Info.plist` → place in `ios/Runner/`

5. **Web**: Copy the Firebase config into `web/index.html`

6. Enable **Firestore Database** if you want cloud-synced alerts/journal entries

> Without these files the app will still run — login/signup stores sessions locally only.

---

### Running the App

**Android (recommended)**
```bash
flutter run                          # auto-detects connected device
flutter run -d <device-id>           # specific device
```

**iOS**
```bash
open ios/Runner.xcworkspace          # configure signing in Xcode first
flutter run -d iphone                # then run from terminal
```

**Windows**
```bash
# Enable Developer Mode first (start ms-settings:developers)
flutter run -d windows
```

**Release APK**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Release iOS**
```bash
flutter build ipa --release
```

---

## App Flow

```
Launch
  │
  ├── First time? ──→ Onboarding (4 pages) ──→ Login / Sign Up
  │
  └── Returning? ──→ Logged in? ──→ Home Screen
                              └──→ Login Screen

Home Screen (5 tabs)
  ├── 🏠 Dashboard
  │     ├── ForexFactory news carousel (filtered by favourites)
  │     ├── Favourite pairs carousel → Chart Detail
  │     └── Market session clock
  │
  ├── 📈 Charts
  │     ├── List of favourite pairs
  │     └── Pair → TradingView WebView
  │               ├── Save analysis (PNG)
  │               └── Set price alert
  │
  ├── 🔔 Alerts
  │     ├── Active alerts list
  │     ├── Swipe to delete
  │     └── Add alert (pair + price + direction)
  │
  ├── 🛒 Store
  │     ├── Search + category filters
  │     ├── Product grid with images
  │     └── Product detail sheet
  │
  └── 📓 Journal
        ├── Stats bar (trades, win rate, P&L)
        ├── Trade entries list
        ├── Swipe to delete
        └── Add trade (pair, direction, prices, emotion, notes)
```

---

## Key Screens

### Dashboard
The home screen fetches economic calendar events from `https://nfs.faireconomy.media/ff_calendar_thisweek.json` every time it loads, or on pull-to-refresh. Events are filtered to only show currencies from your selected pairs (e.g. adding EUR/USD shows all EUR and USD events). Each news tile shows: currency, impact level (colour-coded dot), event title, date/time, forecast, and previous values.

### TradingView Charts
Charts are rendered inside a `WebViewWidget` using TradingView's full-featured widget embed. The symbol is mapped from the pair name (e.g. `EUR/USD` → `FX:EURUSD`, `XAU/USD` → `TVC:GOLD`). The chart runs in dark mode to match the app theme. Saving analysis uses `RepaintBoundary` to capture the rendered chart as a PNG.

### Price Alert Checker (`price_checker_service.dart`)
Originally prototyped in Java (JavaFX), this service is the heart of the alert system. On app start it initialises `flutter_local_notifications` and starts a `Timer.periodic` with a 60-second interval. Each tick:
1. Loads all saved alerts from SharedPreferences
2. Fetches current rates from `api.exchangerate-api.com/v4/latest/USD`
3. Derives cross-rates (e.g. EUR/JPY = JPY_rate / EUR_rate)
4. Compares each alert's condition (`Above` / `Below`) to the current price
5. Fires a push notification for any newly triggered alert (each alert only notifies once per session)

### Trading Journal
Entries are stored as JSON strings in SharedPreferences. Each entry records: pair, direction, entry/exit prices, emotion state, free-text notes, win/loss outcome, and timestamp. The stats bar recalculates on every data change. P&L is derived from direction and price difference, giving a raw pip value.

---

## Architecture

```
main.dart
├── Firebase initialisation (try/catch — graceful degradation)
├── PriceCheckerService.init() + .start()
├── SharedPreferences check (onboarding seen? logged in?)
└── MaterialApp.router (GoRouter)
      ├── /intro     → IntroPage
      ├── /login     → LoginScreen
      ├── /signup    → SignupScreen
      └── /home      → HomeScreen
                          ├── DashboardScreen
                          ├── ChartsScreen → ChartDetailScreen
                          ├── AlertsScreen
                          ├── StoreScreen
                          └── JournalScreen
```

**State management**: Each screen manages its own local state with `StatefulWidget` + `setState`. SharedPreferences is used as the persistent store for all user data (favourites, alerts, journal entries, session flags). Firebase Auth is used when configured.

**Theme**: All colours are centralised in `AppColors` (in `app_theme.dart`) and all widget theme overrides are in `AppTheme.darkTheme`. No hardcoded colours anywhere else in the codebase.

---

## Services

### `PriceCheckerService`
| Method | Description |
|--------|-------------|
| `init()` | Initialises `FlutterLocalNotificationsPlugin` with Android + iOS settings |
| `start()` | Starts `Timer.periodic(60s)` — calls `_checkAll()` immediately and every 60 seconds |
| `stop()` | Cancels the timer (call on app pause/dispose if needed) |
| `_checkAll()` | Loads alerts, fetches rates, compares conditions, fires notifications |
| `_fetchRates()` | GET `api.exchangerate-api.com/v4/latest/USD` — returns `Map<String, double>` |
| `_pairPrice()` | Converts pair string to rate using USD-base arithmetic |
| `_notify()` | Shows a high-priority push notification with pair name and current price |

---

## Configuration

### Adding a New Currency Pair
Add the pair string to `_allPairs` in `lib/addfav.dart` and add its TradingView symbol to `_tvSymbols` in `lib/screens/charts_screen.dart`.

### Changing the News API
The ForexFactory feed URL is in `dashboard_screen.dart → _fetchNews()`. Replace the URI to use any compatible JSON calendar API.

### Changing the Price Feed
The exchange rate API URL is in `price_checker_service.dart → _fetchRates()`. The service expects a JSON body with a `"rates"` map keyed by ISO currency code.

### Notification Tone
The tone selector in the Set Alert sheet is UI-only in the current build. To wire up custom notification sounds, add audio files to `assets/` and reference them in `AndroidNotificationDetails(sound: ...)`.

### App Theme
All colours are defined as `static const` values in `AppColors` inside `lib/app_theme.dart`. Change `AppColors.gold` to adjust the primary accent throughout the entire app.

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

**Code style**: Follow the existing pattern — `StatefulWidget` for screens, `AppColors` for all colours, `SharedPreferences` for persistence. Run `flutter analyze` before submitting.

---

## Roadmap

- [ ] Firebase Firestore sync for alerts and journal entries across devices
- [ ] Background isolate for price checking when app is closed (WorkManager / Background Fetch)
- [ ] Email notification integration (SMTP via `mailer` package already installed)
- [ ] Custom notification tones wired to alert tone selector
- [ ] Chart annotation save — store drawing tool state per pair, not just screenshot
- [ ] Economic calendar reminder notifications (pre-event alerts)
- [ ] In-app purchase integration for Store products
- [ ] Google Sign-In and Apple Sign-In (packages already installed)
- [ ] Multi-language support

---

## License

This project is proprietary software. All rights reserved.

© 2024 Chart Guardian. Unauthorised copying, modification, distribution, or use of this software, via any medium, is strictly prohibited.

---

<p align="center">
  Built with Flutter · Powered by TradingView · Data from ForexFactory
</p>
