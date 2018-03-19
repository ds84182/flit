library flit;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'src/title_bar.dart';
import 'src/sdl_text_input.dart';

void flitInit() {
  if (Platform.isWindows) {
    PlatformOverlay.addOverlay((context, child) {
      return new TitleBarOverlay(child: child);
    });

    initTitleBarChannel();
  }

  initSDLTextInput();
}
