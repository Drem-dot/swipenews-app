// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import '../providers/user_provider.dart'; // Add this import
import '../widgets/top_navigation_bar.dart';
import 'for_you_screen.dart';
import 'feed_screen.dart';
import 'saved_screen.dart';
import 'enhanced_profile_screen.dart'; // New profile screen
import '../screens/onboarding_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showProfile = false; // Track if profile is shown

  static const List<Widget> _screens = <Widget>[
    ForYouScreen(), // Tab 0 - Đề xuất
    FeedScreen(), // Tab 1 - Khám phá
    SavedScreen(), // Tab 2 - Đã lưu
  ];

  void _handleAvatarPressed() {
    setState(() {
      _showProfile = true;
    });
  }

  void _closeProfile() {
    setState(() {
      _showProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Show loading while checking onboarding status
        if (userProvider.isCheckingOnboarding) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.newspaper,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Check if user needs onboarding
        if (userProvider.user != null &&
            !userProvider.user!.isAnonymous &&
            !userProvider.hasCompletedOnboarding) {
          return OnboardingScreen(
            onComplete: () {
              setState(() {}); // Trigger rebuild to show main screen
            },
          );
        }
        
        // Original main screen content
        return Scaffold(
          body: Stack(
            children: [
              // ... rest of your main screen code
              IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  child: TopNavigationBar(
                    selectedIndex: _selectedIndex,
                    onTabPressed: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _showProfile = false;
                      });
                    },
                    onAvatarPressed: _handleAvatarPressed,
                  ),
                ),
              ),
              if (_showProfile)
                AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _showProfile ? Offset.zero : const Offset(1, 0),
                  child: EnhancedProfileScreen(
                    onClose: _closeProfile,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}