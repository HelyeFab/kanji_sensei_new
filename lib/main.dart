import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:kanji_sensei/presentation/theme/app_colors.dart';
import 'core/di/injection.dart';
import 'core/constants/app_config.dart';
import 'data/repositories/saved_words_repository.dart';
import 'data/repositories/user_stats_repository.dart';
import 'presentation/blocs/kanji/kanji_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/screens/kanji_search_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/theme/app_theme.dart';

import 'package:kanji_sensei/presentation/screens/dictionary_screen.dart';
import 'presentation/screens/word_collection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Open Hive boxes for caching
  await Hive.openBox<Map>('kanji_box');
  await Hive.openBox<List>('jlpt_level_box');
  await Hive.openBox<bool>('jlpt_flags_box');

  // Configure dependencies
  configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(const StartAuthListening()),
        ),
        BlocProvider<KanjiBloc>(
          create: (context) => getIt<KanjiBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return const MainApp();
            } else if (state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              return const AuthScreen();
            }
          },
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  
  static final List<Widget> _screens = [
    const DictionaryScreen(),
    const WordCollectionScreen(),
    const KanjiSearchScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SavedWordsRepository>(
          create: (_) => getIt<SavedWordsRepository>(),
        ),
        Provider<UserStatsRepository>(
          create: (_) => getIt<UserStatsRepository>(),
        ),
      ],
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_4x4),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description_outlined),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: '',
                ),
              ],
              currentIndex: _selectedIndex,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.secondary,
              unselectedItemColor: AppColors.textOnPrimary.withOpacity(0.7),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
