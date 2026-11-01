import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:home_widget/home_widget.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/charging_cycle.dart';
import '../../domain/entities/charging_session.dart';
import '../widgets/cycle_history_grid.dart';

/// Keeps the Android home screen widget showing the dashboard's top card.
///
/// Home screen widgets cannot host Flutter, so the real [CycleHistoryGrid], in
/// its compact one row form, is drawn to a PNG that the native widget displays. Sessions only change inside
/// the app, so refreshing the image from there keeps it current.
abstract final class ChargingHomeWidget {
  static const _imageKey = 'charging_card';
  static const _androidProvider =
      'com.rubin.chargingtracker.ChargingCardWidgetProvider';
  static const _logChargeHost = 'log';

  /// Roughly a four cell wide widget, so the card keeps its in-app proportions.
  static const double _cardWidth = 360;
  static const double _pixelRatio = 2;

  static final ThemeData _theme = AppTheme.dark;

  static Future<void> _pendingUpdate = Future.value();

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Taps on the widget while the app is already running.
  static Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  /// The tap that started the app, if there was one.
  static Future<Uri?> initialClick() =>
      HomeWidget.initiallyLaunchedFromHomeWidget();

  static bool isLogCharge(Uri? uri) => uri?.host == _logChargeHost;

  /// Redraws the widget. Updates run one at a time so the newest sessions are
  /// always the last ones written, and a failure never reaches the app.
  static void update(List<ChargingSession> sessions) {
    if (!isSupported) {
      return;
    }

    _pendingUpdate = _pendingUpdate.then((_) async {
      try {
        final image = await _renderCard(sessions);
        await HomeWidget.saveFile(_imageKey, image, extension: 'png');
        await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
      } catch (error, stackTrace) {
        developer.log(
          'Could not update the home screen widget',
          name: 'ChargingHomeWidget',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  static Widget _buildCard(List<ChargingSession> sessions) => MediaQuery(
    data: const MediaQueryData(
      size: Size(_cardWidth, 1000),
      devicePixelRatio: _pixelRatio,
      textScaler: TextScaler.noScaling,
    ),
    child: Theme(
      data: _theme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: _cardWidth,
          child: CycleHistoryGrid(
            sessions: sessions,
            cycle: ChargingCycle.fromSessions(sessions),
            onLogCharge: () {},
            compact: true,
          ),
        ),
      ),
    ),
  );

  /// Draws the card offscreen at its natural height, so the image has no blank
  /// space around it however many rows the card has.
  static Future<Uint8List> _renderCard(List<ChargingSession> sessions) async {
    final boundary = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.implicitView!,
      child: RenderPositionedBox(
        alignment: Alignment.topCenter,
        child: boundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(const Size(_cardWidth, 1000)),
        devicePixelRatio: _pixelRatio,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: _buildCard(sessions),
    ).attachToRenderTree(buildOwner);

    try {
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) {
        throw StateError('The card could not be encoded.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
        child: const SizedBox.shrink(),
      ).attachToRenderTree(buildOwner, root);
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      buildOwner.focusManager.dispose();
    }
  }
}
