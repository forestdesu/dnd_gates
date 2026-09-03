import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';
import 'screens/community_screen.dart' show CommunityScreen;
import 'screens/profile_screen.dart' show Item, fetchItemsPage, fetchItemsSearch, fetchLookups, ProfileTab;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => AuthController(),
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
          home: const MyHomePage(),
        )
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int _selectedIndex = 2;
  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Выбираем AppBar в зависимости от текущей вкладки
    AppBar? currentAppBar;
    if (_selectedIndex == 0) {
      // Магазин - простой navbar без поиска
      currentAppBar = AppBar(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        title: const Text('Магазин', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        elevation: 0,
      );
    } else if (_selectedIndex == 1) {
      // База знаний - персональный navbar
      currentAppBar = AppBar(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        title: const Text('База знаний', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        elevation: 0,
      );
    } else if (_selectedIndex == 2) {
      // Сообщество - с поиском и фильтрами
      currentAppBar = AppBar(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        title: const Text('Сообщество', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        elevation: 0,
      );
    } else if (_selectedIndex == 3) {
      // Профиль - без иконок в navbar
      currentAppBar = AppBar(
        backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
        title: const Text('Профиль', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      );
    }

    return Scaffold(
      appBar: currentAppBar,
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
            label: 'База знаний',
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Center(child: Text('Магазин', style: const TextStyle(color: Colors.white))),
          Center(child: Text('База знаний', style: const TextStyle(color: Colors.white))),
          const CommunityScreen(),
          const ProfileTab(),
        ],
      ),
    );
  }
}