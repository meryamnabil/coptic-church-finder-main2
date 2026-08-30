import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/church_provider.dart';
import 'providers/location_provider.dart';
import 'screens/splash_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';


const Color primaryGold = Color(0xFFB8965E);
const Color backgroundBeige = Color(0xFFF5EFE6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Parse().initialize(
    '7BM3voBPPv83gq086cx2zJAOLiMqrPdd8V56Igf3',
    'https://parseapi.back4app.com/',
    clientKey: 'qlVbw3IUaIPZhSk9DpUKLfuJJDhpkWwMIk7wPkXr',
    autoSendSessionId: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = ChurchProvider();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.loadChurches();
            });
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'دليل الكنائس القبطية',
        
        // تفعيل اللغة العربية والاتجاه من اليمين إلى اليسار (RTL)
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [
          Locale('ar', 'EG'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: backgroundBeige,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGold,
            primary: primaryGold,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}