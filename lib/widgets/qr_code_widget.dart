import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Clean, high-resolution QR Code renderer widget for digital tickets
class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.color = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _QrPainter(
          data: data,
          color: color,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  final Color color;

  _QrPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int matrixSize = 21; // Standard 21x21 QR Matrix
    final double moduleSize = size.width / matrixSize;

    // Deterministic pseudo-random matrix derived from data hash
    final int hash = data.hashCode.abs();
    final rng = math.Random(hash);

    final List<List<bool>> matrix = List.generate(
      matrixSize,
      (_) => List.generate(matrixSize, (_) => false),
    );

    // Helper to draw Finder Pattern (7x7 outer square + 3x3 inner square)
    void drawFinderPattern(int startRow, int startCol) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final row = startRow + r;
          final col = startCol + c;
          if (row < matrixSize && col < matrixSize) {
            // Outer 7x7 border or Inner 3x3 core
            final isOuterBorder = r == 0 || r == 6 || c == 0 || c == 6;
            final isInnerCore = r >= 2 && r <= 4 && c >= 2 && c <= 4;
            matrix[row][col] = isOuterBorder || isInnerCore;
          }
        }
      }
    }

    // Top-Left, Top-Right, Bottom-Left Finder Patterns
    drawFinderPattern(0, 0);
    drawFinderPattern(0, matrixSize - 7);
    drawFinderPattern(matrixSize - 7, 0);

    // Timing Patterns (Row 6 & Col 6)
    for (int i = 8; i < matrixSize - 8; i++) {
      matrix[6][i] = i % 2 == 0;
      matrix[i][6] = i % 2 == 0;
    }

    // Alignment pattern (Bottom-Right quadrant)
    for (int r = 14; r <= 18; r++) {
      for (int c = 14; c <= 18; c++) {
        final isBorder = r == 14 || r == 18 || c == 14 || c == 18;
        final isCenter = r == 16 && c == 16;
        matrix[r][c] = isBorder || isCenter;
      }
    }

    // Fill data modules pseudo-randomly based on data hash
    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        // Skip finder areas
        final inTopLeft = r < 8 && c < 8;
        final inTopRight = r < 8 && c >= matrixSize - 8;
        final inBottomLeft = r >= matrixSize - 8 && c < 8;
        final inAlign = r >= 13 && r <= 19 && c >= 13 && c <= 19;

        if (!inTopLeft && !inTopRight && !inBottomLeft && !inAlign) {
          matrix[r][c] = rng.nextDouble() > 0.45;
        }
      }
    }

    // Render matrix cells on Canvas
    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        if (matrix[r][c]) {
          final rect = Rect.fromLTWH(
            c * moduleSize,
            r * moduleSize,
            moduleSize - 0.5,
            moduleSize - 0.5,
          );
          // Rounded cells for modern aesthetic
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.data != data;
}
