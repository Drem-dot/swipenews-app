// lib/screens/enhanced_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/saved_articles_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/article_detail_screen.dart';
import '../screens/change_password_screen.dart';

class EnhancedProfileScreen extends StatefulWidget {
  final VoidCallback? onClose;

  const EnhancedProfileScreen({super.key, this.onClose});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isProfileLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null && !user.isAnonymous) {
      _nameController.text = user.displayName ?? '';
      _bioController.text = userProvider.userBio;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = userProvider.user;
            if (user == null || user.isAnonymous) {
              return _buildAnonymousView(context);
            }

            return _buildLoggedInView(context, userProvider);
          },
        ),
      ),
    );
  }

  Widget _buildAnonymousView(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Đăng nhập để cá nhân hóa\ntrải nghiệm của bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lưu bài viết yêu thích, nhận đề xuất phù hợp',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 32),
                  _buildGradientButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    child: const Text('Đăng nhập / Đăng ký'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInView(BuildContext context, UserProvider userProvider) {
    final user = userProvider.user!;

    return Column(
      children: [
        _buildHeader(),
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.photoURL != null
                    ? CachedNetworkImageProvider(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? 'Người dùng',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.purple[400]!, Colors.blue[600]!],
              ),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Thông tin'),
              Tab(text: 'Đã lưu'),
              Tab(text: 'Cài đặt'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(userProvider),
              _buildSavedArticlesTab(),
              _buildSettingsTab(userProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Trang cá nhân',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(UserProvider userProvider) {
    final user = userProvider.user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tên hiển thị',
              labelStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple[400]!, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            enabled: false,
            style: TextStyle(color: Colors.grey[600]),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[900]?.withAlpha(128),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            controller: TextEditingController(text: user.email),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _bioController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Giới thiệu',
              labelStyle: TextStyle(color: Colors.grey[400]),
              hintText: 'Viết vài dòng về bạn...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple[400]!, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sở thích đọc báo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  // Nút refresh để lấy đề xuất mới
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.purple[400],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {}); // Trigger rebuild để load suggestions
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selected interests
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: userProvider.availableInterests.map((interest) {
                  final isSelected = userProvider.selectedInterests.contains(
                    interest,
                  );
                  if (!isSelected) return const SizedBox.shrink();

                  return _buildInterestChip(
                    interest,
                    true,
                    () => userProvider.toggleInterest(interest),
                  );
                }).toList(),
              ),

              // Suggested interests
              FutureBuilder<List<String>>(
                future: userProvider.getSuggestedInterests(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Đề xuất dựa trên bài viết bạn thích',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: snapshot.data!.map((interest) {
                          return _buildInterestChip(
                            interest,
                            false,
                            () => userProvider.toggleInterest(interest),
                            suggested: true,
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),

              // All interests
              const SizedBox(height: 16),
              Text(
                'Tất cả danh mục',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: userProvider.availableInterests.map((interest) {
                  final isSelected = userProvider.selectedInterests.contains(
                    interest,
                  );
                  return _buildInterestChip(
                    interest,
                    isSelected,
                    () => userProvider.toggleInterest(interest),
                  );
                }).toList(),
              ),
            ],
          ),

          _buildGradientButton(
            onPressed: _isProfileLoading
                ? null
                : () => _saveProfile(userProvider),
            child: _isProfileLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedArticlesTab() {
    return Consumer<SavedArticlesProvider>(
      builder: (context, provider, child) {
        if (provider.savedArticles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bài viết nào được lưu',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.savedArticles.length,
          itemBuilder: (context, index) {
            final article = provider.savedArticles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArticleDetailScreen(article: article),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: article.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: article.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[800]),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white24,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white24,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab(UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CÀI ĐẶT ỨNG DỤNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingItem(
            icon: Icons.dark_mode,
            title: 'Chế độ tối',
            subtitle: 'Đang phát triển',
            trailing: Switch(
              value: false,
              onChanged: null, // Disable
              activeColor: Colors.grey,
            ),
          ),

          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            subtitle: 'Đang phát triển',
            trailing: Switch(
              value: false,
              onChanged: null, // Disable
              activeColor: Colors.grey,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'TÀI KHOẢN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          if (userProvider.user?.providerData.any(
                (info) => info.providerId == 'password',
              ) ??
              false)
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Đổi mật khẩu',
              subtitle: 'Cập nhật mật khẩu tài khoản',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),

          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Quyền riêng tư',
            subtitle: 'Quản lý dữ liệu cá nhân',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(userProvider);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    bool suggested = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Colors.purple[400]!, Colors.blue[600]!])
              : null,
          color: isSelected ? null : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: suggested && !isSelected
              ? Border.all(color: Colors.purple[400]!, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suggested && !isSelected)
              Icon(Icons.add, size: 16, color: Colors.purple[400]),
            if (suggested && !isSelected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : suggested
                    ? Colors.purple[400]
                    : Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }

  Future<void> _saveProfile(UserProvider userProvider) async {
    setState(() {
      _isProfileLoading = true;
    });

    try {
      await userProvider.updateProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        interests: userProvider.selectedInterests,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thay đổi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }


  void _showLogoutDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              userProvider.handleSignOut();
              widget.onClose?.call();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
