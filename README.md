# Food Macros App

[](https://flutter.dev/)
[](https://www.python.org/)
[](https://fastapi.tiangolo.com/)
[](https://www.tensorflow.org/)

-----

## 📸 About the Project

The Food Macros App is a **cross-platform mobile application** built with **Flutter** that allows users to scan food items using their device's camera and instantly get a breakdown of its macronutrients (calories, protein, fat, carbohydrates, fiber, and sugar). The app features a **Python-based backend** powered by **FastAPI** and **TensorFlow**, which handles image classification and retrieves nutritional information from a pre-defined database.

### ✨ Features

  * **Food Scanning**: Capture photos of food items using your camera or select from your gallery.
  * **Instant Macro Analysis**: Get a detailed breakdown of calories, protein, fat, carbs, fiber, and sugar.
  * **Daily Goal Tracking**: Set personal macronutrient goals and track your daily intake progress.
  * **History Log**: View a history of your scanned food items and their nutritional details.
  * **Favorites**: Mark frequently consumed food items as favorites for quick access.
  * **Cross-Platform**: Available on iOS, Android, Web, macOS, Windows, and Linux.
  * **Dark Mode Support**: Adapts to system-wide dark mode preferences for a comfortable viewing experience.

-----

## 🚀 Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### 📋 Prerequisites

Before you begin, ensure you have the following installed:

  * **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
  * **Python 3.9+**: [Install Python](https://www.python.org/downloads/)
  * **Docker** (Optional, for backend deployment): [Install Docker](https://www.docker.com/get-started)

### 💻 Installation (Frontend - Flutter)

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/theuditbhardwaj/food_macros_app.git
    cd food_macros_app/food_macros
    ```

2.  **Get Flutter dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the Flutter application:**

    ```bash
    flutter run
    ```

    (Choose your desired platform: `flutter run -d chrome` for web, `flutter run -d <deviceName>` for mobile/desktop)

      * **Note for iOS**: You might need to adjust the `PRODUCT_BUNDLE_IDENTIFIER` and `DEVELOPMENT_TEAM` in `food_macros/ios/Runner.xcodeproj/project.pbxproj` and `food_macros/ios/Runner/Info.plist` for a physical device. Also, ensure **Local Network Access Permissions** are granted for the app to communicate with the backend.

### ☁️ Installation (Backend - Python/FastAPI)

You have two options to run the backend: directly or using Docker.

#### Option 1: Run Backend Directly

1.  **Navigate to the backend directory:**
    ```bash
    cd food_macros_app/food_macros_backend
    ```
2.  **Create and activate a virtual environment (recommended):**
    ```bash
    python -m venv venv
    # On Windows:
    .\\venv\\Scripts\\activate
    # On macOS/Linux:
    source venv/bin/activate
    ```
3.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Run the FastAPI application:**
    ```bash
    uvicorn main:app --host 0.0.0.0 --port 8090
    ```
    The backend API will be available at `http://0.0.0.0:8090`.

#### Option 2: Run Backend with Docker

1.  **Navigate to the backend directory:**
    ```bash
    cd food_macros_app/food_macros_backend
    ```
2.  **Build the Docker image:**
    ```bash
    docker build -t food-macros-backend .
    ```
3.  **Run the Docker container:**
    ```bash
    docker run -p 8090:8090 food-macros-backend
    ```
    The backend API will be available at `http://localhost:8090`.

### 🌐 Backend URL Configuration

The Flutter frontend needs to know where the backend is running. The `_backendApiUrl` in `food_macros/lib/tabs/scan_tab.dart` dynamically sets the URL:

```dart
// lib/tabs/scan_tab.dart
static String getBackendUrl() {
  if (Platform.isAndroid) {
    // Android emulator special alias for host machine
    return 'http://10.0.2.2:8090/predict_macros/'; // Changed to 8090
  } else if (Platform.isIOS) {
    // iOS physical device or simulator
    return 'http://localhost:8090/predict_macros/'; // Changed to 8090
  } else {
    // macOS, Windows, Linux, or Web
    return 'http://localhost:8090/predict_macros/'; // Changed to 8090
  }
}
```

-----

## 📁 Project Structure

```
theuditbhardwaj-food_macros_app/
├── README.md
├── food_macros/
│   ├── README.md
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── main_tab_view.dart
│   │   ├── models/
│   │   │   └── analysis_result.dart
│   │   ├── tabs/
│   │   │   ├── goals_tab.dart
│   │   │   ├── history_tab.dart
│   │   │   └── scan_tab.dart
│   │   └── utils/
│   │       └── app_colors.dart
│   ├── android/
│   ├── ios/
│   ├── linux/
│   ├── macos/
│   ├── test/
│   ├── web/
│   └── windows/
└── food_macros_backend/
    ├── class_names.txt
    ├── Dockerfile
    ├── food_classifier_model.h5
    ├── main.py
    ├── model.py
    ├── nutrition_database.json
    └── requirements.txt
```

-----

## 🛠️ Technologies Used

### Frontend

  * **Flutter**
  * **image_picker**
  * **http**
  * **shared_preferences**
  * **intl**

### Backend

  * **Python**
  * **FastAPI**
  * **TensorFlow / Keras**
  * **Pillow (PIL)**
  * **python-multipart**
  * **uvicorn**

-----
