# FinWise AI — Personal Finance Management App

A production-quality Flutter app built with Clean Architecture + MVVM,
Riverpod, Firebase, and Gemini AI.

## What's included

Full source for every feature in the spec:

- **Auth**: Splash, Onboarding, Login, Signup, Forgot Password, Google Sign-In, Logout
- **Dashboard**: balance, income/expense, quick actions, budget progress, recent transactions
- **Expenses**: full CRUD, categories, custom categories via AppStrings, receipts field
- **AI Categorization**: `AiService.categorizeExpense()` via Gemini
- **Voice Entry**: `speech_to_text` capture → Gemini parses amount/category/date/description
- **Analytics**: pie chart (category-wise), bar chart (weekly spend), income vs expense
- **Budget Planner**: per-category monthly limits with live usage %, 80%/100% alerts
- **AI Financial Advisor**: chat UI backed by Gemini, grounded in real Firestore totals
- **Search & Filters**: by category, amount, date, keyword, payment method; date range chips
- **Notifications**: daily reminder, budget warning, monthly summary, savings milestone
- **Profile & Settings**: theme toggle, currency, biometric login, notifications
- **PDF/CSV Export**: `PdfService` generates and shares reports
- **Offline support**: Hive-backed queue in `ExpenseRepository`, synced on reconnect
- **Security**: Firebase Auth, biometric login via `local_auth`, input validation

## Setup

1. **Install Flutter** (stable channel) and run:
   ```bash
   flutter pub get
   ```

2. **Connect Firebase** — install FlutterFire CLI and generate config:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This creates `lib/firebase_options.dart`. Then in `lib/main.dart`, uncomment:
   ```dart
   import 'firebase_options.dart';
   // ...
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
   In the Firebase Console enable: **Authentication** (Email/Password + Google),
   **Cloud Firestore**, and **Storage**.

3. **Add your Gemini API key** — don't hardcode it. Run with:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_key_here
   ```
   (Get a key from https://aistudio.google.com/apikey)

4. **Firestore structure**:
   ```
   users/{uid}
     - name, email, photoUrl, currency, createdAt
     /expenses/{expenseId}
       - amount, category, date, description, paymentMethod, isIncome, createdAt
     /budgets/{budgetId}
       - category, limit, month, year
   ```
   Add security rules restricting each subcollection to `request.auth.uid == uid`.

5. **Fonts**: the theme references `Poppins`. Either drop the four weight files
   into `assets/fonts/` and re-enable the `fonts:` block in `pubspec.yaml`, or
   remove `fontFamily: 'Poppins'` from `app_theme.dart` to use the system font.

6. **Run**:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_key_here
   ```

## Architecture

```
lib/
├── core/           # theme, constants, services (AI/PDF/notifications/biometric), reusable widgets
├── models/         # plain Dart data classes (User, Expense, Budget, Category)
├── repositories/   # Firestore + Hive data access, offline-first sync
├── providers/      # Riverpod StateNotifiers & derived providers — the ViewModel layer
├── screens/        # Views, grouped by feature
├── routes/         # go_router config with auth-guard redirect logic
└── main.dart
```

MVVM mapping: **screens/** = View, **providers/** = ViewModel,
**repositories/ + models/** = Model layer. Views only read/write providers;
providers never import Flutter widgets — this keeps business logic testable
and UI swappable.

## Notes for interviews

- `ExpenseRepository.addExpense()` demonstrates the offline-first pattern:
  writes to Firestore first, falls back to a local Hive queue on failure,
  and `syncPendingExpenses()` flushes the queue once back online.
- `app_router.dart`'s `redirect` callback is a clean example of route guarding
  driven by a Riverpod stream (`authStateProvider`) rather than imperative
  navigation calls scattered across screens.
- `AiService` isolates all Gemini prompt engineering in one place, so the
  categorization, voice-parsing, and advisor features are all one small class
  to walk through.

## What you still need to do

- Generate `firebase_options.dart` (step 2 above) — not included since it's
  tied to your specific Firebase project.
- Add `assets/lottie/*.json` if you want animated splash/empty-states.
- Wire up `image_picker` + `firebase_storage` upload in `add_expense_screen.dart`
  for the receipt image field (left as a stretch feature).
- Add unit/widget tests under `test/` (Phase 12 from the original plan).
