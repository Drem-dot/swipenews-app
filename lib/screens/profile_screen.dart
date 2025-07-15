// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer để lắng nghe UserProvider
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Hiển thị vòng xoay nếu đang tải
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userProvider.user;

          // Nếu chưa có user (trường hợp hiếm), hiển thị lỗi
          if (user == null) {
            return const Center(child: Text("Không thể tải thông tin người dùng."));
          }

          // YÊU CẦU 4.1: Nếu là người dùng ẩn danh
          if (user.isAnonymous) {
            return _buildAnonymousView(context, userProvider);
          } else {
            // Nếu là người dùng đã đăng nhập Google
            return _buildLoggedInView(context, userProvider);
          }
        },
      ),
    );
  }

  // Giao diện cho người dùng chưa đăng nhập
  Widget _buildAnonymousView(BuildContext context, UserProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Đăng nhập để lưu và cá nhân hóa tin tức!"),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text("Đăng nhập với Google"),
            onPressed: () {
              provider.handleSignInWithGoogle();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Giao diện cho người dùng đã đăng nhập
  Widget _buildLoggedInView(BuildContext context, UserProvider provider) {
    final user = provider.user!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ảnh đại diện
          if (user.photoURL != null)
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL!),
              radius: 50,
            ),
          const SizedBox(height: 20),
          // Tên hiển thị
          if (user.displayName != null)
            Text(
              user.displayName!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          // Email
          if (user.email != null)
            Text(
              user.email!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          const SizedBox(height: 40),
          // Nút đăng xuất
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Đăng xuất"),
            onPressed: () {
              provider.handleSignOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}