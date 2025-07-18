import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swipenews/providers/for_you_feed_provider.dart';
import 'package:swipenews/providers/saved_articles_provider.dart';
import 'package:swipenews/services/firestore_service.dart';
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
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProxyProvider<UserProvider, ForYouFeedProvider>(
          create: (_) => ForYouFeedProvider(),
          update: (_, userProvider, forYouProvider) =>
              forYouProvider!..updateUser(userProvider.user),
        ),
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
        home: const AppLifecycleWrapper(child: MainScreen()),
      ),
    );
  }
}

// Enhanced AppLifecycleWrapper để xử lý vấn đề Zalo
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleWrapper({super.key, required this.child});
  
  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> 
    with WidgetsBindingObserver {
  static const lifecycleChannel = MethodChannel('com.example.swipenews/lifecycle');
  bool _isResuming = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupLifecycleChannel();
  }
  
  void _setupLifecycleChannel() {
    lifecycleChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppResumed':
          _handleAppResume();
          break;
        // Removed 'recreateView' as it forces widget tree recreation
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('Flutter lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
        print('App paused - preparing for potential Surface destruction');
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.detached:
        print('App detached');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }
  
  void _handleAppResume() {
    if (_isResuming) return;
    _isResuming = true;
    
    print('Handling app resume...');
    
    // Reset _isResuming flag after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isResuming = false;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}