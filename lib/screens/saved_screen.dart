// lib/screens/saved_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipenews/providers/saved_articles_provider.dart';
import 'package:swipenews/screens/article_detail_screen.dart';

// YÊU CẦU 3: Chuyển thành StatefulWidget
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

// YÊU CẦU 3: Thêm Mixin
class _SavedScreenState extends State<SavedScreen> with AutomaticKeepAliveClientMixin<SavedScreen> {
  
  @override
  bool get wantKeepAlive => true; // Giữ lại trạng thái
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc gọi

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<SavedArticlesProvider>(
        builder: (context, provider, child) {
          if (provider.savedArticles.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có bài báo nào được lưu.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: provider.savedArticles.length,
            itemBuilder: (context, index) {
              final article = provider.savedArticles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Card(
                  color: Colors.grey.shade900,
                  child: ListTile(
                    leading: SizedBox(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: article.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey.shade800),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.image_not_supported, color: Colors.white24),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.image_not_supported, color: Colors.white24),
                            ),
                      ),
                    ),
                    title: Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      article.category.toUpperCase(),
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(article: article),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}