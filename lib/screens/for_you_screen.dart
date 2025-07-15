// lib/screens/for_you_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/for_you_feed_provider.dart';
import '../widgets/article_card.dart';
import '../providers/feed_provider.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> with AutomaticKeepAliveClientMixin<ForYouScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ForYouFeedProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (provider.articles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Hãy "thích" một vài bài báo để chúng tôi biết sở thích của bạn và đề xuất nội dung phù hợp!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: provider.articles.length,
          onPageChanged: (int page) {
            context.read<FeedProvider>().onPageChanged(page);
            final provider = context.read<ForYouFeedProvider>();
            if (page >= provider.articles.length - 3 && provider.hasMore) {
              provider.fetchMoreForYouFeed();
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