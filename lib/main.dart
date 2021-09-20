import 'dart:async';
import 'dart:developer';

import 'package:bbq_app/camera_page.dart';
import 'package:bbq_app/shared/prefs.dart';
import 'package:bbq_app/shared/state.dart';
import 'package:bbq_app/shared/util/environment.dart';
import 'package:bbq_app/webview_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.init();

  final cameras = await availableCameras();

  runZonedGuarded<void>(
    () => runApp(
      MaterialApp(
        title: appName,
        theme: theme,
        home: ChangeNotifierProvider(
          create: (_) => AppState(),
          child: CameraPage(cameras),
        ),
        routes: {WebViewPage.route: (_) => const WebViewPage()},
      ),
    ),
    (dynamic error, dynamic stack) {
      log('Some explosion here...', error: error, stackTrace: stack);
    },
  );
}
