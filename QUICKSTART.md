# CityConnect - Quick Start Guide

## 🚀 5-Minute Setup

### Backend (Python)

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Setup environment
cp .env.example .env
# Edit .env and add your Anthropic API key

# 3. Run server
python app.py
# Server runs at http://localhost:5000
```

### Frontend (Flutter)

```bash
# 1. Get dependencies
flutter pub get

# 2. Run app
flutter run

# 3. (Optional) Update API URL in lib/services/api_service.dart
# Change baseUrl to your backend server
```

## 📱 Testing the App

### 1. Home Screen
- Shows quick action cards for all features
- Displays active accessibility settings

### 2. AR Explorer
- Tap camera icon at bottom
- Grant camera permission
- Point at a landmark
- Tap blue circle to detect
- See heritage info and narration

### 3. Report Issue
- Tap warning icon at bottom
- Take photo or select from gallery
- Select issue category
- Grant location permission (auto-detects GPS)
- Add optional description
- Submit report

### 4. Accessibility Settings
- Tap accessibility icon at bottom
- Toggle features on/off
- Changes apply instantly
- Settings persist across sessions

## 🔑 API Key Setup

1. Get Anthropic API key from [console.anthropic.com](https://console.anthropic.com/)
2. Create `.env` file:
   ```
   ANTHROPIC_API_KEY=sk-ant-...
   ```
3. Backend will use Claude Vision for landmark detection

## 📂 File Structure

```
lib/
├── main.dart                    # App entry point
├── screens/                     # All 4 screens
├── services/                    # API & accessibility
└── widgets/                     # Reusable components

app.py                          # Flask backend
requirements.txt                # Python packages
pubspec.yaml                    # Flutter packages
```

## 🎯 Key Features

✅ AR heritage detection with Claude Vision
✅ City issue reporting with GPS
✅ Full accessibility support (OKU)
✅ Voice narration
✅ High contrast mode
✅ Large font scaling
✅ Haptic feedback
✅ Wheelchair-friendly filter

## 🐛 Troubleshooting

**Camera not working?**
- Check permissions in app settings
- Restart app
- Ensure camera is available

**Location not detected?**
- Enable location services
- Grant location permission
- Check GPS signal

**Backend connection error?**
- Verify backend is running on port 5000
- Check API URL in `api_service.dart`
- Ensure CORS is enabled

**API key error?**
- Verify `.env` file exists
- Check API key is valid
- Restart Flask server

## 📚 Next Steps

1. **Add more heritage sites** - Edit `heritage_sites` in `app.py`
2. **Customize colors** - Edit theme in `main.dart`
3. **Add database** - Replace in-memory storage with SQLite/PostgreSQL
4. **Deploy** - Use Docker/Heroku for backend, Google Play/App Store for app

## 🎤 Demo Script

1. Open app → Show home screen
2. Tap Accessibility → Enable features
3. Go back to Home → Show active features indicator
4. Tap AR Explorer → Point at landmark → Detect
5. Tap Report Issue → Take photo → Submit
6. Show all 4 screens working

## 📞 Support

- Check README.md for detailed documentation
- Review API endpoints in app.py
- Test with curl/Postman for backend

---

**Ready to demo!** 🚀
