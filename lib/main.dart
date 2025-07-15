
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:swipenews/providers/for_you_feed_provider.dart';
import 'package:swipenews/providers/saved_articles_provider.dart';
import 'package:swipenews/services/firestore_service.dart'; // Import FirestoreService
import 'package:timeago/timeago.dart' as timeago;
import 'providers/feed_provider.dart';
import 'providers/user_provider.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'providers/comment_provider.dart';
void main() async {
  timeago.setLocaleMessages('vi', timeago.ViMessages());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Cung cấp FirestoreService ở cấp cao nhất
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        // YÊU CẦU 3.2: Cấu trúc Provider đúng
        // ForYouFeedProvider cũng cần thông tin user
        ChangeNotifierProxyProvider<UserProvider, ForYouFeedProvider>(
          create: (_) => ForYouFeedProvider(),
          update: (_, userProvider, forYouProvider) =>
              forYouProvider!..updateUser(userProvider.user),
        ),
        
        // FeedProvider có thể được đặt sau vì nó sẽ gọi đến ForYouFeedProvider
        ChangeNotifierProxyProvider<UserProvider, FeedProvider>(
          create: (_) => FeedProvider(),
          update: (_, userProvider, feedProvider) =>
              feedProvider!..updateUser(userProvider.user),
        ),

        ChangeNotifierProxyProvider<UserProvider, SavedArticlesProvider>(
          create: (_) => SavedArticlesProvider(),
          update: (_, userProvider, savedProvider) =>
              savedProvider!..updateUser(userProvider.user),
        ),
      ],
      child: MaterialApp(
        title: 'SwipeNews',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueAccent,
          scaffoldBackgroundColor: Colors.black,
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}