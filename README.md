# DriveSense - Intelligent Driver Safety Assistant

<div align="center">
  <img src="assets/drivesense_logo.png" alt="DriveSense Logo" width="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.7.0-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
  [![AI/ML](https://img.shields.io/badge/AI%2FML-YOLO-green.svg)](https://github.com/ultralytics/yolov5)
  [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
</div>

## 📋 Table of Contents

- [Overview](#overview)
- [Related Repositories](#related-repositories)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## 🎯 Overview

DriveSense is an intelligent driver safety assistant system that monitors driving behavior in real-time using ESP32-CAM hardware and AI/ML technologies. The system detects risky behaviors such as drowsiness, phone usage, distraction, and intoxication, providing immediate alerts to enhance road safety.

### Key Technologies
- **Frontend**: Flutter (Dart) with MVVM architecture
- **Backend**: Node.js with MongoDB
- **Hardware**: ESP32-CAM for real-time video streaming
- **AI/ML**: YOLO object detection for behavior recognition
- **Authentication**: Google Sign-In integration
- **Messaging**: Firebase Cloud Messaging
- **Sensors**: Smartphone accelerometer for accident detection

## 🔗 Related Repositories

- **Main App**: [drivesense](https://github.com/Pudd11ng/drivesense) - Flutter mobile application
- **Backend API**: [drivesense-backend](https://github.com/Pudd11ng/drivesense-backend) - Node.js backend server
- **ESP32-CAM**: [drivesense-ESP32CAM](https://github.com/Pudd11ng/drivesense-ESP32CAM) - Camera module firmware

## ✨ Features

### 🚗 Real-time Monitoring
- **Drowsiness Detection**: Monitors eye closure and yawning patterns
- **Phone Usage Detection**: Identifies when driver is using mobile device
- **Distraction Detection**: Recognizes when driver attention is diverted
- **Intoxication Detection**: Monitors for signs of impaired driving
- **Accident Detection**: Uses smartphone accelerometer to detect sudden impacts

### 🔔 Smart Alerts
- **Audio Alerts**: Customized warning sounds for different behaviors
- **Visual Notifications**: In-app notifications with behavior details
- **Emergency Contacts**: Invitation-based emergency contact system with 24-hour invite codes
- **Push Notifications**: Real-time Firebase Cloud Messaging alerts
- **Cooldown System**: Prevents alert spam with 120-second intervals

### 📊 Analytics & Reporting
- **Behavior Tracking**: Historical data of driving patterns
- **Trip Reports**: Detailed analysis of each driving session
- **Safety Scores**: Calculated safety ratings based on behavior
- **Charts & Graphs**: Visual representation of driving data
- **AI-Powered Insights**: Personalized driving tips using Google Gemini AI

### 🔐 Security & Privacy
- **Google Sign-In**: Secure user authentication with Google accounts
- **JWT Authentication**: Secure token-based authentication with 24-hour expiry
- **Token Management**: Secure API token handling
- **Data Encryption**: Protected user data storage with bcrypt password hashing
- **Push Notifications**: Firebase Cloud Messaging for alerts

## 📋 Prerequisites

### Development Environment
- **Flutter SDK**: 3.7.0 or higher
- **Dart SDK**: 3.7.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

### Hardware Requirements
- **ESP32-CAM** module with DriveSense firmware ([firmware repository](https://github.com/Pudd11ng/drivesense-ESP32CAM))
  - Network: `drivesense_camera_ds000001`
  - Password: `password123`
  - Stream URL: `http://192.168.4.1`
- **Android device** for testing (with built-in accelerometer)

### External Services
- **Firebase Project** (Cloud Messaging only)
- **Google Cloud Platform** (Storage and AI services)
- **Freesound API** account for audio alerts
- **MongoDB** database for backend ([backend repository](https://github.com/Pudd11ng/drivesense-backend))
- **Gmail account** for email services (with app password)

## 🚀 Installation

### 1. Clone the Repository
```powershell
git clone https://github.com/Pudd11ng/drivesense.git
cd drivesense
```

### 2. Install Dependencies
```powershell
flutter pub get
```

### 3. Generate Code
```powershell
flutter packages pub run build_runner build
```

### 4. Configure Assets
```powershell
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

## ⚙️ Configuration

### 1. Environment Variables
Create a `.env` file in the root directory (use `.env.example` as template):

```properties
SERVER_ClIENT_ID='your-google-oauth-client-id'
BACKEND_URL='https://your-backend-url.com'
DEVICE_VIDEO_URL='http://192.168.4.1'
FREESOUND_API_KEY='your-freesound-api-key'
```

> **Note**: The `DEVICE_VIDEO_URL` should match your ESP32-CAM configuration. Default DriveSense firmware uses `http://192.168.4.1`.

### 2. Firebase Configuration

#### a) Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable Cloud Messaging

#### b) Configure Firebase Cloud Messaging
1. Go to Project Settings > Cloud Messaging
2. Add your Android app
3. Download `google-services.json` and place it in `android/app/`

#### c) Generate Firebase Config
```powershell
flutterfire configure
```

### 3. Freesound API Setup
1. Create account at [Freesound.org](https://freesound.org/)
2. Generate API key
3. Add key to `.env` file

## 📱 Usage

### 1. Initial Setup
1. Install app on Android device
2. Connect to ESP32-CAM WiFi network (`drivesense_camera_ds000001`)
3. Use network password: `password123`
4. Sign in with Google account
5. Grant necessary permissions (camera, microphone, location, accelerometer)

### 2. Starting Monitoring
1. Mount ESP32-CAM on dashboard facing driver (30-50cm distance)
2. Position camera at eye level for optimal face detection
3. Start monitoring session in app
4. System connects to camera stream at `http://192.168.4.1`
5. Real-time YOLO AI analysis begins (SVGA 800x600 @ 20fps)
6. Audio alerts play for detected behaviors with 120-second cooldown

### 3. Emergency Features
- **Invitation-based Emergency Contacts**: Generate 24-hour invite codes for emergency contacts
- **Automatic Accident Detection**: Real-time accident monitoring using smartphone accelerometer
- **Emergency Notifications**: Automatic alerts to all emergency contacts via FCM and email
- **Location Sharing**: GPS location sharing in case of accident
- **One-touch Emergency Calling**: Direct emergency service contact

## 📁 Project Structure

```
lib/
├── constants/           # App constants and configurations
│   ├── countries.dart
│   └── emergencyNumbers.dart
├── data/               # Data layer (currently empty)
├── domain/             # Business logic and entities
│   └── models/         # Data models
│       ├── accident/
│       ├── alert/
│       ├── device/
│       ├── driving_history/
│       ├── notification/
│       ├── risky_behaviour/
│       └── user/
├── routing/            # Navigation and routing
│   ├── router.dart
│   └── routes.dart
├── ui/                 # User interface components
│   ├── alert_notification/     # Alert and notification screens
│   ├── core/                  # Core UI components
│   ├── driving_history_analysis/  # Analytics and history screens
│   ├── monitoring_detection/   # Main monitoring screens
│   └── user_management/       # User authentication screens
├── utils/              # Utility functions and services
│   ├── accident_detection_service.dart
│   ├── audio_recording_service.dart
│   ├── auth_service.dart
│   ├── cloud_storage_service.dart
│   ├── fcm_service.dart
│   ├── network_binder.dart
│   └── sound_service.dart
├── firebase_options.dart
└── main.dart

assets/
├── audio/              # Additional audio files
├── audio alert/        # Audio files for alerts
│   ├── audio_alert_distraction.mp3
│   ├── audio_alert_drowsiness.mp3
│   ├── audio_alert_intoxication.mp3
│   └── audio_alert_phone_usage.mp3
├── drivesense_logo.png
├── drivesense_logo_white.png
├── drivesense_bottom.png
└── google_icon_logo.svg
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Style
- Follow Flutter/Dart conventions
- Use MVVM architecture pattern
- Add comprehensive comments
- Write unit tests for new features

## 🔍 Troubleshooting

### Common Issues

#### ESP32-CAM Connection
```powershell
# Check WiFi connection to ESP32-CAM
Test-NetConnection -ComputerName 192.168.4.1 -Port 80

# Verify video stream endpoint
Invoke-WebRequest -Uri "http://192.168.4.1/" -Method GET

# Test network connectivity
ping 192.168.4.1
```

#### WiFi Network Issues
```powershell
# Look for ESP32-CAM network
netsh wlan show profiles
# Should show: drivesense_camera_ds000001

# Connect to ESP32-CAM network
# Network: drivesense_camera_ds000001
# Password: password123
```

#### Firebase Configuration
```powershell
# Check Firebase configuration
flutter doctor -v

# Verify google-services.json exists
Get-Item android/app/google-services.json

# Test Firebase Cloud Messaging
# Check Firebase Console for message delivery
```

#### YOLO AI Model Issues
```powershell
# Check if YOLO detection is working
# Monitor app logs for AI processing errors
flutter logs | Select-String "YOLO"

# Verify camera stream quality
# Ensure SVGA (800x600) resolution from ESP32-CAM
# Check frame rate is stable at ~20fps
```

#### Common Camera Issues
```powershell
# Camera positioning problems
# - Ensure 30-50cm distance from driver
# - Position at eye level for face detection
# - Avoid backlighting and direct sunlight
# - Use stable 5V power supply in vehicle

# Connection stability
# - Check ESP32-CAM network: drivesense_camera_ds000001
# - Verify password: password123
# - Test stream: http://192.168.4.1
```

#### AI & Emergency System Issues
```powershell
# Google Gemini AI integration
# - Backend processes driving data for AI insights
# - Check Google Cloud Platform credentials
# - Verify Vertex AI API is enabled

# Emergency contact system
# - Uses invitation codes (24-hour expiry)
# - Check backend emergency contact API endpoints
# - Verify FCM and email notifications are working
```

### Debug Commands
```powershell
# View app logs
flutter logs

# Check dependencies
flutter pub deps

# Analyze code
flutter analyze

# Build for Android
flutter build apk
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **YOLOv11** for object detection framework
- **Google Gemini AI** for driving insights and recommendations
- **Firebase** for cloud messaging services
- **Google Cloud Platform** for storage and AI services
- **MongoDB Atlas** for database services
- **Flutter** team for the amazing framework
- **ESP32-CAM** community for hardware support
- **Freesound** for audio alert resources
- **ESP-IDF** framework by Espressif Systems
- **Node.js** and **Express.js** communities for backend framework

---

<div align="center">
  <p>Built with ❤️ for road safety</p>
  <p>© 2025 DriveSense. All rights reserved.</p>
</div>
