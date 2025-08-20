# MoodMind Consultant App

A companion Flutter app for mental health consultants to interact with clients using chat, and monitor their mood trends over time. This app integrates tightly with the main MoodMind system.

---

## ✨ Features

- 💬 **Real-time Chat**: Secure messaging between consultant and clients.
- 📊 **Mood Statistics**: View charts and patterns of client moods over time.
- 🔐 **Secure Login**: Firebase-based authentication.
- ⚡ **Responsive UI**: Works seamlessly on mobile and tablet.
- 🧠 **Client Context**: Access historical entries, mood data, and chat history.

---

## 📁 Directory Structure (Core Files)

```
lib/
├── screens/
│   ├── login_screen.dart
│   ├── sign_up_screen.dart
│   ├── consultants_list_screen.dart
│   ├── chat_screen.dart
│   └── statistics_screen.dart
├── models/
│   ├── user_model.dart
│   ├── consultant_model.dart
│   ├── mood_statistics_model.dart
│   └── diary_entry_model.dart
```

---

## 🛠 Installation Guide

### ⚙️ Requirements

- Flutter SDK (≥ 3.10)
- Dart SDK (bundled with Flutter)
- Firebase project setup (optional but recommended for authentication and real-time chat)

---

### 🔽 Install Dependencies

```bash
git clone https://github.com/your-org/moodmind-consultant.git
cd moodmind-consultant
flutter pub get
```

---

### 🚀 Run the App

#### Local Development:

```bash
flutter run
```

#### With Firebase (make sure to add your Firebase config files):

```bash
flutter run
```

---

### 📦 Build for Production

```bash
flutter build apk --release
```

Or for iOS:

```bash
flutter build ios --release
```

---

## 🔐 Firebase & Secrets

Place your Firebase files in the correct locations (ignored by Git):

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Ensure you’ve added Firebase initialization per [FlutterFire docs](https://firebase.flutter.dev/docs/overview/).

---

## 🧪 Testing

Run Flutter analyzer and test suite:

```bash
flutter analyze
flutter test
```

---

## 🤝 Contributing

1. Fork this repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes
4. Push and open a Pull Request
---

## 💡 Roadmap Ideas

- Push notifications for new messages
- Mood trend alerts for consultants
- Appointment scheduling
