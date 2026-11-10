# TORI Bank — Flutter migration

Flutter application derived from the supplied TORI Android source, with the supplied video as the visual reference. Application UI and state live in Dart under `lib/`. The Android `MainActivity.kt` is only the standard Flutter engine host; it contains no Compose screens or banking logic.

## Run

Current checks use Flutter 3.47.9 / Dart 3.13.7. The QR scanner dependency requires Flutter 3.29 or newer:

```sh
flutter pub get
cp .env.example .env
flutter run --dart-define-from-file=.env
```

Set `BASE_URL` in `.env` to your backend base URL, including `/api`. The file is ignored by Git; `.env.example` is the shared template. For the Android emulator, use `http://10.0.2.2:8000/api`; for a physical phone, use the backend computer's LAN IP. Restart the Flutter run command after changing `.env`. An explicit `--dart-define=BASE_URL=...` overrides the file. Client configuration is included in the compiled app, so do not put server secrets in this file.

For Android, install Android SDK 34 and Java 17, then run `flutter build apk --dart-define-from-file=.env`. The project uses Android Gradle Plugin 8.3.2 / Gradle 8.4 to satisfy the connectivity plugin requirements. Release signing is still the generated debug configuration; supply your existing signing configuration before publishing.

For a browser preview:

```sh
flutter run -d chrome --dart-define-from-file=.env
```

## Source layout

`cashout.dart` and `services/cashout_service.dart` implement **Payments → Branch Cash Out**: scan the branch QR, review the server amount/charge, confirm with PIN, and follow the branch request status. Cash-out uses existing Shomriddhi savings and never posts financial changes locally. Pending holds, cancellation, expiry and timeout-safe retries are handled by the backend. The ERP must configure and enable cash-out settings/counter first. QR scanning requires camera permission and, on the web, HTTPS/localhost. Verify camera scanning on a real phone before operational use.

`member_card.dart` displays the actual admin-issued membership card through `GET /api/membership/v1/card`, including current status, issue fee and print state. No card request or automatic issuance is performed. Members without an issued card see an empty state. Card numbers can be revealed/copied; demo CVV and expiry details have been removed.

Profile and KYC are connected to the membership backend. `profile_setup.dart` and `services/profile_service.dart` load/save the member profile and submit a camera selfie plus separate NID front/back images (camera or gallery for NID). Each image is limited to 5 MB. KYC displays the server review status; rejected submissions can be submitted again. The backend needs the `customer_kycs` migration. Camera capture still requires physical-device testing; no automated liveness verification is included.

- `auth.dart`: mobile, registration, recovery, OTP and PIN screens.
- `dashboard.dart`: home services, favorites, loan reminder, chart, promotions and transactions.
- `accounts.dart`, `payments.dart`, `payment_security.dart`: holdings and payment flows.
- `profile.dart`, `virtual_debit_card_widget.dart`, `legal_copy.dart`: profile, KYC, nominee, settings, support, card and legal content.
- `dialogs.dart`, `notifications.dart`: statements, account actions, project details and notification screen.
- `models.dart`, `seed_data.dart`, `state.dart`: models, supplied sample data and state.
- `assets/`: supplied fonts and artwork.

The original archive is preserved separately in the delivery's `original-backup` directory. This retains all original files, including unused components, alongside the runnable Flutter source.

## Existing behavior

Login is device-aware: a new installation verifies OTP before PIN login/setup; remembered installations sign in with phone and PIN. Device proof is saved separately per normalized phone. Forgot PIN uses OTP recovery. Clearing app/browser data requires OTP again. Local PIN fallback is disabled for sign-in. The backend needs the additive trusted-device migration; see its `docs/Membership/device-login.md` for protocol details.

The provided native `ApiConfig.kt` has no configured backend. This port retains the transfer and loan-payment server errors rather than making these actions debit the displayed balance. Repository-level local simulation helpers remain available, as in the original repository. OTP, biometric sign-in, QR scanning and other simulated operations are inherited demo behavior, not live banking integrations. Debug OTP is `1234`; the supplied PIN is `982341`.

## Verification and limits

- `flutter analyze --no-pub`: no issues.
- `flutter test`: 10 tests pass, covering login, repository bookkeeping, transfer blocking, profile routes, English/Bengali layouts, light/dark mode and offline overlay.
- `flutter build web --no-pub --web-renderer html`: successful.
- Local Edge browser: welcome → OTP → PIN → home exercised successfully.
- Android APK compilation and physical-device testing have not been performed because Android SDK / Java are unavailable here. Gallery and settings integration require device testing.
- The video covers only part of the application. This migration has not been established as pixel-identical across every screen; the complete original source is retained for further comparison.

The automated screenshot test writes to `../tori-reference/flutter` relative to this project.
