# Release Setup Guide for Vaidra

This guide will help you prepare the Vaidra app for Google Play Console submission.

## ✅ Completed Fixes

The following critical issues have been fixed:

1. ✅ **Application ID** - Changed to `com.healthcare.vaidra`
2. ✅ **Android Permissions** - Added INTERNET, CAMERA, and STORAGE permissions
3. ✅ **App Label** - Updated to "Vaidra" (capitalized)
4. ✅ **Debug Logs** - Replaced all `print()` with `debugPrint()`
5. ✅ **API URL Configuration** - Made configurable for production

## 🔴 Required Actions Before Release

### 1. Deploy Production Backend

Your app currently uses `http://10.0.2.2:8000` which only works on emulators. You need to:

**Option A: Deploy to Cloud Platform (Recommended)**
- Deploy to Railway, Render, Heroku, or similar
- Get your production URL (e.g., `https://vaidra-api.railway.app`)

**Option B: Use ngrok for Testing**
```bash
# In your backend directory
ngrok http 8000
# Copy the HTTPS URL provided
```

**Update the Production URL:**

Edit `vaidra/lib/services/api_service.dart` line 8:
```dart
static const String productionUrl = 'https://your-backend-url.com'; // Replace this
```

---

### 2. Generate Release Keystore

**CRITICAL**: Never use debug keys for production. Generate a proper release keystore:

```bash
# Navigate to android directory
cd vaidra/android

# Generate keystore (save the password securely!)
keytool -genkey -v -keystore vaidra-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vaidra
```

**You will be asked for:**
- Keystore password (save this!)
- Key password (save this!)
- Your name/organization details

**⚠️ IMPORTANT**: 
- Store the keystore file and passwords securely
- If you lose these, you can NEVER update your app on Play Store
- Consider using a password manager

---

### 3. Configure Release Signing

Create `vaidra/android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=vaidra
storeFile=vaidra-release-key.jks
```

Update `vaidra/android/app/build.gradle.kts`:

Replace the release signing section (around line 33) with:

```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

### 4. Secure Your API Keys

**CRITICAL**: Your Gemini API key is exposed in the `.env` file!

1. **Revoke the current key** in Google Cloud Console:
   - Go to https://console.cloud.google.com/apis/credentials
   - Find your API key
   - Delete or restrict it

2. **Generate a new key** and update `.env`

3. **Verify `.gitignore`** includes:
   ```
   .env
   *.jks
   *.keystore
   key.properties
   ```

---

## 🏗️ Building for Release

### Test Build (Debug)
```bash
cd vaidra
flutter build apk --debug
```

### Production Build (Release)

**APK (for direct installation):**
```bash
flutter build apk --release
```

**App Bundle (for Play Store - RECOMMENDED):**
```bash
flutter build appbundle --release
```

The App Bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

---

## ✅ Pre-Upload Checklist

Before uploading to Google Play Console:

- [ ] Backend deployed to production server
- [ ] Production URL updated in `api_service.dart`
- [ ] Release keystore generated and secured
- [ ] Release signing configured in `build.gradle.kts`
- [ ] Gemini API key revoked and replaced
- [ ] `.gitignore` updated to exclude sensitive files
- [ ] App tested on real Android device
- [ ] All features working with production backend
- [ ] Release build successful: `flutter build appbundle --release`

---

## 📱 Testing on Real Device

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Install on device:
   ```bash
   flutter install --release
   ```

3. Test all features:
   - Registration
   - Login
   - Image upload (camera)
   - Image upload (gallery)
   - Profile editing
   - History page
   - Dark mode
   - Language switching

---

## 🚀 Google Play Console Upload

1. Go to https://play.google.com/console
2. Create a new app
3. Fill in app details
4. Upload the App Bundle (`.aab` file)
5. Complete store listing
6. Submit for review

---

## 🔒 Security Reminders

**NEVER commit these files to git:**
- `.env`
- `vaidra-release-key.jks`
- `key.properties`
- Any file containing passwords or API keys

**Store securely:**
- Keystore file
- Keystore passwords
- API keys

---

## 📞 Need Help?

If you encounter issues:
1. Check the error message carefully
2. Verify all URLs are correct
3. Test backend connectivity
4. Ensure keystore is properly configured

---

**Good luck with your release! 🎉**
