import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/trip_entity.dart';

class LiveMapMarkerFactory {
  LiveMapMarkerFactory._();

  static const Color appBlue = Color(0xFF3B82F6);
  static const Color appBlueDark = Color(0xFF1E3A8A);
  static const Color readyGreen = Color(0xFF16A34A);
  static const Color waitingAmber = Color(0xFFF59E0B);
  static const Color completedSlate = Color(0xFF64748B);

  static const String lightMapStyle = '''
[
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]}
]
''';

  static const String darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2230"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#94a3b8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1d2230"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c3548"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#374151"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#475569"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f172a"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#16302b"}]},
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]}
]
''';

  static Color statusColorForStop(TripStopPoint stop) {
    if (stop.isCompleted) return completedSlate;
    return stop.isPassengerReady ? readyGreen : waitingAmber;
  }

  static String statusLabelForStop(TripStopPoint stop) {
    if (stop.isCompleted) return 'Embarcado';
    return stop.isPassengerReady ? 'Pronto' : 'Aguardando';
  }

  static String initialsFromName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Passageiro';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static Future<ui.Image?> _loadUiImage(String? rawUrl) async {
    final url = rawUrl?.trim();
    if (url == null || url.isEmpty) return null;

    try {
      Uint8List? bytes;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) bytes = res.bodyBytes;
      } else if (url.startsWith('assets/')) {
        final data = await rootBundle.load(url);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(url);
        if (await file.exists()) bytes = await file.readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) return null;

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 104,
        targetHeight: 104,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<BitmapDescriptor> createPassengerMapCardIcon(
    TripStopPoint stop, {
    required bool isDark,
  }) async {
    const double width = 316;
    const double height = 122;
    const double cardHeight = 92;

    final avatarImage = await _loadUiImage(stop.passengerPhotoUrl);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final accentColor = statusColorForStop(stop);
    final statusWord = statusLabelForStop(stop);

    final cardBgColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
    final titleColor =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final etaColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569);

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 6, width - 16, cardHeight),
      const Radius.circular(24),
    );

    canvas.drawShadow(
      Path()..addRRect(cardRect),
      Colors.black.withOpacity(isDark ? 0.55 : 0.25),
      9,
      true,
    );
    canvas.drawRRect(cardRect, Paint()..color = cardBgColor);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    final pointerPath = Path()
      ..moveTo(width / 2 - 14, 6 + cardHeight - 2)
      ..lineTo(width / 2 + 14, 6 + cardHeight - 2)
      ..lineTo(width / 2, height - 4)
      ..close();
    canvas.drawPath(pointerPath, Paint()..color = accentColor);

    const avatarCenter = Offset(54, 52);
    const double avatarRadius = 29;
    canvas.drawCircle(
      avatarCenter,
      avatarRadius + 3.5,
      Paint()..color = accentColor,
    );

    final avatarOval = Rect.fromCircle(
      center: avatarCenter,
      radius: avatarRadius,
    );

    if (avatarImage != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(avatarOval));
      final srcSize = math.min(avatarImage.width, avatarImage.height).toDouble();
      final srcLeft = (avatarImage.width - srcSize) / 2;
      final srcTop = (avatarImage.height - srcSize) / 2;
      canvas.drawImageRect(
        avatarImage,
        Rect.fromLTWH(srcLeft, srcTop, srcSize, srcSize),
        avatarOval,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      avatarImage.dispose();
    } else {
      canvas.drawCircle(
        avatarCenter,
        avatarRadius,
        Paint()..color = accentColor,
      );
      final initialsPainter = TextPainter(
        text: TextSpan(
          text: initialsFromName(stop.passengerName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      initialsPainter.paint(
        canvas,
        Offset(
          avatarCenter.dx - initialsPainter.width / 2,
          avatarCenter.dy - initialsPainter.height / 2,
        ),
      );
    }

    const badgeCenter = Offset(77, 75);
    canvas.drawCircle(badgeCenter, 13.5, Paint()..color = cardBgColor);
    canvas.drawCircle(badgeCenter, 11, Paint()..color = accentColor);
    final orderPainter = TextPainter(
      text: TextSpan(
        text: stop.isCompleted ? '✓' : '${stop.orderIndex}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    orderPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - orderPainter.width / 2,
        badgeCenter.dy - orderPainter.height / 2,
      ),
    );

    final namePainter = TextPainter(
      text: TextSpan(
        text: firstName(stop.passengerName),
        style: TextStyle(
          color: titleColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 118);
    namePainter.paint(canvas, const Offset(98, 17));

    final statusPainter = TextPainter(
      text: TextSpan(
        text: statusWord,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    const double pillLeft = 98;
    const double pillTop = 51;
    const double pillPadX = 11;
    const double pillHeight = 29;
    final double pillWidth = statusPainter.width + (pillPadX * 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pillLeft, pillTop, pillWidth, pillHeight),
        const Radius.circular(10),
      ),
      Paint()..color = accentColor,
    );
    statusPainter.paint(
      canvas,
      Offset(
        pillLeft + pillPadX,
        pillTop + (pillHeight - statusPainter.height) / 2,
      ),
    );

    if (!stop.isCompleted && stop.estimatedMinutesRemaining != null) {
      final etaLeft = pillLeft + pillWidth + 8;
      final remainingWidth = (width - 18) - etaLeft;
      if (remainingWidth >= 34) {
        final etaPainter = TextPainter(
          text: TextSpan(
            text: '${stop.estimatedMinutesRemaining} min',
            style: TextStyle(
              color: etaColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: remainingWidth);
        etaPainter.paint(
          canvas,
          Offset(etaLeft, pillTop + (pillHeight - etaPainter.height) / 2),
        );
      }
    }

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 170,
      height: 66,
    );
  }

  /// Marcador anônimo para a visão 2D do passageiro: indica apenas se há alguém
  /// pronto (verde), aguardando (âmbar) ou já embarcado (cinza), sem expor dados pessoais.
  static Future<BitmapDescriptor> createAnonymousStopIcon({
    required bool isReady,
    required bool isCompleted,
    required bool isDark,
  }) async {
    const double size = 84;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    final color = isCompleted
        ? completedSlate
        : (isReady ? readyGreen : waitingAmber);

    final ringColor = isDark ? const Color(0xFF111827) : Colors.white;

    // Halo suave de status
    canvas.drawCircle(center, 38, Paint()..color = color.withOpacity(0.22));
    // Borda externa contrastante com o tema
    canvas.drawCircle(center, 27, Paint()..color = ringColor);
    // Núcleo com a cor do status
    canvas.drawCircle(center, 21, Paint()..color = color);

    final iconData = isCompleted
        ? Icons.check_rounded
        : (isReady ? Icons.person_rounded : Icons.schedule_rounded);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 30,
      height: 30,
    );
  }

  static Future<BitmapDescriptor> createDriverArrowIcon() async {
    const double size = 140;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.drawCircle(center, 58, Paint()..color = appBlue.withOpacity(0.24));

    final arrowPath = Path()
      ..moveTo(size * 0.50, size * 0.16)
      ..lineTo(size * 0.80, size * 0.78)
      ..lineTo(size * 0.50, size * 0.65)
      ..lineTo(size * 0.20, size * 0.78)
      ..close();

    canvas.drawShadow(arrowPath, Colors.black.withOpacity(0.45), 8, true);
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = appBlue
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 52,
      height: 52,
    );
  }

  static Future<BitmapDescriptor> createBusVehicleIcon() async {
    const double size = 128;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      58,
      Paint()..color = readyGreen.withOpacity(0.20),
    );
    canvas.drawCircle(center, 44, Paint()..color = Colors.white);
    canvas.drawCircle(center, 37, Paint()..color = readyGreen);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.directions_bus_rounded.codePoint),
        style: TextStyle(
          fontSize: 44,
          fontFamily: Icons.directions_bus_rounded.fontFamily,
          package: Icons.directions_bus_rounded.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 48,
      height: 48,
    );
  }

  static Future<BitmapDescriptor> createDestinationIcon() async {
    const double size = 104;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.drawCircle(center, 44, Paint()..color = Colors.white);
    canvas.drawCircle(center, 37, Paint()..color = const Color(0xFFDC2626));

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'FIM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 40,
      height: 40,
    );
  }
}