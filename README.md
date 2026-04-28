# UniMatch

UniMatch is a mobile app that connects high school students with university students for tutoring. The experience is modeled after swipe-based matchmaking apps: students browse tutor profiles, swipe to express interest, and when both sides match, a chat opens so they can coordinate sessions.

It runs on Android, iOS, Web, Windows, Linux, and macOS.

---

## What the app does

A high school student signs up, builds a profile listing the subjects they need help with, and starts browsing university tutors. A university student does the same in reverse, listing the subjects they can teach. When both swipe right on each other, it is a match. From there, they chat directly inside the app to arrange tutoring sessions.

All communication stays within the app.

---

## Features

- Account creation and login
- Profile setup with photo upload
- Swipe-based browsing to find tutors or students
- Automatic matching when both sides express interest
- Real-time chat between matched users
- Push notifications for new matches

---

## Tech stack

- Built with Flutter, which allows it to run on mobile, web, and desktop from a single codebase
- Firebase handles user authentication, real-time messaging, file storage, and push notifications
- State is managed with Provider
- Notifications use Awesome Notifications and Flutter Local Notifications
- The swipe interface is built with Flutter Card Swiper

---

## Project structure

```
lib/
├── main.dart                  App entry point
├── firebase_options.dart      Firebase configuration
├── models/                    Data shapes: User, Match, Message, Swipe
├── providers/                 App-wide state: Auth, Match, Swipe
├── repositories/              Data access: Auth, User, Match, Swipe, Chat
├── screens/
│   ├── auth/                  Login and registration screens
│   ├── chat/                  Messaging interface
│   ├── matches/               Match list and match details
│   ├── profile/               Profile viewing and editing
│   ├── registration/          Onboarding flow
│   ├── shell/                 App navigation shell
│   └── swipe/                 Swipe interface
├── services/                  Firebase wrappers for Firestore and Storage
└── widgets/                   Reusable UI components
```

---
