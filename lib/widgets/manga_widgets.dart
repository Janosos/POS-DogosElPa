import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
    return CustomPaint(
      painter: _HalftonePainter(
        backgroundColor: backgroundColor,
        dotColor: dotColor,
      ),
      child: child,
    );
  }
}

class _HalftonePainter extends CustomPainter {
  final Color backgroundColor;
  final Color dotColor;

  _HalftonePainter({
    required this.backgroundColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const double step = 14.0;
    const double radius = 0.85;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
        canvas.drawCircle(
          Offset(x + step / 2, y + step / 2),
          radius,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HalftonePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dotColor != dotColor;
  }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

class ProductImageDisplay extends StatelessWidget {
  final String? localImagePath;
  final String? imageBase64;
  final String? imageUrl;
  final String fallbackLabel;
  final BoxFit fit;

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
    // 1. Check local file path first
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      final file = File(localImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _buildBase64OrNetworkFallback(),
        );
      }
    }
    return _buildBase64OrNetworkFallback();
  }

  Widget _buildBase64OrNetworkFallback() {
    // 2. Check embedded Base64 data (portable across devices & LAN!)
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(imageBase64!);
        return Image.memory(
          bytes,
          fit: fit,
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

