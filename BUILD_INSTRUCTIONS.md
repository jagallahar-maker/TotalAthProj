# Total Athlete - iOS Build Instructions for Codemagic

## Project Configuration

**Bundle Identifier:** `com.justingallahar.totalathlete`  
**App Display Name:** Total Athlete  
**Version:** 1.0.0+1

## Prerequisites

Before building with Codemagic, ensure you have:

1. **Apple Developer Account** with access to App Store Connect
2. **App Store Connect API Key** for Codemagic integration
3. **Provisioning Profiles and Certificates** set up in Codemagic

## Codemagic Setup

### 1. Connect Your Repository

1. Log in to [Codemagic](https://codemagic.io/)
2. Click "Add application"
3. Connect your Git repository (GitHub, GitLab, or Bitbucket)
4. Select the repository containing this Flutter project

### 2. Configure App Store Connect Integration

1. In Codemagic, go to **Teams** > **Integrations** > **App Store Connect**
2. Click **Add key**
3. Enter your App Store Connect API credentials:
   - Issuer ID
   - Key ID
   - API Key (.p8 file)
4. Save the integration

### 3. Configure iOS Code Signing

#### Option A: Automatic Code Signing (Recommended)

1. In your app settings, go to **Code signing identities**
2. Click **iOS code signing**
3. Select **Automatic code signing**
4. Choose your Apple Developer Portal integration
5. Select the provisioning profile for `com.justingallahar.totalathlete`

#### Option B: Manual Code Signing

1. Upload your **Distribution Certificate** (.p12 file)
2. Upload your **Provisioning Profile** (App Store distribution profile)
3. Set the certificate password

### 4. Environment Variables

In Codemagic app settings, add these environment variables:

- `BUNDLE_ID`: `com.justingallahar.totalathlete`
- `APP_STORE_ID`: Your App Store Connect app ID (from App Store Connect)

### 5. Configure the Workflow

The `codemagic.yaml` file in the project root defines the build workflow:

- **Build configuration**: Release
- **Flutter version**: Stable channel
- **Xcode**: Latest version
- **Instance type**: Mac mini M1 (faster builds)

Key build steps:
1. Set up code signing
2. Install Flutter dependencies
3. Install CocoaPods dependencies
4. Run Flutter analyze
5. Build iOS IPA
6. Upload to TestFlight

## Building the App

### Trigger a Build

Builds are triggered automatically when you:
- Push to the main/master branch
- Create a pull request
- Manually trigger from Codemagic dashboard

### Manual Build Trigger

1. Go to your app in Codemagic
2. Click **Start new build**
3. Select the branch (e.g., `main`)
4. Select the workflow: `ios-workflow`
5. Click **Start new build**

## Build Artifacts

After a successful build, you'll receive:

1. **IPA file** - The signed iOS application package
2. **Build logs** - Complete build output for debugging
3. **TestFlight submission** - Automatic upload to TestFlight (if enabled)

## TestFlight Distribution

The workflow is configured to automatically:
1. Build the IPA
2. Upload to TestFlight
3. Submit to "Internal Testers" beta group

### Manual TestFlight Upload

If automatic upload fails, you can manually upload:

1. Download the IPA from Codemagic artifacts
2. Open **Xcode** > **Window** > **Organizer**
3. Drag the IPA into the Archives section
4. Click **Distribute App** > **App Store Connect**
5. Follow the upload wizard

## Troubleshooting

### Common Issues

#### Build Fails with Code Signing Error

**Solution**: Verify your provisioning profile matches the bundle ID:
- Bundle ID: `com.justingallahar.totalathlete`
- Profile type: App Store Distribution
- Check profile hasn't expired

#### Pod Install Fails

**Solution**: The workflow includes automatic pod installation. If it fails:
- Check `ios/Podfile.lock` is committed to Git
- Verify minimum iOS deployment target (iOS 12.0)

#### Flutter Analyze Errors

**Solution**: Run locally before pushing:
```bash
flutter analyze
```

Fix any errors reported before triggering a CI build.

#### Version Number Conflicts

**Solution**: The workflow auto-increments build numbers based on TestFlight. Ensure:
- `APP_STORE_ID` environment variable is set correctly
- Your app exists in App Store Connect

### Local Testing

Before pushing to Codemagic, test the build locally:

```bash
# Install dependencies
flutter pub get
cd ios && pod install && cd ..

# Analyze code
flutter analyze

# Build iOS (requires macOS and Xcode)
flutter build ios --release
```

## App Store Connect Configuration

### Create the App

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Go to **My Apps** > **+** icon
3. Create new app:
   - **Platform**: iOS
   - **Name**: Total Athlete
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.justingallahar.totalathlete`
   - **SKU**: `total-athlete-001` (or your preference)

### Configure TestFlight

1. In App Store Connect, go to your app
2. Click **TestFlight** tab
3. Create a new **Internal Testing** group:
   - Name: "Internal Testers"
   - Add testers (email addresses)

## Post-Build Steps

After successful build:

1. **Check TestFlight**: Verify the build appears in App Store Connect > TestFlight
2. **Test the app**: Download from TestFlight and test core workflows
3. **Submit for review**: When ready, submit to App Store for review

## Core Workflows to Test

Before submitting to App Store, verify these flows work:

1. ✅ Start workout
2. ✅ Select routine
3. ✅ Exercises auto-load
4. ✅ Log sets with progression suggestions
5. ✅ Navigate between exercises in session
6. ✅ Finish workout
7. ✅ Workout saved in history
8. ✅ Weight tracking (displays pounds correctly)
9. ✅ View analytics and progress charts

## Key Features Verified for Production

- ✅ iOS bundle identifier: `com.justingallahar.totalathlete`
- ✅ App display name: "Total Athlete"
- ✅ No preview-only dependencies
- ✅ GoRouter navigation routes valid
- ✅ Weight tracking uses kg internally, displays lb
- ✅ Automatic goal weight migration
- ✅ Workout session overview with progress tracking
- ✅ Auto-progression suggestions
- ✅ Auto-navigation to next exercise

## Support

For Codemagic-specific issues:
- [Codemagic Documentation](https://docs.codemagic.io/)
- [Codemagic Support](https://codemagic.io/support/)

For Flutter build issues:
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- Run `flutter doctor -v` to check your setup
