import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/aviso_institucional.dart';

// Carrusel hero fotografico con transicion animada, rotacion automatica y flechas suaves
class NoticesCarousel extends StatefulWidget {
  final List<AvisoInstitucional> avisos;
  final ValueChanged<String>? onActionPressed;

  const NoticesCarousel({
    super.key,
    required this.avisos,
    this.onActionPressed,
  });

  @override
  State<NoticesCarousel> createState() => _NoticesCarouselState();
}

class _NoticesCarouselState extends State<NoticesCarousel> {
  int _indiceActual = 0;
  Timer? _autoRotationTimer;
  bool _rotacionDetenidaPorUsuario = false;
  bool _mostrarFlechas = false;

  @override
  void initState() {
    super.initState();
    _iniciarRotacionAutomatica();
  }

  @override
  void dispose() {
    _autoRotationTimer?.cancel();
    super.dispose();
  }

  // Inicia el temporizador para rotar la imagen del banner cada 5 segundos
  void _iniciarRotacionAutomatica() {
    _autoRotationTimer?.cancel();
    _autoRotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _rotacionDetenidaPorUsuario || widget.avisos.length <= 1) {
        return;
      }
      setState(() {
        _indiceActual = (_indiceActual + 1) % widget.avisos.length;
      });
    });
  }

  // Detiene la rotacion automatica cuando el usuario da clic o cambia manualmente de imagen
  void _detenerRotacionPorInteraccion() {
    _rotacionDetenidaPorUsuario = true;
    _autoRotationTimer?.cancel();
  }

  // Reinicia el indice si cambia el filtro de campus activo
  @override
  void didUpdateWidget(covariant NoticesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_indiceActual >= widget.avisos.length) {
      _indiceActual = 0;
    }
  }

  // Avanza manualmente a la siguiente fotografia con transicion animada
  void _siguienteAvisoManual() {
    if (widget.avisos.isEmpty) return;
    _detenerRotacionPorInteraccion();
    setState(() {
      _indiceActual = (_indiceActual + 1) % widget.avisos.length;
      _mostrarFlechas = true;
    });
  }

  // Retrocede manualmente a la fotografia anterior con transicion animada
  void _anteriorAvisoManual() {
    if (widget.avisos.isEmpty) return;
    _detenerRotacionPorInteraccion();
    setState(() {
      _indiceActual =
          (_indiceActual - 1 + widget.avisos.length) % widget.avisos.length;
      _mostrarFlechas = true;
    });
  }

  // Construye el banner fotografico con cross-fade animado en imagen y texto
  @override
  Widget build(BuildContext context) {
    if (widget.avisos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        color: AppColors.primaryNavy,
        child: const Text(
          'No hay comunicados registrados para el campus seleccionado.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final AvisoInstitucional aviso = widget.avisos[_indiceActual];
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 680;
    final bool isWide = screenWidth >= 1280;
    final double bannerHeight = isMobile ? 300 : (isWide ? 450 : 380);

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _mostrarFlechas = true;
        });
      },
      onExit: (_) {
        setState(() {
          _mostrarFlechas = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          // Al tocar o dar clic en el banner se pausa la rotacion y se muestran/ocultan las flechas
          _detenerRotacionPorInteraccion();
          setState(() {
            _mostrarFlechas = !_mostrarFlechas;
          });
        },
        child: SizedBox(
          width: double.infinity,
          height: bannerHeight,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Transicion animada de fotografia y escala suave al cambiar de diapositiva
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 520),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  final Animation<double> scaleAnimation =
                      Tween<double>(begin: 1.03, end: 1.0).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  aviso.imagenAsset,
                  key: ValueKey<String>(aviso.idAviso),
                  width: double.infinity,
                  height: bannerHeight,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              // Franja inferior plana semitransparente con texto animado al cambiar de aviso
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xE00F2444),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 48,
                    vertical: isMobile ? 14 : 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              final Animation<Offset> slideAnimation =
                                  Tween<Offset>(
                                begin: const Offset(0.02, 0),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slideAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey<String>('texto_${aviso.idAviso}'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: <Widget>[
                                    _buildHeroBadge(
                                      aviso.categoria.toUpperCase(),
                                      AppColors.secondaryBlue,
                                    ),
                                    _buildHeroBadge(
                                      aviso.nombreCampus.toUpperCase(),
                                      AppColors.accentCrimson,
                                    ),
                                    Text(
                                      aviso.fechaPublicacion,
                                      style: const TextStyle(
                                        color: Color(0xFFD0DCF0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            aviso.titulo,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isMobile
                                                  ? 17
                                                  : (isWide ? 24 : 21),
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            aviso.resumen,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: const Color(0xFFE2E9F5),
                                              fontSize: isMobile ? 13 : 14,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isMobile) ...<Widget>[
                                      const SizedBox(width: 24),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppColors.secondaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        onPressed: () {
                                          _detenerRotacionPorInteraccion();
                                          if (widget.onActionPressed != null) {
                                            widget.onActionPressed!(
                                              aviso.categoria,
                                            );
                                          }
                                        },
                                        child: const Text(
                                          'VER INFORMACION',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Indicadores inferiores con animacion fluida de ancho
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List<Widget>.generate(
                              widget.avisos.length,
                              (int index) {
                                final bool activo = index == _indiceActual;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () {
                                      _detenerRotacionPorInteraccion();
                                      setState(() {
                                        _indiceActual = index;
                                        _mostrarFlechas = true;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 260),
                                      curve: Curves.easeOutCubic,
                                      width: activo ? 28 : 10,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: activo
                                            ? Colors.white
                                            : Colors.white38,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Las flechas laterales aparecen y desaparecen con opacidad suave cuando se interactua
              if (_mostrarFlechas && widget.avisos.length > 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder:
                          (BuildContext context, double opacity, Widget? child) {
                        return Opacity(opacity: opacity, child: child);
                      },
                      child: _buildCircleArrowButton(
                        icon: Icons.chevron_left,
                        onTap: _anteriorAvisoManual,
                      ),
                    ),
                  ),
                ),
              if (_mostrarFlechas && widget.avisos.length > 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder:
                          (BuildContext context, double opacity, Widget? child) {
                        return Opacity(opacity: opacity, child: child);
                      },
                      child: _buildCircleArrowButton(
                        icon: Icons.chevron_right,
                        onTap: _siguienteAvisoManual,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Boton circular plano para cambiar de fotografia en el banner
  Widget _buildCircleArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xCC0F2444),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  // Etiqueta plana de categoria o campus
  Widget _buildHeroBadge(String texto, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
