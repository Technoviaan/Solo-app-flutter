# Solo App - Research & Development (RND) Document

## Project Overview
Solo App is a Flutter-based mobile application designed for personal use, likely involving contact management, check-ins, and subscription-based features. It uses modern Flutter practices, including the BLoC pattern for state management and an organized feature-based directory structure.

## Technical Stack
- **Framework**: Flutter (compatible with 3.38.1+)
- **State Management**: BLoC (Business Logic Component) via `flutter_bloc`.
- **Network**: HTTP for REST API communication.
- **Storage**: `flutter_secure_storage` for tokens, `shared_preferences` for local data.
- **Notifications**: `flutter_local_notifications` for local alerts.
- **Android Level**: Upgraded to support AGP 8.9.1 and Gradle 8.12.

## Project Structure
```
lib/
├── core/               # Shared infrastructure
│   ├── network/        # API configurations and base clients
│   ├── storage/        # Secure and local storage management
│   └── utils/          # Common utilities
├── home/               # Main application features (Check-in, Contacts)
├── loginWithNumber/    # Auth flow (Login, OTP, Onboarding)
├── subscription/       # Subscription and payment features
├── widgets/            # Reusable UI components
├── main.dart           # App entry point
└── app.dart            # Root widget and theme configuration
```

## Workflows & Feature Flows

### 1. Authentication & Onboarding
- **Onboarding**: Greets the user and directs them to the login flow.
- **Login**: User enters their mobile number.
- **OTP Verification**: Verifies the user via an OTP sent to their mobile number.
- **Profile Setup**: New users are prompted to enter their name and email through separate onboarding screens.

### 2. Contacts Management
- **Manual Mode**: Currently, the app allows users to manually add and manage up to two emergency or primary contacts.
- **Subscription Lock**: Access to the contact feature or the number of contacts may be limited by the user's subscription status.

### 3. Subscription Flow
- Users can view and purchase subscription plans. The state of the subscription affects certain app features (like the number of contacts they can save).

---

## API Implementation Details
**Base URL**: `https://mvp-backend-3rq1.onrender.com/api`

### Key Endpoints
| Feature | API Class | Description |
| :--- | :--- | :--- |
| Authentication | `AuthApi` | Handles login and OTP verification. |
| User Profile | `UserNameApi`, `UserEmailApi` | Updates user details during onboarding. |
| Account Mgmt | `DeleteAccountApi` | Permanently deletes user account. |

### Network Layer Pattern
The app uses a consistent pattern for API calls:
1. Define the endpoint in `api_config.dart`.
2. Implement an API class that handles the request and parses the response.
3. Integrate the API call within a BLoC to manage loading, success, and error states.

---

## Build System & Maintenance (Recent Fixes)

The project underwent a significant build system upgrade to remain compatible with modern Android requirements:

### 1. Build Tools Upgrade
- **Gradle**: Upgraded to **8.12**.
- **Android Gradle Plugin (AGP)**: Upgraded to **8.9.1**.
- **Kotlin**: Updated to **2.1.0**.

### 2. Compatibility Fixes
- **Core Library Desugaring**: Enabled to support Java 8+ features on older Android devices, specifically for `flutter_local_notifications`.
- **Namespace Injection**: A custom script was added to `android/build.gradle` to automatically inject namespaces into legacy plugins, preventing "Namespace not specified" errors.
- **Manifest Cleanup**: The same script automatically removes the legacy `package` attribute from plugin manifests, which is no longer supported in AGP 8.0+.

### 3. Removed Dependencies
- **`contacts_service`**: Removed due to its reliance on the deprecated `Registrar` API, which prevented compilation. The application now uses a custom manual contact entry system.

---

## How to Build the Project
To build the project for Android, run:
```bash
flutter clean
flutter pub get
flutter build apk --debug --android-skip-build-dependency-validation
```
*Note: The `--android-skip-build-dependency-validation` flag is recommended if there are minor version warnings from non-critical sub-dependencies.*
