// lib/widgets/top_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';

class TopNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabPressed;
  final VoidCallback? onAvatarPressed; // Add callback for avatar tap

  const TopNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTabPressed,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabs(),
            _buildAvatar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabItem('Đề xuất', 0),
        const SizedBox(width: 20),
        _buildTabItem('Khám phá', 1),
        const SizedBox(width: 20),
        _buildTabItem('Đã lưu', 2),
      ],
    );
  }

  Widget _buildTabItem(String text, int index) {
    final bool isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabPressed(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.white : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : Colors.white.withAlpha(180),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        
        return GestureDetector(
          onTap: onAvatarPressed,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha((255 * 0.3).round()),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: user != null && user.photoURL != null && !user.isAnonymous
                  ? CachedNetworkImage(
                      imageUrl: user.photoURL!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white54,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple[400]!, Colors.blue[600]!],
                        ),
                      ),
                      child: Icon(
                        user != null && !user.isAnonymous 
                            ? Icons.person 
                            : Icons.person_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}