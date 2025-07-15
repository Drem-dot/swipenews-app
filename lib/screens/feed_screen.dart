// lib/screens/feed_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/article_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin<FeedScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.articles.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!provider.isLoading && provider.articles.isEmpty) {
          return const Center(child: Text('Không tìm thấy bài báo nào.'));
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: provider.articles.length,
          onPageChanged: (int page) {
            context.read<FeedProvider>().onPageChanged(page);
            final provider = context.read<FeedProvider>();
            if (page >= provider.articles.length - 3 && provider.hasMore) {
              provider.fetchMoreArticles();
            }
          },
          itemBuilder: (context, index) {
            final article = provider.articles[index];
            return ArticleCard(article: article);
          },
        );
      },
    );
  }
}