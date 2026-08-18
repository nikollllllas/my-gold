import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers.dart';
import 'screens/account.dart';
import 'screens/calculator.dart';
import 'screens/home.dart';
import 'screens/market.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  try {
    // Exige google-services.json / GoogleService-Info.plist (flutterfire configure);
    // sem eles o init falha e o app segue sem push.
    await Firebase.initializeApp();
  } catch (_) {}
  runApp(const ProviderScope(child: MyGoldApp()));
}

class MyGoldApp extends StatelessWidget {
  const MyGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Gold',
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const _Shell(),
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();
  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> with WidgetsBindingObserver {
  int _index = 0;
  static const _screens = [HomeScreen(), MarketScreen(), CalculatorScreen(), AccountScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Usuário volta do checkout no navegador → recarrega status premium.
    // (Deep link mygold:// fica para quando android/ e ios/ forem gerados.)
    if (state == AppLifecycleState.resumed) ref.invalidate(userProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Mercado'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: 'Calculadora'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Conta'),
        ],
      ),
    );
  }
}
