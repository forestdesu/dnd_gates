import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/loading_indicator.dart';
import 'controllers/auth.dart';
import 'controllers/lookups.dart';
import 'screens/community.dart' show CommunityScreen;
import 'screens/subscription.dart' show SubscriptionScreen;
import 'screens/profile.dart' show Item, fetchItemsPage, fetchItemsSearch, fetchLookups, ProfileTab;
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

const _kBackground = Color.fromARGB(255, 31, 31, 31);
const _kSurface = Color.fromRGBO(37, 37, 39, 1.0);
const _kAccent = Color(0xFF5B5FEF);
const _kTextSecondary = Color(0xFF8E8E93);

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
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: _kBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _kAccent,
              brightness: Brightness.dark,
              surface: _kSurface,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: _kSurface,
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            cardColor: _kSurface,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
              // Крупные суммы/цифры (было размазано по TextStyle(fontSize: 26, fontWeight: w800))
              displaySmall: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              // Заголовки секций (было TextStyle(fontSize: 16, fontWeight: w700) в десятке файлов)
              titleMedium: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              // Основной текст
              bodyMedium: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
              // Лейблы полей форм (было TextStyle(color: Colors.white70))
              labelMedium: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14),
              // Вторичный/приглушённый текст (было Colors.white54 / withValues(alpha: 0.6))
              labelSmall: GoogleFonts.inter(color: _kTextSecondary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
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
            label: 'Подписки',
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