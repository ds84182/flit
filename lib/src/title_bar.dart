library flit.lib.title_bar;

import 'dart:async';

import 'package:flit/src/aux_channels.dart';
import 'package:flutter/material.dart';

class TitleBarOverlay extends StatelessWidget {
  final Widget child;

  const TitleBarOverlay({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = new _MetricsController();

    return new Stack(
      children: <Widget>[
        child,
        new Positioned(
          left: 0.0,
          right: 0.0,
          top: 0.0,
          height: MediaQuery.of(context).padding.top,
          child: new DecoratedBox(
            decoration: new BoxDecoration(
              color: Colors.black26,
            ),
            child: new IconTheme(
              data: theme.primaryIconTheme.copyWith(size: 20.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  new Expanded(
                    child: new _SectionMetricsTracker(
                      controller: metrics,
                      section: _TitleBarSection.caption,
                    ),
                  ),
                  new MinimizeWindowButton(controller: metrics),
                  new MaximizeRestoreWindowButton(controller: metrics),
                  new CloseWindowButton(controller: metrics),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final ValueNotifier<bool> maximizeState = new ValueNotifier<bool>(false);

void initTitleBarChannel() {
  AuxChannels.titleBar.setMethodCallHandler((methodCall) {
    if (methodCall.method == "updateMaximizeState") {
      maximizeState.value = methodCall.arguments as bool;
    }
  });
}

enum _TitleBarSection { caption, close, restore, minimize }

class _MetricsController {
  final List<double> _metrics =
      new List<double>.filled(_TitleBarSection.values.length, 0.0);

  bool _scheduled = false;

  void _postUpdate() {
    AuxChannels.titleBar.invokeMethod("updateMetrics", _metrics);
  }

  void _schedule() {
    if (!_scheduled) {
      _scheduled = true;
      scheduleMicrotask(() {
        _scheduled = false;
        _postUpdate();
      });
    }
  }

  void updateMetric(_TitleBarSection section, double width) {
    _metrics[section.index] = width;
    _schedule();
  }
}

class _SectionMetricsTracker extends StatelessWidget {
  final Widget child;
  final _MetricsController controller;
  final _TitleBarSection section;

  const _SectionMetricsTracker(
      {Key key, this.child, this.controller, this.section})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (context, constraints) {
        controller.updateMetric(
          section,
          constraints.maxWidth * MediaQuery.of(context).devicePixelRatio,
        );
        return child ?? new Container();
      },
    );
  }
}

const _kButtonAspectRatio = 1.6;

class CloseWindowButton extends StatelessWidget {
  final _MetricsController controller;
  const CloseWindowButton({Key key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new AspectRatio(
      aspectRatio: _kButtonAspectRatio,
      child: new _SectionMetricsTracker(
        controller: controller,
        section: _TitleBarSection.close,
        child: new Material(
          type: MaterialType.transparency,
          child: new InkWell(
            onTap: () {
              AuxChannels.titleBar.invokeMethod("close");
            },
            child: new Center(
              child: const Icon(Icons.close),
            ),
          ),
        ),
      ),
    );
  }
}

class MaximizeRestoreWindowButton extends StatelessWidget {
  final _MetricsController controller;
  const MaximizeRestoreWindowButton({Key key, this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new AspectRatio(
      aspectRatio: _kButtonAspectRatio,
      child: new _SectionMetricsTracker(
        controller: controller,
        section: _TitleBarSection.restore,
        child: new Material(
          type: MaterialType.transparency,
          child: new InkWell(
            onTap: () {
              AuxChannels.titleBar.invokeMethod("restore");
            },
            child: new Center(
              child: new AnimatedBuilder(
                animation: maximizeState,
                builder: (context, widget) {
                  return maximizeState.value
                      ? const Icon(Icons.crop_square)
                      : const Icon(Icons.crop_16_9);
                },
              ),
              // Use Icons.crop_16_9 for maximize, Icons.crop_square for restore
            ),
          ),
        ),
      ),
    );
  }
}

class MinimizeWindowButton extends StatelessWidget {
  final _MetricsController controller;
  const MinimizeWindowButton({Key key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new AspectRatio(
      aspectRatio: _kButtonAspectRatio,
      child: new _SectionMetricsTracker(
        controller: controller,
        section: _TitleBarSection.minimize,
        child: new Material(
          type: MaterialType.transparency,
          child: new InkWell(
            onTap: () {
              AuxChannels.titleBar.invokeMethod("minimize");
            },
            child: new Center(
              child: const Icon(Icons.remove),
            ),
          ),
        ),
      ),
    );
  }
}
