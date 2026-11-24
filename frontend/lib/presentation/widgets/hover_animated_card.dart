import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Contenedor interactivo con animacion suave al pasar el cursor (PC) o tocar (Tablet y Celular)
class HoverAnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? activeBorderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const HoverAnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.activeBorderColor,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 8,
  });

  @override
  State<HoverAnimatedCard> createState() => _HoverAnimatedCardState();
}

class _HoverAnimatedCardState extends State<HoverAnimatedCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  // Actualiza el estado cuando el cursor entra o sale en PC y Laptop
  void _setHovered(bool value) {
    if (_isHovered != value) {
      setState(() {
        _isHovered = value;
      });
    }
  }

  // Actualiza el estado cuando el usuario presiona la tarjeta en pantalla tactil
  void _setPressed(bool value) {
    if (_isPressed != value) {
      setState(() {
        _isPressed = value;
      });
    }
  }

  // Construye la tarjeta con transicion fluida de escala, desplazamiento y color de borde
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = _isHovered || _isPressed;

    final Color defaultBg = widget.backgroundColor ??
        (isDark ? AppColors.darkSurface : Colors.white);
    final Color defaultBorder =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color highlightBorder = widget.activeBorderColor ??
        (isDark ? AppColors.footerAccentBlue : AppColors.secondaryBlue);

    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: isActive ? 1.016 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: isActive ? const Offset(0, -0.012) : Offset.zero,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: defaultBg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: isActive ? highlightBorder : defaultBorder,
                width: isActive ? 1.6 : 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: widget.onTap,
                onHighlightChanged: _setPressed,
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
