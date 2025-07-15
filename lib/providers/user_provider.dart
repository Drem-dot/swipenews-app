// lib/providers/user_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<String> _selectedInterests = [];

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool _isCheckingOnboarding = false; // Add this line
  bool get isCheckingOnboarding => _isCheckingOnboarding; // Add this line
  Map<String, dynamic>? get userProfile => _userProfile;
  List<String> get selectedInterests => _selectedInterests;

  // Available interests
// Trong user_provider.dart, thay thế availableInterests với:

// Available interests - mapped to actual categories
final List<String> availableInterests = [
  'Thời sự',
  'Kinh doanh',
  'Thể thao',
  'Giải trí',
  'Công nghệ',
  'Sức khỏe',
  'Giáo dục',
  'Du lịch',
  'Pháp luật',
  'Văn hóa',
  'Thế giới',
  'Đời sống',
  'Bất động sản',
  'Khoa học',
  'Ô tô - Xe máy'
];

// Thêm method để lấy suggested interests
Future<List<String>> getSuggestedInterests() async {
  if (_user == null || _user!.isAnonymous) return [];
  
  try {
    // Lấy liked categories từ Firestore
    final likedSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('liked_articles')
        .get();
    
    // Đếm số lần like cho mỗi category
    Map<String, int> categoryCount = {};
    
    for (var doc in likedSnapshot.docs) {
      final category = doc.data()['category'] as String?;
      if (category != null) {
        // Map category từ source sang display name
        final displayCategory = _mapCategoryToDisplay(category);
        if (displayCategory != null) {
          categoryCount[displayCategory] = (categoryCount[displayCategory] ?? 0) + 1;
        }
      }
    }
    
    // Sắp xếp theo số lượng like và lấy top 5
    var sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories
        .take(5)
        .map((e) => e.key)
        .where((cat) => !_selectedInterests.contains(cat))
        .toList();
  } catch (e) {
    debugPrint('Error getting suggested interests: $e');
    return [];
  }
}

// Helper method để map category
String? _mapCategoryToDisplay(String sourceCategory) {
  final categoryMap = {
    // VNExpress
    'thoi-su': 'Thời sự',
    'du-lich': 'Du lịch',
    'the-gioi': 'Thế giới',
    'kinh-doanh': 'Kinh doanh',
    'khoa-hoc': 'Khoa học',
    'giai-tri': 'Giải trí',
    'the-thao': 'Thể thao',
    'phap-luat': 'Pháp luật',
    'giao-duc': 'Giáo dục',
    'suc-khoe': 'Sức khỏe',
    'doi-song': 'Đời sống',
    // Dân trí
    'xa-hoi': 'Thời sự',
    'bat-dong-san': 'Bất động sản',
    'suc-manh-so': 'Công nghệ',
    'van-hoa': 'Văn hóa',
    // VietnamNet
    'oto-xe-may': 'Ô tô - Xe máy',
    'thong-tin-truyen-thong': 'Công nghệ',
  };
  
  return categoryMap[sourceCategory];
}
  UserProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    _isCheckingOnboarding = true; 
    notifyListeners();
    
    _user = _authService.getCurrentUser();
    if (_user == null) {
      _user = await _authService.signInAnonymously();
      _hasCompletedOnboarding = true;
    } else if (!_user!.isAnonymous) {
      await _loadUserProfile();
    }else {
    _hasCompletedOnboarding = true; // Anonymous users skip onboarding
  }
    
    _isLoading = false;
    _isCheckingOnboarding = false; // Add this
    notifyListeners();
  }

  bool? _hasCompletedOnboarding;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding ?? false;
  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
  if (_user == null || _user!.isAnonymous) return;
  
  try {
    final doc = await _firestore.collection('users').doc(_user!.uid).get();
    if (doc.exists) {
      _userProfile = doc.data();
      _selectedInterests = List<String>.from(_userProfile?['interests'] ?? []);
      _hasCompletedOnboarding = _userProfile?['hasCompletedOnboarding'] ?? false;
    } else {
      await _createUserProfile();
      _hasCompletedOnboarding = false; // New user needs onboarding
    }
  } catch (e) {
    debugPrint('Error loading user profile: $e');
    _hasCompletedOnboarding = true;
  }
  notifyListeners();
}

  // Create user profile in Firestore
  Future<void> _createUserProfile() async {
    if (_user == null || _user!.isAnonymous) return;
    
    final profileData = {
      'uid': _user!.uid,
      'email': _user!.email,
      'displayName': _user!.displayName ?? 'User',
      'photoURL': _user!.photoURL,
      'bio': '',
      'interests': [],
      'createdAt': FieldValue.serverTimestamp(),
      'settings': {
        'darkMode': true,
        'notifications': false,
      },
    };
    
    try {
      await _firestore.collection('users').doc(_user!.uid).set(profileData);
      _userProfile = profileData;
      _selectedInterests = [];
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  // Add method to mark onboarding complete:
Future<void> completeOnboarding() async {
  if (_user == null || _user!.isAnonymous) return;
  
  try {
    await _firestore.collection('users').doc(_user!.uid).update({
      'hasCompletedOnboarding': true,
    });
    _hasCompletedOnboarding = true;
    notifyListeners();
  } catch (e) {
    debugPrint('Error completing onboarding: $e');
  }
}

  // Toggle interest selection
  void toggleInterest(String interest) {
    if (_selectedInterests.contains(interest)) {
      _selectedInterests.remove(interest);
    } else {
      _selectedInterests.add(interest);
    }
    notifyListeners();
  }

  // Email/Password Registration
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
      _user = _auth.currentUser;
      
      // Create user profile in Firestore
      await _createUserProfile();
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'Mật khẩu quá yếu';
      } else if (e.code == 'email-already-in-use') {
        throw 'Email đã được sử dụng';
      } else {
        throw e.message ?? 'Đã có lỗi xảy ra';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email/Password Sign In
  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = _auth.currentUser;
      await _loadUserProfile();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Email không tồn tại';
      } else if (e.code == 'wrong-password') {
        throw 'Mật khẩu không đúng';
      } else {
        throw e.message ?? 'Đã có lỗi xảy ra';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google Sign In
  Future<void> handleSignInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    _user = await _authService.signInWithGoogle();
    if (_user != null && !_user!.isAnonymous) {
      await _loadUserProfile();
    }
    _isLoading = false;
    notifyListeners();
  }

  // Sign Out
  Future<void> handleSignOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _userProfile = null;
    _selectedInterests = [];
    // After sign out, return to anonymous state
    await init();
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    List<String>? interests,
  }) async {
    if (_user == null || _user!.isAnonymous) return;
    
    try {
      // Update Firebase Auth profile
      if (displayName != null && displayName != _user!.displayName) {
        await _user!.updateDisplayName(displayName);
        await _user!.reload();
        _user = _auth.currentUser;
      }
      
      // Update Firestore profile
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (interests != null) {
        updates['interests'] = interests;
        _selectedInterests = interests;
      }
      
      await _firestore.collection('users').doc(_user!.uid).update(updates);
      
      // Update local profile
      if (_userProfile != null) {
        _userProfile!.addAll(updates);
      }
      
      notifyListeners();
      return;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw 'Không thể cập nhật thông tin';
    }
  }

  // Update settings
  Future<void> updateSettings({
    bool? darkMode,
    bool? notifications,
  }) async {
    if (_user == null || _user!.isAnonymous) return;
    
    try {
      final currentSettings = Map<String, dynamic>.from(_userProfile?['settings'] ?? {});
      
      if (darkMode != null) currentSettings['darkMode'] = darkMode;
      if (notifications != null) currentSettings['notifications'] = notifications;
      
      await _firestore.collection('users').doc(_user!.uid).update({
        'settings': currentSettings,
      });
      
      if (_userProfile != null) {
        _userProfile!['settings'] = currentSettings;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
      throw 'Không thể cập nhật cài đặt';
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_user == null || _user!.isAnonymous) return;
    
    try {
      await _authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw 'Không thể đổi mật khẩu';
    }
  }

  // Get user bio
  String get userBio => _userProfile?['bio'] ?? '';

  // Get user settings
  bool get isDarkMode => _userProfile?['settings']?['darkMode'] ?? true;
  bool get notificationsEnabled => _userProfile?['settings']?['notifications'] ?? false;
}