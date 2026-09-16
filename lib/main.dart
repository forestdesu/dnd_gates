import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/loading_indicator.dart';
import 'auth_controller.dart';
import 'controllers/lookups_controller.dart';
import 'screens/community_screen.dart' show CommunityScreen;
import 'screens/subscription_screen.dart' show SubscriptionScreen;
import 'screens/profile_screen.dart' show Item, fetchItemsPage, fetchItemsSearch, fetchLookups, ProfileTab;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthController()),
          ChangeNotifierProvider(create: (_) => LookupsController()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(scaffoldBackgroundColor: const Color.fromARGB(255, 31, 31, 31),
              primarySwatch: Colors.red,
              textTheme: TextTheme(
                  bodyMedium: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 22
                  ),
                  labelSmall: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 18
                  )
              )
          ),
          home: const AppStartupGate(),
          builder: (context, child) {
            return SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: child!,
            );
          },
        )
    );
  }
}

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final lookups = context.read<LookupsController>();
    final auth = context.read<AuthController>();
    await Future.wait([
      lookups.load(),
      auth.tryRestoreSession(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupsController>();
    final auth = context.watch<AuthController>();

    if (lookups.isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    if (lookups.error != null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Сервер временно не работает',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return MyHomePage(initialIndex: auth.isAuthenticated ? 2 : 3);
  }
}

class MyHomePage extends StatefulWidget {
  final int initialIndex;

  const MyHomePage({super.key, this.initialIndex = 2});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex = widget.initialIndex;
  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Магазин',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Мои подписки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub),
            label: 'Сообщество',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            Center(child: Text('Магазин', style: const TextStyle(color: Colors.white))),
            const SubscriptionScreen(),
            const CommunityScreen(),
            const ProfileTab(),
          ],
        ),
      ),
    );
  }
}