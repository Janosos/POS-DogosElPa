import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/manga_theme.dart';

class HalftoneBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color dotColor;

  const HalftoneBackground({
    super.key,
    required this.child,
    this.backgroundColor = MangaColors.bgCream,
    this.dotColor = const Color(0x281E1E1E),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _HalftoneTilePainter(dotColor: dotColor),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HalftoneTilePainter extends CustomPainter {
  final Color dotColor;
  static ui.ImageShader? _tileShader;
  static bool _isGenerating = false;

  _HalftoneTilePainter({required this.dotColor});

  static void _ensureTile(Color color) {
    if (_tileShader != null || _isGenerating) return;
    _isGenerating = true;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 24, 24));
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(6, 6), 0.9, dotPaint);
    canvas.drawCircle(const Offset(18, 18), 0.9, dotPaint);
    final picture = recorder.endRecording();
    picture.toImage(24, 24).then((img) {
      _tileShader = ui.ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
      _isGenerating = false;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_tileShader == null) {
      _ensureTile(dotColor);
      return;
    }
    final paint = Paint()..shader = _tileShader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _HalftoneTilePainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}

class MangaPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color? hoverColor;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final String? tooltip;

  const MangaPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.hoverColor,
    this.borderRadius = 12,
    this.borderWidth = 2.0,
    this.borderColor = Colors.black,
    this.shadow = MangaShadows.sm,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.tooltip,
  });

  @override
  State<MangaPressButton> createState() => _MangaPressButtonState();
}

class _MangaPressButtonState extends State<MangaPressButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = (_isHovered && widget.hoverColor != null)
        ? widget.hoverColor!
        : widget.backgroundColor;

    Widget content = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          transform: Matrix4.translationValues(
            _isPressed ? 2.0 : 0.0,
            _isPressed ? 2.0 : 0.0,
            0.0,
          ),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
            boxShadow: _isPressed ? MangaShadows.pressed : widget.shadow,
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        child: content,
      );
    }
    return content;
  }
}

class MangaDashedDivider extends StatelessWidget {
  final Color color;
  final double height;

  const MangaDashedDivider({
    super.key,
    this.color = const Color(0x4D000000),
    this.height = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color, height: height),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double height;

  _DashedLinePainter({required this.color, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = height
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    double x = 0;
    final y = size.height / 2;

    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.height != height;
}

class ProductImageDisplay extends StatelessWidget {
  final String? localImagePath;
  final String? imageBase64;
  final String? imageUrl;
  final String fallbackLabel;
  final BoxFit fit;

  static final Map<String, Uint8List> _base64Cache = {};

  const ProductImageDisplay({
    super.key,
    this.localImagePath,
    this.imageBase64,
    this.imageUrl,
    required this.fallbackLabel,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Check local file path first (Async file image decoding with downsampling cache)
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return Image.file(
        File(localImagePath!),
        fit: fit,
        cacheWidth: 320,
        cacheHeight: 320,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildBase64OrNetworkFallback(),
      );
    }
    return _buildBase64OrNetworkFallback();
  }

  Widget _buildBase64OrNetworkFallback() {
    // 2. Check embedded Base64 data (cached in memory for high FPS scrolling)
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final Uint8List bytes = _base64Cache.putIfAbsent(
          imageBase64!,
          () => base64Decode(imageBase64!),
        );
        return Image.memory(
          bytes,
          fit: fit,
          cacheWidth: 320,
          cacheHeight: 320,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildNetworkOrEmojiFallback(),
        );
      } catch (_) {}
    }
    return _buildNetworkOrEmojiFallback();
  }

  Widget _buildNetworkOrEmojiFallback() {
    // 3. Check network URL
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: fit,
        cacheWidth: 320,
        cacheHeight: 320,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildComicPlaceholder(),
      );
    }
    return _buildComicPlaceholder();
  }

  Widget _buildComicPlaceholder() {
    return Container(
      color: MangaColors.cardImageBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fastfood_rounded,
            size: 34,
            color: Colors.black87,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              fallbackLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MangaFonts.comic(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

