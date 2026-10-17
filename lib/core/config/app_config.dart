/// إعدادات تهيئة التطبيق والاتصال مع Supabase.
///
/// لتشغيل التطبيق مع الاتصال الفعلي بقاعدة بيانات Supabase، يتم تمرير
/// المتغيرات أثناء تشغيل أو بناء التطبيق باستخدام أعلام `--dart-define`:
///
/// flutter run \
///   --dart-define=SUPABASE_URL="https://your-project-id.supabase.co" \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY="your-anon-or-publishable-key"
///
/// تنبيه أمني: لا تضع أسرار الخادم أو مفتاح service_role هنا أو في أي ملف في تطبيق العميل.
class AppConfig {
  static const String appName = 'Taqat Emaar';
  static const String technicalName = 'taqat_emaar';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
