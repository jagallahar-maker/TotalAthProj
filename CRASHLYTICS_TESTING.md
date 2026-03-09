# Firebase Crashlytics Testing Guide

## 🧪 Developer Tools Location

**Settings → Developer Tools** (at the bottom of the screen)

---

## 🐛 Test Crash (Fatal Error)

### What it does:
Forces an immediate app crash to verify fatal error reporting.

### When to use:
- First-time Firebase setup verification
- Before TestFlight submission
- After major Firebase configuration changes

### Expected behavior:
1. Tap "Test Crash (Crashlytics)"
2. Confirmation dialog appears
3. Tap "Trigger Crash"
4. Brief "Triggering test crash..." message
5. **App crashes and closes** after 0.5 seconds

### Verification:
- Wait **5-10 minutes**
- Open Firebase Console → Crashlytics
- Look for crash report: "Test crash from Developer Tools"
- Stack trace should show `CrashlyticsService.testCrash()`

---

## ⚠️ Test Non-Fatal Error

### What it does:
Logs an error to Firebase without crashing the app.

### When to use:
- Testing error logging without disruption
- Verifying Firebase connection
- Safe to use repeatedly during development

### Expected behavior:
1. Tap "Test Non-Fatal Error"
2. Confirmation dialog appears
3. Tap "Log Error"
4. Success message: "✅ Non-fatal error logged to Crashlytics"
5. **App continues running normally**

### Verification:
- Wait **5-10 minutes** (sometimes up to 1 hour)
- Open Firebase Console → Crashlytics
- Look for non-fatal error: "Test non-fatal error from Developer Tools"
- Error details include:
  - Exception message
  - Stack trace
  - Custom keys: `test_non_fatal_error: true`
  - Timestamp

---

## 📊 Context Logged with Errors

Both test methods automatically log:

### Standard Context:
- `test_crash: true` (for fatal crashes)
- `test_non_fatal_error: true` (for non-fatal errors)
- `test_timestamp`: ISO 8601 timestamp
- Custom log message

### App Context (always included):
- `environment`: development / production / beta
- `platform`: iOS, Android, Web
- `app_version`: from pubspec.yaml
- `build_number`: from pubspec.yaml
- `current_screen`: Last visited route
- `unit_preference`: kg or lb

### Workout Context (if applicable):
- `active_workout_id`
- `active_workout_name`
- `active_routine`
- `active_program`
- `exercise_count`

---

## 🎯 Best Practices

### Testing Sequence:

1. **First test**: Non-Fatal Error
   - Safe, won't disrupt development
   - Verifies Firebase connection
   - Check Firebase Console after 5-10 minutes

2. **Second test**: Fatal Crash
   - Only after non-fatal test succeeds
   - Confirms fatal crash reporting
   - App will need to be restarted

### Before TestFlight:

✅ Test both crash types  
✅ Verify reports in Firebase Console  
✅ Check stack traces are readable  
✅ Confirm custom context appears  
✅ Review Firebase project settings  

---

## 🔍 What You'll See in Firebase Console

### Fatal Crash Report:
```
Exception: Test crash from Developer Tools
Stack trace:
  CrashlyticsService.testCrash (crashlytics_service.dart:122)
  [... Flutter framework trace ...]

Custom Keys:
  test_crash: true
  environment: development
  platform: iOS
  current_screen: /settings
```

### Non-Fatal Error Report:
```
Exception: Test non-fatal error from Developer Tools
Reason: Testing Crashlytics non-fatal error reporting
Stack trace:
  [... Dart stack trace ...]

Custom Keys:
  test_non_fatal_error: true
  test_timestamp: 2024-01-15T10:30:00.000Z
  environment: development
```

---

## ⏰ Expected Timing

| Action | Time to Firebase Console |
|--------|--------------------------|
| Fatal Crash | 5-10 minutes |
| Non-Fatal Error | 10-60 minutes |
| First crash ever | Up to 1 hour |

**Note**: First crash after setup may take longer as Firebase provisions your Crashlytics dashboard.

---

## 🚨 Troubleshooting

### No crashes appearing in Firebase Console?

**Check these:**
1. Wait full 10 minutes (or 1 hour for non-fatal)
2. Verify `GoogleService-Info.plist` is in `ios/Runner/`
3. Ensure Crashlytics is enabled in Firebase Console
4. Try toggling Firebase Console filters:
   - All issues vs Open issues
   - All versions vs specific version
5. Clear app data and retry test

### App not crashing during test?

- This means Firebase is not initialized
- Check console logs for Firebase initialization errors
- Verify Firebase configuration files are present

### Error: "Crashlytics not initialized"?

- The test crash requires Firebase to be connected
- Add `GoogleService-Info.plist` to iOS project
- Rebuild: `flutter clean && flutter build ios`

---

## 💡 Pro Tips

### During Development:
- Use **Test Non-Fatal Error** frequently (safe)
- Use **Test Crash** sparingly (disrupts workflow)
- Check Firebase Console before each TestFlight build

### In Production:
- Crashlytics automatically captures all crashes
- No need to manually trigger tests
- Monitor Firebase Console for real user crashes

### Custom Error Logging:
```dart
import 'package:total_athlete/services/crashlytics_service.dart';

// In your code:
try {
  // risky operation
} catch (e, stack) {
  CrashlyticsService().recordError(
    e,
    stack,
    reason: 'Failed to save workout',
    fatal: false,
  );
}
```

---

## 📞 Need Help?

If crashes aren't appearing after following this guide:

1. Check `FIREBASE_SETUP.md` for configuration steps
2. Verify all Firebase files are properly added
3. Try a clean rebuild: `flutter clean && flutter build ios`
4. Check Xcode build logs for Firebase errors

---

**Happy testing! 🚀**

Remember: These tools are for **development and testing only**. Real crashes in production are automatically captured without any manual intervention.
