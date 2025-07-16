# scripts/setup_firebase.sh
#!/bin/bash

# Create firebase_options.dart from environment variable
echo "Creating firebase_options.dart..."
echo "$FIREBASE_OPTIONS" | base64 --decode > lib/firebase_options.dart

# Create google-services.json for Android
echo "Creating google-services.json..."
echo "$GOOGLE_SERVICES_JSON" | base64 --decode > android/app/google-services.json

# Create GoogleService-Info.plist for iOS (if needed)
if [ ! -z "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "Creating GoogleService-Info.plist..."
    echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > ios/Runner/GoogleService-Info.plist
fi

echo "Firebase setup completed!"