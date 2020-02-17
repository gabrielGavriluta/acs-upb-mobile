import 'package:acs_upb_mobile/module/settings/settings_page.dart';
import 'package:appcenter/appcenter.dart';
import 'package:appcenter_analytics/appcenter_analytics.dart';
import 'package:appcenter_crashes/appcenter_crashes.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:preferences/preferences.dart';

import 'generated/l10n.dart';
import 'module/home/home_page.dart';
import 'routes/routes.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefService.init(prefix: 'pref_');
  PrefService.setDefaultValues({'language': 'auto'});
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _appSecret;
  String _installId = 'Unknown';
  bool _areAnalyticsEnabled = false, _areCrashesEnabled = false;

  _MyAppState() {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    _appSecret = kIsWeb
        ? "a2fc9ff0-a0aa-4a25-80e1-c1fb24c2ae77"
        : ios
            ? "225a5fc5-e5f5-4c85-bffa-7ac30be2116c"
            : "61321521-b6a4-4d1f-b9e6-42a02dfbb5f6";
  }

  @override
  initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    await AppCenter.start(
        _appSecret, [AppCenterAnalytics.id, AppCenterCrashes.id]);

    if (!mounted) return;

    var installId = await AppCenter.installId;

    var areAnalyticsEnabled = await AppCenterAnalytics.isEnabled;
    var areCrashesEnabled = await AppCenterCrashes.isEnabled;

    setState(() {
      _installId = installId;
      _areAnalyticsEnabled = areAnalyticsEnabled;
      _areCrashesEnabled = areCrashesEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
        defaultBrightness: Brightness.dark,
        data: (brightness) => ThemeData(
              brightness: brightness,
            ),
        themedWidgetBuilder: (context, theme) {
          return MaterialApp(
              title: "ACS UPB Mobile",
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                S.delegate
              ],
              supportedLocales: S.delegate.supportedLocales,
              theme: theme,
              routes: {
                Routes.home: (context) => HomePage(),
                Routes.settings: (context) => SettingsPage(),
              },
              home: HomePage());
        });
  }
}
