library flit;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'src/title_bar.dart';
import 'src/sdl_text_input.dart';

void flitInit() {
  if (Platform.isWindows) {
    initTitleBarChannel();
  }

  initSDLTextInput();
}

/// Widget that wraps an app in platform-specific widgets.
///
/// Usage:
///
/// Add (or merge into, if it exists) this line to your MaterialApp.
///
/// ```dart
/// builder: (context, child) => new FlitAppWrapper(child: child),
/// ```
class FlitAppWrapper extends StatelessWidget {
  final Widget child;
  const FlitAppWrapper({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return new TitleBarOverlay(
        child: child,
      );
    } else {
      return child;
    }
  }
}
