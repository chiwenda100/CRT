# CRT Trading Journal

A local-first Flutter journal for recording forex trades using Candle Range Theory (CRT) setups and reviewing performance in R multiples.

## Features

- Record currency pair, long/short direction, date, session, CRT setup, outcome, and result in R.
- Optionally capture risk percentage, entry, stop loss, take profit, and execution notes.
- Review, search, filter, and delete logged trades.
- Attach a chart screenshot to each trade.
- Track net R, win rate, average R, profit factor, outcome totals, and a cumulative R curve.
- Store journal entries on the device using shared preferences. No account or broker connection is required.
- Developed by Radon Simba.

## Run

From this directory:

```sh
flutter pub get
flutter run
```

The project is configured for Android, iOS, web, and Windows. Build or run the platform supported by your local Flutter toolchain.

## Validate

```sh
flutter analyze
flutter test
```

This journal is for record keeping and performance review, not financial advice. Past performance does not predict future results.

## Firebase accounts

Firebase email/password sign-in and account registration require an owner-configured Firebase project. Enable Email/Password Authentication, Cloud Firestore, and Firebase Storage, then provide the Android `google-services.json` and FlutterFire-generated `lib/firebase_options.dart` before enabling account-backed cloud sync and screenshot uploads.
"# CRT" 
