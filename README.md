# swap

## Getting Started

# BookSwap

BookSwap is a cross-platform Flutter app for students to swap textbooks. It provides listing management, swap offers, and 1:1 chat threads between users. The project uses Firebase (Authentication, Firestore) for backend services and Provider + Firestore streams for state management.

---

## Quick facts

- Platform: Flutter (mobile, web, desktop supported by Flutter)
- Backend: Firebase (Auth, Firestore)
- State management: Provider + real-time Firestore streams
- Languages: Dart / Flutter

---

## Features

- Create and manage book listings
- Request a swap by offering one of your books
- Accept / reject / cancel swap offers
- Real-time chat (1:1) between users
- Optimistic UI updates for swap status transitions

---

## Repo layout (important files)

- `lib/main.dart` — app entry point
- `lib/ui/` — UI screens and widgets
	- `ui/auth/` — auth screens (`sign_in_screen.dart`, `sign_up_screen.dart`)
	- `ui/tabs/` — main tab screens (Listings, My Listings, Chats, Settings)
	- `ui/threads/` — chat UI
- `lib/models/` — data models (`book_listing.dart`, `swap_offer.dart`, `chat.dart`)
- `lib/services/` — Firestore & chat services (`firestore_service.dart`, `chat_service.dart`)
- `lib/providers/` — Provider classes (app settings, etc.)
- `lib/firebase_options.dart` — generated Firebase config (if using FlutterFire CLI)

---

## Prerequisites

- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)
- A Firebase project with Firestore and Authentication enabled
- Add platform config files to your project (when building platforms):
	- Android: `android/app/google-services.json`
	- iOS/macOS: `ios/Runner/GoogleService-Info.plist` / `macos/Runner/GoogleService-Info.plist`

Note: This repo includes `lib/firebase_options.dart` if configured via FlutterFire CLI. If not present, either run the FlutterFire CLI to generate this file or provide the platform files above.

---

## Setup & Run

1. Clone the repo and change into the app folder:

```powershell
cd C:\Users\HP\Downloads\bookapp\bookswap\swap
```

2. Install Dart/Flutter packages:

```powershell
flutter pub get
```

3. (Optional) If you haven't set up Firebase configuration for this project:

- Use the Firebase console to create a project and enable Authentication (Email/Password) and Firestore.
- Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS/macOS) as needed.
- Or run the FlutterFire CLI to configure and generate `lib/firebase_options.dart`:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Run the app:

```powershell
flutter run
```

5. Static analysis (quick check):

```powershell
dart analyze
```

---

## Firestore data model (summary)

- `listings` collection — stores book listings with fields like `ownerId`, `title`, `author`, `condition`, `pending`, `createdAt`.
- `swaps` collection — stores swap offers with `listingId`, `offeredBookId`, `senderId`, `recipientId`, `status`, `createdAt`.
- `threads` collection — chat threads with `participantIds` (sorted), `lastMessage`, `updatedAt`. Each thread has a `messages` subcollection.

---

## How swap state is modeled

- `status` in `swaps` documents: `pending`, `accepted`, `rejected`, `cancelled`.
- `pending` boolean in `listings` marks whether a book is currently committed to a swap (not available).
- UI uses optimistic updates: when a user accepts/rejects/cancels, the UI updates immediately and reverts if the Firestore write fails.

---

## State management

- Realtime streams from Firestore drive the UI updates (e.g., `FirestoreService.streamAllListings()`, `streamMyListings()`, `streamAllMyOffers()`).
- Provider is used for app-wide configuration (e.g., `AppSettingsProvider`).
- Local ephemeral UI state is used for optimistic updates (for example, `_pendingStatusUpdates` map tracks swaps currently being updated locally).

---

Common developer commands:

```powershell
flutter pub get
dart analyze
flutter run -d <deviceId>
```



## Notes & Future work

- Add pagination for listings and chat messages
- Add swap completion confirmation and more explicit transaction states for exchanged books
- Add group chats and richer messaging features
- Improve error handling & retry policies for Firestore writes

---

