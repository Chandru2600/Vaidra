# Vaidra - AI-Powered Healthcare Platform

<div align="center">

![Vaidra Logo](vaidra.png)

**Instant Medical Image Analysis with AI**

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Latest-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Google Gemini](https://img.shields.io/badge/Google-Gemini%20AI-4285F4?logo=google)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Features](#features) • [Quick Start](#quick-start) • [Architecture](#architecture) • [Documentation](#documentation)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [API Documentation](#api-documentation)
- [Configuration](#configuration)
- [Development](#development)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

---

## 🌟 Overview

**Vaidra** is a cross-platform mobile healthcare application that leverages Google's Gemini AI to provide instant medical image analysis. Users can upload photos of skin conditions and receive immediate AI-powered diagnosis with severity assessment, first aid guidance, and doctor recommendations.

### Problem Statement
Patients often struggle to identify skin conditions and need quick preliminary guidance before consulting a doctor. Traditional healthcare requires scheduling appointments, which can delay treatment for urgent conditions.

### Solution
- **Instant AI Analysis**: Upload a photo, get immediate condition identification
- **Severity Assessment**: Understand if the condition is MINOR, MODERATE, or URGENT
- **First Aid Guidance**: Receive step-by-step care instructions
- **Medical History**: Track all scans and conditions over time
- **Multi-language Support**: English, Tamil, Hindi

---

## ✨ Features

### 🔐 User Authentication
- Secure JWT-based authentication
- Password hashing with bcrypt
- Profile management with medical history
- Persistent login sessions

### 🤖 AI-Powered Analysis
- Google Gemini Flash vision model
- Instant skin condition identification
- Confidence score (0-100%)
- Severity classification (MINOR/MODERATE/URGENT)
- First aid recommendations
- Warning signs to watch for

### 📊 Scan History
- View all previous scans
- Track condition progression
- Pull-to-refresh functionality
- Date-based organization

### 👤 Profile Management
- Edit personal information
- Medical conditions tracking
- Allergy management
- Age and gender-based insights

### 🌙 Dark Mode
- System-wide dark theme
- Persistent preference
- Smooth theme transitions
- Battery-friendly OLED support

### 🌍 Multi-language
- English
- Tamil (தமிழ்)
- Hindi (हिंदी)
- Easy language switching

---

## 🛠 Technology Stack

### Frontend (Mobile App)

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.8+ | Cross-platform UI framework |
| **Dart** | 3.8+ | Programming language |
| **Provider** | 6.1+ | State management |
| **Dio** | 5.9+ | HTTP client for API calls |
| **image_picker** | 1.1+ | Camera/gallery access |
| **shared_preferences** | 2.5+ | Local storage |

### Backend (API Server)

| Technology | Version | Purpose |
|------------|---------|---------|
| **FastAPI** | Latest | Web framework |
| **Python** | 3.9+ | Programming language |
| **SQLAlchemy** | Latest | ORM for database |
| **Pydantic** | Latest | Data validation |
| **JWT** | Latest | Authentication tokens |
| **bcrypt** | Latest | Password hashing |
| **Google Generative AI** | Latest | Gemini AI integration |
| **PIL/Pillow** | Latest | Image processing |

### Database & Storage

| Component | Technology |
|-----------|------------|
| **Development** | SQLite |
| **Production** | PostgreSQL-ready |
| **Migrations** | Alembic |
| **File Storage** | Local filesystem (S3-ready) |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  MOBILE APP (Flutter)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │  Home    │  │  Profile │  │  History │             │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘             │
│       │             │              │                    │
│       └─────────────┴──────────────┘                    │
│                     │                                   │
│              API Service (Dio)                          │
└─────────────────────┼───────────────────────────────────┘
                      │ REST API (JSON)
                      │
┌─────────────────────▼───────────────────────────────────┐
│              BACKEND (FastAPI)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │   Auth   │  │  Scans   │  │  Doctor  │             │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘             │
│       │             │              │                    │
│  ┌────▼─────────────▼──────────────▼─────┐             │
│  │         Database (SQLite/PostgreSQL)   │             │
│  └────────────────────────────────────────┘             │
│                     │                                   │
│              ┌──────▼──────┐                           │
│              │  AI Client  │                           │
│              └──────┬──────┘                           │
└─────────────────────┼───────────────────────────────────┘
                      │ API Call
                      │
          ┌───────────▼────────────┐
          │  Google Gemini AI      │
          │  (Vision Analysis)     │
          └────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** 3.8 or higher
- **Python** 3.9 or higher
- **Google Gemini API Key** ([Get one here](https://ai.google.dev))

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/vaidra.git
cd vaidra
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env

# Edit .env and add your Gemini API key
# GEMINI_API_KEY=your_api_key_here

# Run database migrations
alembic upgrade head

# Start backend server
uvicorn app.main:app --reload
```

Backend will be running at `http://localhost:8000`

### 3. Frontend Setup

```bash
# Navigate to frontend directory
cd vaidra

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 4. Access the App

- **Mobile App**: Opens automatically on your device/emulator
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

---

## 📁 Project Structure

```
Vaidra/
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── main.py            # FastAPI app entry point
│   │   ├── auth.py            # Authentication endpoints
│   │   ├── scans.py           # Scan analysis endpoints
│   │   ├── doctor.py          # Doctor recommendation endpoints
│   │   ├── ai_client.py       # Gemini AI integration
│   │   ├── models.py          # SQLAlchemy models
│   │   ├── schemas.py         # Pydantic schemas
│   │   ├── config.py          # Configuration
│   │   ├── db.py              # Database connection
│   │   ├── storage.py         # File storage
│   │   └── utils.py           # Utility functions
│   ├── alembic/               # Database migrations
│   ├── uploads/               # Uploaded images
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile             # Docker configuration
│   └── .env.example           # Environment variables template
│
├── vaidra/                    # Flutter frontend
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── screens/           # UI screens
│   │   │   ├── homePage.dart
│   │   │   ├── profilePage.dart
│   │   │   ├── historyPage.dart
│   │   │   ├── loginPage.dart
│   │   │   ├── register.dart
│   │   │   └── editProfilePage.dart
│   │   ├── services/
│   │   │   └── api_service.dart  # API client
│   │   ├── providers/
│   │   │   └── theme_provider.dart  # Theme management
│   │   └── screens/
│   │       └── language_provider.dart  # Localization
│   ├── assets/
│   │   └── translations/      # Language files
│   ├── pubspec.yaml           # Flutter dependencies
│   └── android/ios/web/       # Platform-specific code
│
├── PROJECT_DOCUMENTATION.md   # Detailed technical docs
├── README.md                  # This file
└── docker-compose.yml         # Docker Compose config
```

---

## 📚 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "John Doe",
  "age": 30,
  "gender": "Male"
}
```

#### Login
```http
POST /auth/login
Content-Type: application/x-www-form-urlencoded

username=user@example.com&password=securepassword
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

#### Get Profile
```http
GET /auth/profile
Authorization: Bearer {token}
```

#### Update Profile
```http
PUT /auth/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "John Doe",
  "age": 31,
  "conditions": "Diabetes",
  "allergies": "Penicillin"
}
```

### Scan Endpoints

#### Analyze Image
```http
POST /scans/analyze
Content-Type: multipart/form-data

scan_image: <file>
user_id: 1 (optional)
```

**Response:**
```json
{
  "scan_id": 123,
  "result": {
    "condition": "Eczema (Atopic Dermatitis)",
    "confidence": 85,
    "severity": "MODERATE",
    "steps": [
      "Apply fragrance-free moisturizer",
      "Avoid scratching the area",
      "Use cool compress for itching"
    ],
    "warnings": [
      "Watch for signs of infection",
      "Consult doctor if symptoms worsen"
    ]
  }
}
```

#### Get Recent Scans
```http
GET /scans/recent
Authorization: Bearer {token}
```

### Doctor Endpoints

#### Find Nearby Doctors
```http
GET /doctors/nearby?lat=12.9716&lng=77.5946&specialty=dermatology
```

---

## ⚙️ Configuration

### Backend Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# Gemini AI
GEMINI_API_KEY=your_gemini_api_key_here

# JWT Authentication
SECRET_KEY=your_secret_key_here
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# File Storage
UPLOAD_DIR=./uploads

# Database (optional, defaults to SQLite)
DATABASE_URL=sqlite:///./vaidra.db
# For PostgreSQL:
# DATABASE_URL=postgresql://user:password@localhost/vaidra
```

### Frontend Configuration

API base URL is automatically configured in `lib/services/api_service.dart`:
- **Web**: `http://localhost:8000`
- **Android Emulator**: `http://10.0.2.2:8000`
- **iOS/Desktop**: `http://localhost:8000`

---

## 💻 Development

### Running Tests

#### Backend Tests
```bash
cd backend
pytest
```

#### Frontend Tests
```bash
cd vaidra
flutter test
```

### Code Formatting

#### Backend
```bash
black app/
isort app/
```

#### Frontend
```bash
flutter format lib/
```

### Linting

#### Backend
```bash
flake8 app/
```

#### Frontend
```bash
flutter analyze
```

---

## 🐳 Docker Deployment

### Using Docker Compose

```bash
# Build and start services
docker-compose up --build

# Run migrations
docker-compose exec backend alembic upgrade head

# Stop services
docker-compose down
```

### Manual Docker Build

#### Backend
```bash
cd backend
docker build -t vaidra-backend .
docker run -p 8000:8000 --env-file .env vaidra-backend
```

---

## 🌐 Production Deployment

### Backend (Heroku/Railway/Render)

1. Set environment variables
2. Use PostgreSQL database
3. Configure S3 for file storage
4. Enable CORS for your domain

### Frontend (App Stores)

#### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

---

## 🔒 Security

- ✅ JWT token authentication
- ✅ Password hashing with bcrypt
- ✅ Input validation with Pydantic
- ✅ CORS configuration
- ✅ SQL injection prevention (SQLAlchemy ORM)
- ✅ File upload validation

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

---

## 🙏 Acknowledgments

- Google Gemini AI for vision analysis
- Flutter team for the amazing framework
- FastAPI for the modern Python web framework
- All contributors and testers

---

## 📞 Support

For support, email support@vaidra.com or open an issue on GitHub.

---

## 🗺 Roadmap

### Phase 2 Features
- [ ] Telemedicine video consultations
- [ ] Prescription management
- [ ] Medication reminders
- [ ] Health analytics dashboard
- [ ] Insurance integration

### Technical Improvements
- [ ] PostgreSQL migration
- [ ] S3 cloud storage
- [ ] Redis caching
- [ ] WebSocket real-time updates
- [ ] CI/CD pipeline
- [ ] Kubernetes deployment

---

<div align="center">

**Made with ❤️ for better healthcare**

[⬆ Back to Top](#vaidra---ai-powered-healthcare-platform)

</div>
