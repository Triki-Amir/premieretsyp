# Next Gen Power - Flutter Mobile App

A peer-to-peer energy trading platform built with Flutter, converted from the original React application.

## Features

- **User Authentication**: Login and signup functionality
- **Dashboard**: View available factories and energy trading opportunities
- **My Factory**: Monitor your factory's energy generation, consumption, and battery status
- **Trading Offers**: Browse and create energy buy/sell offers
- **Blockchain Explorer**: View transaction history and blockchain statistics
- **Profile Management**: Manage account settings and preferences

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Navigate to the flutter_application_1 directory:
   ```bash
   cd flutter_application_1
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## App Structure

```
lib/
├── main.dart                    # App entry point and navigation
├── models/                      # Data models
│   ├── energy_data.dart
│   ├── energy_offer.dart
│   ├── factory.dart
│   └── trade.dart
├── providers/                   # State management
│   └── energy_data_provider.dart
├── screens/                     # App screens
│   ├── blockchain_screen.dart
│   ├── dashboard_screen.dart
│   ├── login_screen.dart
│   ├── my_factory_screen.dart
│   ├── profile_screen.dart
│   └── smart_contracts_screen.dart
└── widgets/                     # Reusable widgets
    ├── energy_gauge.dart
    ├── offer_card.dart
    └── trade_card.dart
```

## Key Technologies

- **Flutter**: Cross-platform mobile framework
- **Provider**: State management solution
- **FL Chart**: Charting library for data visualization
- **Material Design**: UI component library

## Features Overview

### Login Screen
- Toggle between login and signup
- Email and password authentication
- Factory name registration for new users

### Dashboard
- Search and filter factories
- View energy balance charts
- Browse available factories with real-time data
- Initiate energy trades

### My Factory
- Real-time energy generation and consumption monitoring
- Energy source distribution (Solar, Wind, Footstep)
- Battery level tracking
- Daily summary statistics

### Trading Offers
- Create new buy/sell offers
- View all available market offers
- Quick trade execution
- Market statistics overview

### Blockchain Explorer
- Transaction history
- Blockchain network statistics
- Transaction details with block hashes

### Profile
- Account settings
- Notification preferences
- Privacy and security settings
- Sign out functionality

## Conversion Notes

This Flutter app is a faithful conversion of the original React mobile app with the following changes:
- React hooks → Flutter Provider pattern for state management
- TypeScript interfaces → Dart classes
- React components → Flutter widgets
- CSS styling → Flutter Material Design theming
- Recharts → FL Chart (with simplified implementations)

## Running the App

```bash
# For development
flutter run

# For Android release
flutter build apk

# For iOS release
flutter build ios
```

