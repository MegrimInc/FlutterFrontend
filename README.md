# Megrim Mobile App (Flutter)

Customer and merchant mobile app for Megrim. Customers browse merchants, place
orders, earn and redeem points, and pay in-app. Merchants can operate a
terminal-style flow and receive live order updates.

## What It Does

- Customer ordering with points, gratuity, tax, and service fees
- Stripe-based in-app payments and saved cards
- Real-time order updates via WebSockets
- Merchant terminal flow (including Bluetooth-based handoff)
- Push notifications and app version enforcement

## Tech Stack

- Flutter + Dart
- Firebase (Auth/Crashlytics/Messaging)
- Stripe (mobile SDK)
- WebSockets (Redis service)
- REST APIs (Postgres service)

## Project Structure

- `lib/main.dart`: app bootstrap, Firebase, push, initial login
- `lib/config.dart`: environment endpoints and version policy
- `lib/backend/`: data, websocket, cart, search
- `lib/UI/`: screens and flows for customer + terminal
- `lib/DTO/`: data transfer objects

## Local Development

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run on a device or simulator:
   ```bash
   flutter run
   ```

## Configuration

Endpoints are configured in `lib/config.dart`:

- Postgres service (REST): `postgres-*-http`
- Redis service (WS): `redis-*-ws`

Switch environments by editing `AppConfig.environment`.

## Related Services

- Postgres microservice: core REST API, auth, merchants, inventory, Stripe
- Redis microservice: live order flow and terminal coordination
- NextJS admin: merchant dashboard and onboarding
