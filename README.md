# Zamzam - Premium Stationery App

![Zamzam App](https://images.unsplash.com/photo-1583485088034-4e089a1cb798?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=300&q=80)

## Overview

> **Note:** This project is developed for a real client and is used in a production environment.

Zamzam is a Flutter-based e-commerce application specializing in premium stationery products. The app provides a seamless shopping experience for users looking to purchase high-quality pens, notebooks, art supplies, and other stationery items.

## Features

- **User Authentication**
  - Email & Password login/signup
  - Password recovery
  - Guest browsing option

- **Product Browsing**
  - Category-based filtering
  - Search functionality
  - Featured products showcase
  - Detailed product information

- **Shopping Experience**
  - Add to cart functionality
  - Wishlist management
  - Order tracking
  - Secure checkout process

- **User Profile**
  - Personal information management
  - Order history
  - Address management
  - Account settings

- **UI/UX**
  - Clean, intuitive interface
  - Responsive design
  - Smooth animations
  - Consistent theme

## Technologies

- **Frontend**: Flutter/Dart
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Realtime Database
  - Storage
- **APIs**: RESTful API integration for product data

## Getting Started

### Prerequisites

- Flutter (latest stable version)
- Dart SDK
- Android Studio / VS Code
- A Firebase account

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/Mohamedbasem1/ZamZam-Mobile-App.git
   ```

2. Navigate to the project directory:
   ```
   cd zamzam
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Connect to Firebase:
   - Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/)
   - Follow the Firebase setup instructions for Flutter
   - Download the `google-services.json` file for Android and/or `GoogleService-Info.plist` for iOS and place in the respective app directories

5. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── constants/        # App constants (themes, images, etc.)
├── models/           # Data models
├── pages/            # UI screens
├── services/         # Business logic and API services
├── widgets/          # Reusable UI components
└── main.dart         # App entry point
```

## Firebase Setup

The app requires Firebase for backend services. You'll need to:

1. Create a Firebase project
2. Enable Authentication (Email/Password)
3. Set up Cloud Firestore with proper security rules
4. Configure Firebase Storage if needed

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Project Link: [https://github.com/yourusername/zamzam](https://github.com/yourusername/zamzam)

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Unsplash](https://unsplash.com/) for images
- [Material Design](https://material.io/)
