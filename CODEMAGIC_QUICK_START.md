# Codemagic Quick Start - Total Athlete

## 🚀 Get Your First Build in 5 Steps

### Step 1: Connect Repository to Codemagic
1. Go to [codemagic.io](https://codemagic.io) and sign up/login
2. Click **"Add application"**
3. Select your Git provider (GitHub, GitLab, or Bitbucket)
4. Authorize Codemagic to access your repositories
5. Select the **Total Athlete** repository

### Step 2: Set Up App Store Connect Integration
1. In Codemagic, go to **Teams** → **Integrations**
2. Click **App Store Connect** → **Add key**
3. Get your API credentials from [App Store Connect](https://appstoreconnect.apple.com/access/api):
   - Go to **Users and Access** → **Keys** → **App Store Connect API**
   - Click **+** to generate a new key
   - Download the `.p8` file
   - Copy the **Key ID** and **Issuer ID**
4. In Codemagic:
   - Upload the `.p8` file
   - Enter **Key ID** and **Issuer ID**
   - Click **Save**

### Step 3: Configure Code Signing

**Option A: Automatic (Recommended)**
1. In app settings → **iOS code signing**
2. Select **"Automatic code signing"**
3. Choose your App Store Connect integration
4. Select distribution profile for `com.justingallahar.totalathlete`
5. Click **Save**

**Option B: Manual**
1. Export your **Distribution Certificate** (.p12) from Keychain Access
2. Download your **App Store Distribution Provisioning Profile** from Apple Developer
3. In Codemagic app settings → **iOS code signing**
4. Upload certificate (.p12) and provisioning profile
5. Enter certificate password

### Step 4: Create App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps** → **+** icon → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: Total Athlete
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: com.justingallahar.totalathlete (must match!)
   - **SKU**: total-athlete-001
4. Click **Create**
5. Note the **App ID** (found in App Information)

### Step 5: Set Environment Variables & Build
1. In Codemagic app settings → **Environment variables**
2. Add variable:
   - **Name**: `APP_STORE_ID`
   - **Value**: [Your App ID from Step 4]
   - Check **"Secure"**
3. Click **Save**
4. Go to app main page → **Start new build**
5. Select branch: `main` (or your branch)
6. Select workflow: `ios-workflow`
7. Click **Start new build**

## ⏱️ Build Timeline

- **Typical build time**: 10-15 minutes
- **Steps to watch**:
  1. ✅ Clone repository (1 min)
  2. ✅ Set up Flutter (2 min)
  3. ✅ Get packages (1 min)
  4. ✅ Install pods (2 min)
  5. ✅ Flutter analyze (1 min)
  6. ✅ Build IPA (5-8 min)
  7. ✅ Upload to TestFlight (2 min)

## 🎯 What Happens After Build

### Successful Build
- ✅ IPA artifact available for download
- ✅ Build automatically uploaded to TestFlight
- ✅ Email notification sent
- ✅ Build appears in App Store Connect → TestFlight
- ⏳ Processing time in TestFlight: 5-20 minutes

### Failed Build
- ❌ Check build logs for errors
- 📧 Email notification with error
- 🔍 Common fixes below

## 🐛 Common Issues & Quick Fixes

### "Code signing error"
**Fix**: Verify provisioning profile matches bundle ID exactly
- Expected: `com.justingallahar.totalathlete`
- Check profile hasn't expired
- Regenerate profile if needed

### "Flutter analyze failed"
**Fix**: Run locally first
```bash
flutter analyze
```
Fix any errors before pushing

### "Pod install failed"
**Fix**: Usually auto-resolves. If not:
```bash
cd ios
pod install
pod update
cd ..
git add ios/Podfile.lock
git commit -m "Update Podfile.lock"
git push
```

### "Build number already exists"
**Fix**: Ensure `APP_STORE_ID` is set correctly
- The workflow auto-increments based on TestFlight
- Check you created the app in App Store Connect (Step 4)

### "Archive not found"
**Fix**: Check build scheme
- Should be: `Runner`
- Verify in `codemagic.yaml` → `XCODE_SCHEME: "Runner"`

## 📱 Testing Your Build

### Install from TestFlight
1. Download **TestFlight** app from App Store
2. Log in with your Apple ID (same as App Store Connect)
3. Accept the TestFlight invite (sent to your email)
4. Install **Total Athlete**
5. Test all core workflows (see CI_READINESS_CHECKLIST.md)

### Test These Critical Flows
- ✅ Start workout → log sets → finish
- ✅ Start routine workout → navigate exercises
- ✅ Log bodyweight with custom date
- ✅ View analytics charts
- ✅ Weight displays in pounds correctly

## 🔄 Making Updates

### Trigger New Build
1. Make code changes locally
2. Commit and push to Git
3. Codemagic automatically starts build (if configured)
4. Or manually trigger from dashboard

### Version Bumping
Update in `pubspec.yaml`:
```yaml
version: 1.0.1+2  # version+build number
```
- **Version** (1.0.1): User-facing version
- **Build** (+2): Internal build number (auto-incremented by Codemagic)

## 📧 Update Email Notification

Edit `codemagic.yaml`:
```yaml
publishing:
  email:
    recipients:
      - your-email@example.com  # Change this!
```

## 🎓 Next Steps

After successful build:
1. ✅ Test app thoroughly in TestFlight
2. ✅ Add external testers (optional)
3. ✅ Prepare App Store listing:
   - Screenshots
   - Description
   - Keywords
   - Privacy policy
4. ✅ Submit for App Store review
5. ✅ Set up automatic builds on push

## 📚 Resources

- [Codemagic Flutter iOS docs](https://docs.codemagic.io/flutter-publishing/publishing-to-app-store/)
- [Apple Developer Portal](https://developer.apple.com/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [TestFlight Help](https://developer.apple.com/testflight/)

## 🆘 Need Help?

- **Codemagic Support**: [codemagic.io/support](https://codemagic.io/support/)
- **Flutter iOS Docs**: [docs.flutter.dev/deployment/ios](https://docs.flutter.dev/deployment/ios)
- **Build Logs**: Check detailed logs in Codemagic dashboard

---

**Bundle ID**: `com.justingallahar.totalathlete`  
**App Name**: Total Athlete  
**Workflow**: ios-workflow  
**Current Version**: 1.0.0+1
