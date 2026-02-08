# 🌆 CityConnect — Smart City Companion

> **An inclusive smart city mobile app combining AR heritage exploration and city issue reporting — designed for everyone, including persons with disabilities (OKU).**
### YouTube Application Demo Video Link: https://youtu.be/BDw940f_RGE?si=kk3eCvQlwP4DViDi 
### YouTube PlymHack 2026 Reflection Video Link: https://youtu.be/y4J1TQn-2Zk?si=FyuM1Joxp7K2O8B5

## 🎯 Features

### AR Heritage Explorer
- Point your phone camera at historical landmarks
- AI-powered landmark recognition using Claude Vision API
- Instant historical information overlay
- Voice narration for visually impaired users
- Wheelchair accessibility information

### City Issue Reporting
- Capture photos of city problems (potholes, waste, broken facilities)
- Auto-detect GPS location
- Categorize issues (road damage, waste, lighting, accessibility, etc.)
- Submit reports directly to authorities
- Track report status

### Comprehensive Accessibility (OKU Features)
- **Visual Impairment**: Voice narration, large font mode (1x, 1.5x, 2x), high contrast
- **Mobility Disability**: Report issues without moving, wheelchair-friendly route filter
- **Hearing Impairment**: Visual notifications, text-based alerts, icon-based UI
- **Cognitive Disability**: Simple UI, large touch targets, step-by-step guidance

## 📱 Project Structure

```
cityconne-flutter-code/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── screens/
│   │   ├── home_screen.dart         # Home screen with quick actions
│   │   ├── ar_explorer_screen.dart  # AR heritage explorer
│   │   ├── report_issue_screen.dart # Issue reporting form
│   │   └── accessibility_screen.dart # Accessibility settings
│   ├── services/
│   │   ├── accessibility_service.dart # Accessibility state management
│   │   └── api_service.dart         # API client for backend
│   └── widgets/
│       └── (custom widgets)
├── pubspec.yaml                     # Flutter dependencies
├── app.py                           # Flask backend server
├── requirements.txt                 # Python dependencies
├── .env.example                     # Environment variables template
└── README.md                        # This file
```

## 🚀 Getting Started

### Prerequisites

| Badge | Description |
|-------|-------------|
| <div align="center">![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)</div> | **Flutter**: Install from [flutter.dev](https://flutter.dev/docs/get-started/install) |
| <div align="center">![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=FFD43B)</div> | **Python 3.8+**: Install from [python.org](https://www.python.org/) |
| <div align="center">![Android Studio](https://img.shields.io/badge/Android_Studio-3DDC84?style=for-the-badge&logo=android-studio&logoColor=white)</div> | **Android Studio** or ![Xcode](https://img.shields.io/badge/Xcode-147EFB?style=for-the-badge&logo=xcode&logoColor=white) **Xcode** (for mobile development) |
| <div align="center">![Anthropic](https://img.shields.io/badge/Anthropic-000000?style=for-the-badge&logoColor=white)</div> | **Anthropic API Key**: Get from [console.anthropic.com](https://console.anthropic.com/) |

### Backend Setup (Python)

1. **Navigate to project directory**
   ```bash
   cd cityconne-flutter-code
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Setup environment variables**
   ```bash
   cp .env.example .env
   # Edit .env and add your Anthropic API key
   ```

5. **Run Flask server**
   ```bash
   python app.py
   ```
   Server will start at `http://localhost:5000`

### Frontend Setup (Flutter)

1. **Navigate to project directory**
   ```bash
   cd cityconne-flutter-code
   ```

2. **Get Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API URL** (if needed)
   - Edit `lib/services/api_service.dart`
   - Change `baseUrl` to your backend server URL

4. **Run on device/emulator**
   ```bash
   flutter run
   ```

## 🔌 API Endpoints

### Heritage APIs

**Detect Heritage Site**
```
POST /api/heritage/detect
Body: { "imageBase64": "..." }
Response: { "detected": true, "site": {...} }
```

**Get Heritage List**
```
GET /api/heritage/list?wheelchairOnly=false
Response: { "sites": [...], "total": 5 }
```

**Get Heritage Details**
```
GET /api/heritage/<id>
Response: { "id": 1, "name": "...", ... }
```

### Issue APIs

**Create Issue Report**
```
POST /api/issues/create
Body: {
  "category": "road_damage",
  "photoBase64": "...",
  "latitude": 3.1413,
  "longitude": 101.6964,
  "address": "...",
  "description": "..."
}
Response: { "success": true, "issue": {...} }
```

**Get Issues List**
```
GET /api/issues/list?status=pending&category=road_damage
Response: { "issues": [...], "total": 5 }
```

**Get Issue Details**
```
GET /api/issues/<id>
Response: { "id": 1, "category": "...", ... }
```

**Update Issue Status**
```
PUT /api/issues/<id>/status
Body: { "status": "in_progress" }
Response: { "success": true, "issue": {...} }
```

## 🎨 Accessibility Features

### Visual Accessibility
- **High Contrast Mode**: Increases contrast for better visibility
- **Large Font Mode**: 1x, 1.5x, 2x font size options
- **Voice Narration**: Text-to-speech for all content

### Audio Accessibility
- **Haptic Feedback**: Vibration feedback for interactions
- **Visual Notifications**: Icons and visual indicators

### Motor Accessibility
- **Large Touch Targets**: Bigger buttons and tap areas
- **Simplified Navigation**: Reduced gesture complexity

### Mobility Accessibility
- **Wheelchair-Friendly Filter**: Show only accessible sites
- **GPS-Based Reporting**: Report issues without moving

## 🧪 Testing

### Test AR Detection
1. Open AR Explorer tab
2. Grant camera permission
3. Point camera at a heritage site (or use test image)
4. Tap "Capture and Detect"
5. Should show landmark info and narration

### Test Issue Reporting
1. Open Report Issue tab
2. Grant camera and location permissions
3. Take photo of any object
4. Select category
5. Verify location is auto-detected
6. Submit report

### Test Accessibility
1. Open Accessibility Settings
2. Enable High Contrast → UI should change
3. Set Font Size to Large → Text should scale
4. Enable Voice Narration → Content should be read aloud
5. Enable Wheelchair-Friendly Filter → Only accessible sites shown

## 📦 Dependencies

### Flutter
- `provider`: State management
- `http`: HTTP requests
- `image_picker`: Photo selection
- `camera`: Camera access
- `geolocator`: GPS location
- `flutter_tts`: Text-to-speech
- `shared_preferences`: Local storage

### Python
- `Flask`: Web framework
- `Flask-CORS`: Cross-origin requests
- `anthropic`: Claude API client
- `python-dotenv`: Environment variables

## 🔐 Security Notes

- Store API keys in `.env` file (never commit to git)
- Use HTTPS in production
- Validate all user inputs on backend
- Implement authentication for production
- Add rate limiting for API endpoints

## 🚀 Deployment

### Backend Deployment (Python)
```bash
# Using Gunicorn
pip install gunicorn
gunicorn app:app

# Using Docker
docker build -t cityconne-backend .
docker run -p 5000:5000 cityconne-backend
```

### Frontend Deployment (Flutter)
```bash
# Build APK for Android
flutter build apk

# Build IPA for iOS
flutter build ios

# Build Web
flutter build web
```

## 📝 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions:
1. Check existing GitHub issues
2. Create a new issue with detailed description
3. Include screenshots/logs if applicable

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Anthropic Claude API](https://docs.anthropic.com/)
- [Material Design Guidelines](https://material.io/design)

## 🌟 Acknowledgments

- Built for hackathon focused on SDG 11 (Sustainable Cities)
- Inspired by inclusive design principles
- Thanks to the Flutter and Flask communities

---

**CityConnect** - Making cities more accessible, one report at a time. 🌍♿
