import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'data/providers/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';

const _navy = Color(0xFF18334F);
const _gold = Color(0xFFF0AD35);
const _pageBackground = Color(0xFFF6F8FB);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  runApp(
    ProviderScope(
      child: TaqatEmaarApp(
        isConfigured: AppConfig.isConfigured,
      ),
    ),
  );
}

class TaqatEmaarApp extends StatelessWidget {
  const TaqatEmaarApp({
    super.key,
    this.isConfigured = false,
  });

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _navy,
          primary: _navy,
          secondary: _gold,
        ),
        scaffoldBackgroundColor: _pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _pageBackground,
          foregroundColor: _navy,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(
              color: Color(0xFFE9EDF3),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: isConfigured
          ? const AppAuthGate()
          : const MissingConfigScreen(),
    );
  }
}

class AppAuthGate extends ConsumerWidget {
  const AppAuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (state) {
        if (state.session != null) {
          return const StoreHomeScreen();
        }
        return const WelcomeScreen();
      },
      loading: () {
        if (Supabase.instance.client.auth.currentSession != null) {
          return const StoreHomeScreen();
        }
        return const WelcomeScreen();
      },
      error: (e, stack) {
        if (Supabase.instance.client.auth.currentSession != null) {
          return const StoreHomeScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text(
          'طاقة إعمار — إعداد الاتصال',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE5EAF0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      size: 48,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Taqat Emaar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'مطلوب ضبط مفاتيح Supabase',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'لتشغيل التطبيق والاتصال بقاعدة البيانات الحقيقية، '
                    'يرجى تمرير المتغيرين البيئيين عند التشغيل:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'flutter run \\\n'
                      '  --dart-define=SUPABASE_URL="..." \\\n'
                      '  --dart-define=SUPABASE_PUBLISHABLE_KEY="..."',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تنبيه أمني: لا تضع مفاتيح service_role السرية داخل التطبيق.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}