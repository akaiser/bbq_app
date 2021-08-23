import 'package:flutter/material.dart';

const appName = 'BBQ App';
const mainColor = Color(0xff303030);
const mainTextStyle = TextStyle(fontSize: 16);
const processInterval = Duration(seconds: 2);
const progressBarHeight = 4.0;

final theme = ThemeData.dark().copyWith(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: OpenUpwardsPageTransitionsBuilder(),
    },
  ),
);
