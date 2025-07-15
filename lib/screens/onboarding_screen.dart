// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selectedInterests = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text(
                  'Bỏ qua',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
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
                  const Text(
                    'Chào mừng đến với SwipeNews',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn ít nhất 3 chủ đề bạn quan tâm',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _selectedInterests.length / 3,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _selectedInterests.length >= 3
                            ? Colors.green
                            : Colors.purple[400]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedInterests.length}/3',
                    style: TextStyle(
                      color: _selectedInterests.length >= 3
                          ? Colors.green
                          : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Interest grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: userProvider.availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return _buildInterestCard(interest, isSelected);
                  }).toList(),
                ),
              ),
            ),
            
            // Continue button
            Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedOpacity(
                opacity: _selectedInterests.length >= 3 ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[400]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedInterests.length >= 3 && !_isLoading
                        ? _handleContinue
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Tiếp tục',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestCard(String interest, bool isSelected) {
    // Icon map cho các categories
    final iconMap = {
      'Thời sự': Icons.public,
      'Kinh doanh': Icons.business,
      'Thể thao': Icons.sports_soccer,
      'Giải trí': Icons.movie,
      'Công nghệ': Icons.computer,
      'Sức khỏe': Icons.favorite,
      'Giáo dục': Icons.school,
      'Du lịch': Icons.flight,
      'Pháp luật': Icons.gavel,
      'Văn hóa': Icons.palette,
      'Thế giới': Icons.language,
      'Đời sống': Icons.emoji_people,
      'Bất động sản': Icons.home,
      'Khoa học': Icons.science,
      'Ô tô - Xe máy': Icons.directions_car,
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedInterests.remove(interest);
          } else {
            _selectedInterests.add(interest);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.purple[400]!, Colors.blue[600]!],
                )
              : null,
          color: isSelected ? null : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              iconMap[interest] ?? Icons.category,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              interest,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Update interests
      await userProvider.updateProfile(
        interests: _selectedInterests.toList(),
      );
      
      // Mark onboarding as complete
      await userProvider.completeOnboarding();
      
      widget.onComplete();
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
          _isLoading = false;
        });
      }
    }
  }
}