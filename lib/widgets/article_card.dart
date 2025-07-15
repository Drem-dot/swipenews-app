import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swipenews/widgets/comment_sheet.dart';
import '../providers/comment_provider.dart';
import '../models/article.dart';
import '../providers/feed_provider.dart';
import '../screens/article_detail_screen.dart';
import 'action_toolbar.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  const ArticleCard({super.key, required this.article});

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundImage(),
          _buildClearImageSection(context),
          _buildContentPanel(context),
          _buildFixedActionToolbar(context),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return CachedNetworkImage(
      imageUrl: widget.article.imageUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade700,
        child: Container(color: Colors.black),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade900,
        child: const Center(child: Icon(Icons.image_not_supported)),
      ),
    );
  }

  Widget _buildClearImageSection(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: screenSize.height * 0.4,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(widget.article.imageUrl ?? ''),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildContentPanel(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            color: const Color.fromRGBO(0, 0, 0, 0.35),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height * 0.6,
                maxHeight: screenSize.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.article.summary,
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedActionToolbar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.7)],
          ),
        ),
        child: Consumer<FeedProvider>(
          builder: (context, provider, child) {
            final isLiked = provider.likedArticleIds.contains(
              widget.article.id,
            );
            final isSaved = provider.savedArticleIds.contains(
              widget.article.id,
            );

            return ActionToolbar(
              isLiked: isLiked,
              isSaved: isSaved,
              onLikePressed: () {
                context.read<FeedProvider>().toggleLike(
                  context,
                  widget.article,
                );
              },
              onSavePressed: () {
                context.read<FeedProvider>().toggleSave(widget.article);
              },
              onSharePressed: () {
                final textToShare =
                    '${widget.article.title}\n\nĐọc thêm tại SwipeNews:\n${widget.article.sourceUrl}';
                SharePlus.instance.share(
                  ShareParams(text: textToShare, subject: widget.article.title),
                );
              },
              onDetailPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ArticleDetailScreen(article: widget.article),
                  ),
                );
              },
              onCommentPressed: () {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return ChangeNotifierProvider(
                      create: (context) => CommentProvider(),
                      child: CommentSheet(
                        articleId: widget.article.id,
                        currentUser: currentUser,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
