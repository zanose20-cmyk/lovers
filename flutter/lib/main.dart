import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/account_recovery_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/room_screen.dart';
import 'screens/rooms_list_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/store_screen.dart';
import 'screens/vehicles_store_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/vip_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/agencies_screen.dart';
import 'screens/create_agency_screen.dart';
import 'screens/daily_tasks_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/jitsi_room_screen.dart';
import 'screens/create_vehicle_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/search_screen.dart';
import 'screens/voice_room_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_rooms_screen.dart';
import 'screens/admin_gifts_screen.dart';
import 'screens/badge_shop_screen.dart';
import 'screens/post_comments_screen.dart';
import 'screens/blocked_list_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'providers/api_provider.dart';
import 'providers/rooms_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/gifts_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/agencies_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/notifications_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  NotificationService.onNavigate = (route, args) {
    navigatorKey.currentState?.pushNamed(route, arguments: args);
  };
  NotificationService.onTokenUpdate = (token) async {
    try {
      final auth = navigatorKey.currentContext?.read<AuthProvider>();
      if (auth?.token != null) {
        final api = ApiService(AppConfig.serverUrl);
        api.setToken(auth!.token!);
        await api.post('/api/auth/devices/register', body: {
          'deviceId': 'android',
          'platform': 'android',
          'pushToken': token,
        });
      }
    } catch (_) {}
  };
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ApiProvider>(
          create: (_) => ApiProvider(),
          update: (_, auth, api) => api!..setToken(auth.token),
        ),
        ChangeNotifierProvider(create: (ctx) => RoomsProvider(ctx.read<ApiProvider>().api)),
        ChangeNotifierProvider(create: (ctx) => WalletProvider(ctx.read<ApiProvider>().api)),
        ChangeNotifierProvider(create: (ctx) => PostsProvider(ctx.read<ApiProvider>().api)),
        ChangeNotifierProvider(create: (ctx) => GiftsProvider(ctx.read<ApiProvider>().api)),
        ChangeNotifierProvider(create: (ctx) => MessagesProvider(ctx.read<ApiProvider>().api)),
        ChangeNotifierProvider(create: (ctx) => AgenciesProvider(ctx.read<ApiProvider>().api)),
        ChangeNotifierProvider(create: (ctx) => TasksProvider(ctx.read<ApiProvider>().api)),
        ChangeNotifierProvider(create: (ctx) => NotificationsProvider(ctx.read<ApiProvider>().api)),
      ],
      child: const LoversApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LoversApp extends StatelessWidget {
  const LoversApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Lovers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        final routes = <String, WidgetBuilder>{
          '/splash': (ctx) => const SplashScreen(),
          '/onboarding': (ctx) => const OnboardingScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/recovery': (ctx) => const AccountRecoveryScreen(),
          '/home': (ctx) => const HomeScreen(),
          '/profile': (ctx) => ProfileScreen(userId: settings.arguments as String?),
          '/edit-profile': (ctx) => const EditProfileScreen(),
          '/rooms-list': (ctx) => const RoomsListScreen(),
          '/create-room': (ctx) => const CreateRoomScreen(),
          '/room': (ctx) {
            final roomId = settings.arguments as String?;
            if (roomId == null) return const HomeScreen();
            return RoomScreen(roomId: roomId);
          },
          '/jitsi-room': (ctx) {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null) return const HomeScreen();
            return JitsiRoomScreen(
              serverUrl: args['server'] as String? ?? 'https://meet.jit.si',
              roomName: args['roomName'] as String? ?? 'غرفة',
              displayName: args['displayName'] as String? ?? 'مستخدم',
              token: args['token'] as String?,
            );
          },
          '/store': (ctx) => const StoreScreen(),
          '/vehicles-store': (ctx) => const VehiclesStoreScreen(),
          '/wallet': (ctx) => const WalletScreen(),
          '/vip': (ctx) => const VIPScreen(),
          '/messages': (ctx) => const MessagesScreen(),
          '/conversation': (ctx) {
            final userId = settings.arguments as String?;
            if (userId == null) return const HomeScreen();
            return ConversationScreen(userId: userId);
          },
          '/posts': (ctx) => const PostsScreen(),
          '/create-post': (ctx) => const CreatePostScreen(),
          '/agencies': (ctx) => const AgenciesScreen(),
          '/create-agency': (ctx) => const CreateAgencyScreen(),
          '/daily-tasks': (ctx) => const DailyTasksScreen(),
          '/notifications': (ctx) => const NotificationsScreen(),
          '/settings': (ctx) => const SettingsScreen(),
          '/create-vehicle': (ctx) => const CreateVehicleScreen(),
          '/search': (ctx) => SearchScreen(initialQuery: settings.arguments as String? ?? ''),
          '/friend-requests': (ctx) => const FriendRequestsScreen(),
          '/voice-room': (ctx) {
            final args = settings.arguments;
            if (args is Map<String, dynamic>) {
              return VoiceRoomScreen(
                server: args['server'] as String? ?? 'https://meet.jit.si',
                roomName: args['roomName'] as String,
                displayName: args['displayName'] as String? ?? 'مستخدم',
                email: args['email'] as String?,
                jwtToken: args['token'] as String?,
              );
            }
            return VoiceRoomScreen(
              server: 'https://meet.jit.si',
              roomName: args as String? ?? 'غرفة',
            );
          },
          '/admin': (ctx) => const AdminDashboardScreen(),
          '/admin-users': (ctx) => const AdminUsersScreen(),
          '/admin-rooms': (ctx) => const AdminRoomsScreen(),
          '/admin-gifts': (ctx) => const AdminGiftsScreen(),
          '/admin-vehicles': (ctx) => const VehiclesStoreScreen(),
          '/badge-shop': (ctx) => const BadgeShopScreen(),
          '/post-comments': (ctx) => PostCommentsScreen(postId: (ModalRoute.of(ctx)!.settings.arguments as Map)['postId']),
          '/blocked': (ctx) => const BlockedListScreen(),
        };

        final builder = routes[settings.name];
        if (builder != null) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
            transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
              final tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut));
              final fadeAnimation = animation.drive(tween);
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          );
        }
        return MaterialPageRoute(builder: (ctx) => const HomeScreen());
      },
    );
  }
}
