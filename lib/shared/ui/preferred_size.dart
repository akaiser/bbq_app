import 'package:flutter/material.dart';

class PreferredSizeWidgetWrapper extends StatelessWidget
    implements PreferredSizeWidget {
  PreferredSizeWidgetWrapper({
    required this.child,
    bool addNavigationBarHeight = false,
    Key? key,
  })  : preferredSize = Size.fromHeight(kToolbarHeight +
            (addNavigationBarHeight ? kBottomNavigationBarHeight : 0)),
        super(key: key);

  final Widget child;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) => child;
}
