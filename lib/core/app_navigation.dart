import 'package:flutter/foundation.dart';

/// Lets screens outside the bottom navigation (e.g. the Downloads screen)
/// switch the selected tab.
class AppNavigation {
  static const int versesTab = 0;
  static const int playerTab = 1;

  static final ValueNotifier<int> tabIndex = ValueNotifier(versesTab);
}
