library flit.src.aux_channels;

import 'package:flutter/services.dart';

class AuxChannels {
  const AuxChannels._();

  static const MethodChannel titleBar = const MethodChannel(
    "flit/titlebar",
    const JSONMethodCodec(),
  );

  static const MethodChannel sdlTextInput = const MethodChannel(
    "flit/sdl/textinput",
    const JSONMethodCodec(),
  );
}
