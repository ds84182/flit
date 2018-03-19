library flit.src.sdl_text_input;

import 'package:flit/src/aux_channels.dart';
import 'package:flutter/services.dart';

void initSDLTextInput() {
  new _SDLTextHandler();
}

class _SDLTextHandler {
  int transaction;
  TextEditingValue state;

  static const int kKeyDown = 0;
  static const int kKeyRepeat = 1;
  static const int kKeyUp = 2;

  static const int kKCBackspace = 8;
  static const int kKCDelete = 127;

  static const int kKCLeft = 1073741904;
  static const int kKCRight = 1073741903;

  _SDLTextHandler() {
    SystemChannels.textInput.setMockMethodCallHandler((call) {
      if (call.method == "TextInput.setClient") {
        AuxChannels.sdlTextInput.invokeMethod("start");
        transaction = (call.arguments as List)[0] as int;
      } else if (call.method == "TextInput.setEditingState") {
        state = new TextEditingValue.fromJSON(call.arguments);
      } else if (call.method == "TextInput.clearClient") {
        transaction = null;
        state = null;
        AuxChannels.sdlTextInput.invokeMethod("stop");
      }
    });

    AuxChannels.sdlTextInput.setMethodCallHandler((call) {
      if (call.method == "textEditing") {
        if (state == null) return;
        // TODO: Handle properly
      } else if (call.method == "textInput") {
        if (state == null) return;

        final text = call.arguments as String;

        insert(text);
        updateEditingState();
      } else if (call.method == "keyInput") {
        if (state == null) return;

        final args = call.arguments as List;

        // [`key` int, `mod` int, `type` 0 (down) | 1 (repeat) | 2 (up)]
        print(call.arguments);

        final key = args[0] as int;
        final mod = args[1] as int;
        final type = args[2] as int;

        if (type == kKeyDown || type == kKeyRepeat) {
          if (key == kKCBackspace) {
            backspace();
            updateEditingState();
          } else if (key == kKCDelete) {
            delete();
            updateEditingState();
          } else if (key == kKCLeft) {
            left();
            updateEditingState();
          } else if (key == kKCRight) {
            right();
            updateEditingState();
          }
        }
      }
    });
  }

  void backspace() {
    if (state.selection.isCollapsed) {
      final newOffset = state.selection.baseOffset - 1;

      if (newOffset >= 0) {
        state = state.copyWith(
          text: state.text.replaceRange(newOffset, newOffset + 1, ""),
          selection: state.selection.copyWith(
            baseOffset: newOffset,
            extentOffset: newOffset,
          ),
        );
      }
    } else {
      insert("");
    }
  }

  void delete() {
    if (state.selection.isCollapsed) {
      state = state.copyWith(
        text: state.text.replaceRange(
            state.selection.baseOffset, state.selection.baseOffset + 1, ""),
      );
    } else {
      insert("");
    }
  }

  void insert(String text) {
    final newOffset = state.selection.baseOffset + text.length;

    state = state.copyWith(
      text: state.text
          .replaceRange(state.selection.start, state.selection.end, text),
      selection: state.selection.copyWith(
        baseOffset: newOffset,
        extentOffset: newOffset,
      ),
    );
  }

  void left() {
    if (state.selection.isCollapsed) {
      final newOffset = state.selection.baseOffset - 1;
      if (newOffset >= 0) {
        state = state.copyWith(
          selection: state.selection.copyWith(
            baseOffset: newOffset,
            extentOffset: newOffset,
          ),
        );
      }
    } else {
      final newOffset = state.selection.baseOffset;
      state = state.copyWith(
        selection: state.selection.copyWith(
          baseOffset: newOffset,
          extentOffset: newOffset,
        ),
      );
    }
  }

  void right() {
    if (state.selection.isCollapsed) {
      final newOffset = state.selection.baseOffset + 1;
      if (newOffset <= state.text.length) {
        state = state.copyWith(
          selection: state.selection.copyWith(
            baseOffset: newOffset,
            extentOffset: newOffset,
          ),
        );
      }
    } else {
      final newOffset = state.selection.extentOffset;
      state = state.copyWith(
        selection: state.selection.copyWith(
          baseOffset: newOffset,
          extentOffset: newOffset,
        ),
      );
    }
  }

  void updateEditingState() {
    BinaryMessages.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        new MethodCall(
          "TextInputClient.updateEditingState",
          [
            transaction,
            state.toJSON(),
          ],
        ),
      ),
      ignoreReply,
    );
  }

  static void ignoreReply(reply) {}
}
