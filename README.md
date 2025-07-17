# SwipeNews 📰

SwipeNews là ứng dụng đọc tin tức thông minh với giao diện swipe hiện đại, được xây dựng bằng Flutter và Firebase. Ứng dụng tự động thu thập tin tức từ các trang báo lớn của Việt Nam và cá nhân hóa nội dung dựa trên sở thích người dùng.

## 📱 Tính năng chính

### 🎯 Trải nghiệm đọc tin

- **Swipe Navigation**: Vuốt trái/phải để chuyển bài viết như TikTok
- **Smart Feed**: Đề xuất tin tức dựa trên sở thích và lịch sử đọc
- **Multi-source**: Tổng hợp tin từ VNExpress, Dân Trí, VietnamNet
- **Categories**: 15+ danh mục từ Thời sự, Công nghệ đến Giải trí

### 👤 Cá nhân hóa

- **User Profiles**: Đăng nhập với Email/Google
- **Interest Selection**: Chọn chủ đề yêu thích khi onboarding
- **Save Articles**: Lưu bài viết để đọc sau
- **Like System**: Hệ thống like để cải thiện đề xuất

### 💬 Tương tác xã hội

- **Comments**: Bình luận và thảo luận về bài viết
- **Nested Replies**: Trả lời bình luận với thread
- **Real-time Updates**: Cập nhật bình luận real-time với Firestore

### 🎨 Giao diện

- **Dark Mode**: Giao diện tối mặc định
- **Smooth Animations**: Animation mượt mà cho mọi tương tác
- **Responsive Design**: Tối ưu cho mọi kích thước màn hình

## 🚀 Cài đặt và Chạy

### Yêu cầu

- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- Android Studio / VS Code
- Firebase account

### 1. Clone repository

```bash
git clone https://github.com/yourusername/swipenews.git
cd swipenews
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase

a. Tạo Firebase project

Truy cập Firebase Console
Tạo project mới hoặc sử dụng project có sẵn
Enable Authentication (Email/Password & Google Sign-In)
Tạo Firestore Database
Enable Storage (optional - cho avatar upload)

b. Thêm Firebase vào app

```bash
# Cài đặt FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

c. Download config files

- Android: Tải google-services.json → đặt vào android/app/
- iOS: Tải GoogleService-Info.plist → đặt vào ios/Runner/

### 4. Cấu hình Google Sign-In

**Android**:

1. Lấy SHA-1 fingerprint:

```bash
cd android
./gradlew signingReport
```

2. Thêm SHA-1 vào Firebase Console → Project Settings → Android app.

**Web Client ID**:

1. Copy Web Client ID từ Firebase Console → Authentication → Sign-in method → Google
2. Update trong lib/services/auth_service.dart:

```dart
const String webClientId = 'YOUR_WEB_CLIENT_ID_HERE';
```

### 5. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Articles - read only
    match /articles/{article} {
      allow read: if true;
      allow write: if false;
    }
    
    // Users - read/write own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      
      match /{subcollection}/{document} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Comments
    match /articles/{articleId}/comments/{commentId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likeCount', 'replyCount']));
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
      
      // Nested collections
      match /{subcollection}/{document} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow delete: if request.auth != null;
      }
    }
  }
}
```

### 6. Chạy ứng dụng

```bash
# Development
flutter run

# Production build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### 📁 Cấu trúc Project

```bash
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── article.dart         # Article model
│   └── comment.dart         # Comment model
├── providers/               # State management
│   ├── user_provider.dart   # User authentication state
│   ├── feed_provider.dart   # News feed state
│   └── comment_provider.dart # Comments state
├── screens/                 # UI screens
│   ├── main_screen.dart     # Main navigation
│   ├── feed_screen.dart     # News feed
│   ├── article_detail_screen.dart # Article reader
│   ├── enhanced_profile_screen.dart # User profile
│   ├── auth_screen.dart     # Login/Register
│   └── onboarding_screen.dart # First-time setup
├── services/                # Business logic
│   ├── auth_service.dart    # Authentication
│   ├── firestore_service.dart # Database operations
│   └── comment_service.dart # Comment operations
└── widgets/                 # Reusable components
    ├── article_card.dart    # Swipeable article card
    ├── comment_list_item.dart # Comment widget
    └── top_navigation_bar.dart # Custom nav bar

```

### 🔧 Configuration

**Environment Variables (Optional)**

Tạo file .env cho development:

```bash
WEB_CLIENT_ID=128128649313-8uurnl9tq7kkr11ek9j76t70fr0n8p43.apps.googleusercontent.com
```

**Build Configuration**

```bash
# Run with environment variables
flutter run --dart-define=WEB_CLIENT_ID=$WEB_CLIENT_ID
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (git checkout -b feature/AmazingFeature)
3. Commit your changes (git commit -m 'Add some AmazingFeature')
4. Push to the branch (git push origin feature/AmazingFeature)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- News sources: VNExpress, Dân Trí, VietnamNet
- UI inspiration: TikTok, Google News
- Built with Flutter & Firebase

## 📞 Contact

- Project Link: https://github.com/Drem-dot/swipenews-app

<p align="center">Made with ❤️ in Vietnam</p>

