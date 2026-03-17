// 3D Isometric City Painter — SimCity-style canvas drawing
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/building.dart';
import '../constants.dart';
import '../theme/app_theme.dart';

// ── ISOMETRIC GRID PAINTER ────────────────────────────────────
// Each cell is drawn as an isometric tile. Buildings grow upward.
// Isometric projection: x-right = screen right+down, y-up = screen right+up up.

class CityIsometricPainter extends CustomPainter {
  final List<BuildingModel> buildings;
  final int selectedIndex;
  final double scale;

  CityIsometricPainter({required this.buildings, this.selectedIndex = -1, this.scale = 1.0});

  // Isometric tile size
  static const double tileW = 72.0;
  static const double tileH = 36.0;
  static const int gridCols = 6;
  static const int gridRows = 6;

  // Convert grid (col, row) to screen (x, y) — top corner of tile
  Offset isoToScreen(int col, int row, double cx, double cy) {
    final sx = cx + (col - row) * tileW / 2;
    final sy = cy + (col + row) * tileH / 2;
    return Offset(sx, sy);
  }

  // Get grid position for building index
  (int, int) gridPos(int idx) {
    // Arrange buildings in a city block pattern
    final col = idx % gridCols;
    final row = idx ~/ gridCols;
    return (col, row);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = 60.0;

    // ── DRAW GROUND GRID ──
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        _drawGroundTile(canvas, col, row, cx, cy);
      }
    }

    // ── DRAW ROADS ──
    _drawRoads(canvas, cx, cy);

    // ── DRAW BUILDINGS (from back to front for correct z-ordering) ──
    final sorted = List.generate(buildings.length, (i) => i)
      ..sort((a, b) {
        final (ca, ra) = gridPos(a);
        final (cb, rb) = gridPos(b);
        return (ca + ra).compareTo(cb + rb);
      });

    for (final idx in sorted) {
      final (col, row) = gridPos(idx);
      _drawBuilding(canvas, buildings[idx], col, row, cx, cy, idx == selectedIndex);
    }

    // ── EMPTY PLOTS for remaining spaces ──
    for (int i = buildings.length; i < math.min(buildings.length + 4, gridCols * gridRows); i++) {
      final (col, row) = gridPos(i);
      _drawEmptyPlot(canvas, col, row, cx, cy);
    }
  }

  void _drawGroundTile(Canvas canvas, int col, int row, double cx, double cy) {
    final pos = isoToScreen(col, row, cx, cy);
    final paint = Paint()..color = const Color(0xFF1A3A2A).withOpacity(0.8)..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = const Color(0xFF243D30)..style = PaintingStyle.stroke..strokeWidth = 0.8;

    final path = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(pos.dx + tileW / 2, pos.dy + tileH / 2)
      ..lineTo(pos.dx, pos.dy + tileH)
      ..lineTo(pos.dx - tileW / 2, pos.dy + tileH / 2)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawRoads(Canvas canvas, double cx, double cy) {
    // Horizontal road between row 2 and 3
    final roadPaint = Paint()..color = const Color(0xFF2D3A3A)..style = PaintingStyle.fill;
    for (int col = 0; col < gridCols; col++) {
      final pos = isoToScreen(col, 3, cx, cy);
      final path = Path()
        ..moveTo(pos.dx, pos.dy)
        ..lineTo(pos.dx + tileW / 2, pos.dy + tileH / 2)
        ..lineTo(pos.dx, pos.dy + tileH)
        ..lineTo(pos.dx - tileW / 2, pos.dy + tileH / 2)
        ..close();
      canvas.drawPath(path, roadPaint);

      // Road markings
      final markPaint = Paint()..color = const Color(0xFFFFD600).withOpacity(0.3)..strokeWidth = 1;
      canvas.drawLine(Offset(pos.dx - tileW / 4, pos.dy + tileH * 0.75), Offset(pos.dx + tileW / 4, pos.dy + tileH * 0.25), markPaint);
    }
  }

  void _drawEmptyPlot(Canvas canvas, int col, int row, double cx, double cy) {
    final pos = isoToScreen(col, row, cx, cy);
    // Dashed outline to indicate buildable plot
    final paint = Paint()..color = const Color(0xFF2E7D32).withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(pos.dx + tileW / 2, pos.dy + tileH / 2)
      ..lineTo(pos.dx, pos.dy + tileH)
      ..lineTo(pos.dx - tileW / 2, pos.dy + tileH / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawBuilding(Canvas canvas, BuildingModel b, int col, int row, double cx, double cy, bool selected) {
    final pos    = isoToScreen(col, row, cx, cy);
    final cat    = kBuildingCats[b.category] ?? kBuildingCats['house']!;
    final tier   = getBuildingTier(b.amount);
    final height = _tierHeight(tier.index);
    final color  = cat.color;

    if (tier.index == 0) {
      _drawEmptyPlot(canvas, col, row, cx, cy);
      return;
    }

    // ── TOP FACE ──
    final topPaint = Paint()..color = color..style = PaintingStyle.fill;
    final topPath  = Path()
      ..moveTo(pos.dx, pos.dy - height)
      ..lineTo(pos.dx + tileW / 2, pos.dy + tileH / 2 - height)
      ..lineTo(pos.dx, pos.dy + tileH - height)
      ..lineTo(pos.dx - tileW / 2, pos.dy + tileH / 2 - height)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // ── LEFT FACE (darker) ──
    final leftPaint = Paint()..color = Color.lerp(color, Colors.black, 0.35)!..style = PaintingStyle.fill;
    final leftPath  = Path()
      ..moveTo(pos.dx - tileW / 2, pos.dy + tileH / 2 - height)
      ..lineTo(pos.dx, pos.dy + tileH - height)
      ..lineTo(pos.dx, pos.dy + tileH)
      ..lineTo(pos.dx - tileW / 2, pos.dy + tileH / 2)
      ..close();
    canvas.drawPath(leftPath, leftPaint);

    // ── RIGHT FACE (medium shade) ──
    final rightPaint = Paint()..color = Color.lerp(color, Colors.black, 0.20)!..style = PaintingStyle.fill;
    final rightPath  = Path()
      ..moveTo(pos.dx, pos.dy + tileH - height)
      ..lineTo(pos.dx + tileW / 2, pos.dy + tileH / 2 - height)
      ..lineTo(pos.dx + tileW / 2, pos.dy + tileH / 2)
      ..lineTo(pos.dx, pos.dy + tileH)
      ..close();
    canvas.drawPath(rightPath, rightPaint);

    // ── WINDOWS on right face ──
    if (tier.index >= 3) {
      _drawWindows(canvas, pos, height, tier.index, color);
    }

    // ── ROOF DETAILS ──
    _drawRoof(canvas, pos, height, tier.index, color);

    // ── EDGE HIGHLIGHT ──
    final edgePaint = Paint()
      ..color = selected ? AppTheme.accent : Colors.white.withOpacity(0.15)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.0 : 0.8;
    canvas.drawPath(topPath, edgePaint);
    if (selected) {
      // Glow ring
      final glowPaint = Paint()..color = AppTheme.accent.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 5;
      canvas.drawPath(topPath, glowPaint);
    }

    // ── BUILDING ICON on top face ──
    final textPainter = TextPainter(
      text: TextSpan(text: cat.icon, style: const TextStyle(fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy + tileH / 2 - height - textPainter.height / 2 - 2));
  }

  void _drawWindows(Canvas canvas, Offset pos, double height, int tierIdx, Color wallColor) {
    final winPaint = Paint()..color = const Color(0xFFB3E5FC).withOpacity(0.8)..style = PaintingStyle.fill;
    final winRows = math.min(tierIdx - 1, 3);
    final winCols = math.min(tierIdx, 4);
    for (int r = 0; r < winRows; r++) {
      for (int c = 0; c < winCols; c++) {
        final wx = pos.dx + (tileW / 2) * 0.15 + c * (tileW / 2) * 0.18;
        final wy = pos.dy + tileH - height * 0.75 + r * (height * 0.18);
        canvas.drawRect(Rect.fromLTWH(wx, wy, 5, 7), winPaint);
      }
    }
  }

  void _drawRoof(Canvas canvas, Offset pos, double height, int tierIdx, Color color) {
    if (tierIdx < 2) return;
    final roofColor = Color.lerp(color, Colors.white, 0.15)!;
    final roofPaint = Paint()..color = roofColor..style = PaintingStyle.fill;
    if (tierIdx <= 3) {
      // Pointed roof
      final roofPath = Path()
        ..moveTo(pos.dx, pos.dy - height - 10)
        ..lineTo(pos.dx + tileW / 3, pos.dy + tileH / 2 - height)
        ..lineTo(pos.dx - tileW / 3, pos.dy + tileH / 2 - height)
        ..close();
      canvas.drawPath(roofPath, roofPaint);
    } else {
      // Flat roof with parapet
      final parPaint = Paint()..color = Color.lerp(color, Colors.white, 0.1)!..style = PaintingStyle.fill;
      final parPath = Path()
        ..moveTo(pos.dx, pos.dy - height - 5)
        ..lineTo(pos.dx + tileW / 2, pos.dy + tileH / 2 - height - 5)
        ..lineTo(pos.dx, pos.dy + tileH - height - 5)
        ..lineTo(pos.dx - tileW / 2, pos.dy + tileH / 2 - height - 5)
        ..close();
      canvas.drawPath(parPath, parPaint);
    }
    // Antenna for mansions
    if (tierIdx == 6) {
      final antPaint = Paint()..color = Colors.grey..strokeWidth = 1.5..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(pos.dx, pos.dy - height - 12), Offset(pos.dx, pos.dy - height - 28), antPaint);
      canvas.drawCircle(Offset(pos.dx, pos.dy - height - 28), 3, Paint()..color = Colors.red);
    }
  }

  double _tierHeight(int tierIdx) {
    const heights = [0.0, 20.0, 36.0, 54.0, 72.0, 94.0, 120.0];
    return tierIdx < heights.length ? heights[tierIdx] : 120.0;
  }

  @override
  bool shouldRepaint(covariant CityIsometricPainter old) =>
      old.buildings != buildings || old.selectedIndex != selectedIndex;
}
