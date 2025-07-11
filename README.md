# Idris Academy - E-Learning Mobile App

> A feature-rich e-learning mobile application built with Flutter, designed to provide a seamless and engaging learning experience.

This project is a comprehensive prototype for an educational platform, featuring user authentication, course management, progress tracking, and a mock support system. It is built using the Provider state management solution and currently operates with mock data for demonstration purposes.

---

## ✨ Features

-   **🔐 User Authentication**: Secure login and signup functionality. The app supports multiple mock user accounts to demonstrate different states (e.g., existing user vs. new user).
-   **📊 Personalized Dashboard**: Displays courses the user is currently enrolled in, their progress, and a list of recommended courses.
-   **📚 Rich Course Catalog**: A browsable list of all available courses, each with detailed information, modules, and submodules.
-   **🎓 Course Enrollment & Progress Tracking**:
    -   Users can enroll in courses from the catalog.
    -   Progress is calculated based on the completion of individual submodules.
    -   The app tracks the user's state for each submodule (completed/incomplete).
-   **🔔 Notification System**: An in-app notification center for course updates, messages, and announcements. Includes a badge count for unread notifications.
-   **📢 Important Announcements**: A system to display a pop-up announcement to users upon login.
-   **👤 Profile Management**:
    -   View user details and learning statistics (achievements).
    -   Update personal information like name, phone number, and profile picture.
    -   Securely update the account password after verifying the current one.
-   **💬 AI Support Chat (Mock)**: A simple, rule-based support chatbot to assist users with common questions. Designed for future integration with a real AI service like Gemini.

---

## 🛠️ Tech Stack

-   **Framework**: [Flutter](https://flutter.dev/)
-   **Language**: [Dart](https://dart.dev/)
-   **State Management**: [Provider](https://pub.dev/packages/provider) (using `ChangeNotifier`)
-   **Architecture**: The project follows a service-oriented approach, separating business logic (`UserService`) from the UI.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

You need to have the Flutter SDK installed on your machine. For instructions, please see the official Flutter documentation.

### Installation

1.  **Clone the repository**
    ```sh
    git clone https://github.com/your-username/idris_academy.git
    ```
2.  **Navigate to the project directory**
    ```sh
    cd idris_academy
    ```
3.  **Install dependencies**
    ```sh
    flutter pub get
    ```
4.  **Run the app**
    ```sh
    flutter run
    ```

### Mock User Credentials

You can use the following credentials to test the application:

-   **Existing User (with data):**
    -   **Username:** `testuser`
    -   **Password:** `testpassword`
-   **New User (no data):**
    -   **Username:** `newuser`
    -   **Password:** `newpassword`

---

## 📂 Project Structure

The project is organized into the following main directories:

```
lib/
├── main.dart             # App entry point
├── models/               # Data models (UserModel, CourseModel, etc.)
├── screens/              # UI for each page/screen of the app
├── services/             # Business logic and data handling (UserService)
└── widgets/              # Reusable UI components
```

---

## 📝 Note on Data

This application currently uses **mock data** hardcoded within `lib/services/user_service.dart`. All "database" operations (fetching courses, updating profiles, etc.) are simulated in memory. This allows for rapid UI development and testing without requiring a backend connection.

The next step would be to replace these mock data methods with real HTTP requests to a backend API (e.g., REST or GraphQL).

---

## 🔮 Future Improvements

-   [ ] **Backend Integration**: Replace the mock `UserService` with a real backend service (e.g., Firebase, Supabase, or a custom REST API).
-   [ ] **AI Chatbot Integration**: Connect the support chat to a real conversational AI like the Gemini API.
-   [ ] **Testing**: Add unit, widget, and integration tests to ensure code quality and stability.
-   [ ] **Payment Gateway**: Implement a payment system for premium subscription plans.
-   [ ] **UI/UX Enhancements**: Add animations and refine the user interface for a more polished look and feel.