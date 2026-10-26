import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

/// Carrousel optimisé pour la navigation TV (D-pad / télécommande).
///
/// Principes TV :
/// - Navigation horizontale (← →) déplace le focus entre les éléments
/// - Vertical (↑ ↓) quitte le carrousel (retour au parent)
/// - OK/Enter/Select/GamepadA active l'élément focalisé
/// - L'élément focalisé a un indicateur visuel clair (bordure, échelle, halo)
/// - Gestion propre du focus : ne "vole" pas le focus aux éléments parents verticaux
class TvCarousel extends StatefulWidget {
  const TvCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onItemActivated,
    this.itemWidth = 290,
    this.itemHeight = 400,
    this.itemSpacing = 16,
    this.viewportFraction = 0.45,
    this.initialPage = 0,
    this.autoFocus = false,
    this.onPageChanged,
    this.enable3DEffect = true,
  });

  final List<Widget> items;
  final Widget Function(BuildContext, int, bool) itemBuilder;
  final void Function(int index) onItemActivated;
  final double itemWidth;
  final double itemHeight;
  final double itemSpacing;
  final double viewportFraction;
  final int initialPage;
  final bool autoFocus;
  final void Function(int)? onPageChanged;
  final bool enable3DEffect;

  @override
  State<TvCarousel> createState() => _TvCarouselState();
}

class _TvCarouselState extends State<TvCarousel> {
  late final PageController _pageController;
  late final FocusScopeNode _focusScopeNode;
  int _currentPage = 0;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: widget.initialPage,
    );
    _focusScopeNode = FocusScopeNode();
    _currentPage = widget.initialPage;
    _focusedIndex = widget.initialPage;

    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _focusScopeNode.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage && page >= 0 && page < widget.items.length) {
      setState(() {
        _currentPage = page;
        _focusedIndex = page;
      });
      widget.onPageChanged?.call(page);
    }
  }

  /// Gère la navigation clavier/D-pad pour le carrousel.
  KeyEventResult _handleCarouselKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final logicalKey = event.logicalKey;

    // Navigation horizontale : déplace le focus
    if (logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }

    // Activation : Enter/Select/OK/GamepadA
    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.select ||
        logicalKey == LogicalKeyboardKey.space ||
        logicalKey == LogicalKeyboardKey.gameButtonA) {
      _activateCurrentItem();
      return KeyEventResult.handled;
    }

    // Navigation verticale : quitte le carrousel (retour au parent)
    if (logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored; // Laisse le focus remonter au parent
    }

    return KeyEventResult.ignored;
  }

  void _moveFocus(int direction) {
    final newIndex = (_focusedIndex + direction).clamp(0, widget.items.length - 1);
    if (newIndex != _focusedIndex) {
      setState(() {
        _focusedIndex = newIndex;
      });
      _pageController.animateToPage(
        _focusedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _activateCurrentItem() {
    if (_focusedIndex >= 0 && _focusedIndex < widget.items.length) {
      widget.onItemActivated(_focusedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusScope(
      node: _focusScopeNode,
      autofocus: widget.autoFocus,
      onKeyEvent: _handleCarouselKeyEvent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            final page = _pageController.page?.round() ?? 0;
            if (page != _focusedIndex) {
              setState(() => _focusedIndex = page);
            }
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length,
          physics: const PageScrollPhysics(),
          itemBuilder: (context, index) {
            final rel = index - _currentPage;
            final isFocused = index == _focusedIndex;

            Widget itemWidget = widget.itemBuilder(context, index, isFocused);

            // Effet 3D optionnel sur l'élément centré
            if (widget.enable3DEffect) {
              final rel = index - (_pageController.page ?? _currentPage.toDouble());
              final scale = (1 - (rel.abs() * 0.22)).clamp(0.75, 1.0);
              final opacity = (1 - (rel.abs() * 0.35)).clamp(0.4, 1.0);
              final rotationY = (rel * 0.45).clamp(-0.7, 0.7);

              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateY(rotationY)
                ..scale(scale, scale);

              itemWidget = Transform(
                transform: transform,
                alignment: Alignment.center,
                child: Opacity(
                  opacity: opacity,
                  child: itemWidget,
                ),
              );
            }

            // Wrap avec TvFocus pour la navigation TV
            return TvFocus(
              focusNode: FocusNode(),
              autofocus: index == 0 && widget.autoFocus,
              onActivate: () {
                setState(() => _focusedIndex = index);
                widget.onItemActivated(index);
              },
              onKeyEvent: (node, event) {
                // Gestion locale des touches pour cet élément
                if (event is! KeyDownEvent) return KeyEventResult.ignored;

                final logicalKey = event.logicalKey;

                // Navigation interne au carrousel
                if (logicalKey == LogicalKeyboardKey.arrowRight) {
                  _moveFocus(1);
                  return KeyEventResult.handled;
                }
                if (logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _moveFocus(-1);
                  return KeyEventResult.handled;
                }
                if (logicalKey == LogicalKeyboardKey.enter ||
                    logicalKey == LogicalKeyboardKey.select ||
                    logicalKey == LogicalKeyboardKey.space ||
                    logicalKey == LogicalKeyboardKey.gameButtonA) {
                  widget.onItemActivated(index);
                  return KeyEventResult.handled;
                }

                // Vertical = sort du carrousel
                if (logicalKey == LogicalKeyboardKey.arrowUp ||
                    logicalKey == LogicalKeyboardKey.arrowDown) {
                  return KeyEventResult.ignored;
                }

                return KeyEventResult.ignored;
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.itemSpacing / 2,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: widget.itemWidth,
                  height: widget.itemHeight,
                  child: itemWidget,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}