import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/drawer_menu_button.dart';
import 'package:orbit_3d_flutter/core/widgets/home_menu_drawer.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final GlobalKey<HomeMenuDrawerState> _drawerKey =
      GlobalKey<HomeMenuDrawerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _menuFocusNode = FocusNode(debugLabel: 'Home menu button');
  @override
  void dispose() {
    _menuFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isM3u = ref.watch(sourceTypeProvider).value == 'm3u';
    final location = GoRouterState.of(context).uri.path;
    final isWide = MediaQuery.sizeOf(context).width > 720;
    final tvMode = ref.watch(tvModeNotifierProvider);

    final entries = _navEntries(isM3u, l);
    final selectedIndex = _indexFor(location, entries);

    return ListenableBuilder(
      listenable: tvMode,
      builder: (context, _) {
        final showTvMenuOverlay = tvMode.enabled && location != '/home';
        final scaffold = Scaffold(
          key: _scaffoldKey,
          drawer: HomeMenuDrawer(key: _drawerKey),
          onDrawerChanged: (isOpened) {
            if (isOpened) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _drawerKey.currentState?.requestInitialFocus();
              });
            }
          },
          appBar: location == '/home'
              ? AppBar(
                  leading: Opacity(
                    opacity: 0,
                    alwaysIncludeSemantics: true,
                    child: DrawerMenuButton(
                      focusNode: _menuFocusNode,
                    ),
                  ),
                  title: Text(_titleForPath(context, location)),
                )
              : null,
          body: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.child),
                    if (showTvMenuOverlay)
                      const Positioned(
                        left: 0,
                        top: 0,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0,
                            alwaysIncludeSemantics: true,
                            child: DrawerMenuButton(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    // Hauteur fixe : sans contrainte, `NavigationBar` calcule sa
                    // hauteur d'apres le contenu et se replie sur deux lignes quand
                    // les libelles sont longs (live_tv_channels, etc.).
                    child: SizedBox(
                      height: 64,
                      child: NavigationBar(
                        labelBehavior:
                            NavigationDestinationLabelBehavior.onlyShowSelected,
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (index) {
                          context.go(entries[index].route);
                        },
                        labelTextStyle:
                            WidgetStateProperty.resolveWith<TextStyle>(
                          (states) => TextStyle(
                            fontSize: 11,
                            fontWeight: states.contains(WidgetState.selected)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: states.contains(WidgetState.selected)
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        destinations: [
                          for (final e in entries)
                            NavigationDestination(
                              icon: Icon(e.icon),
                              tooltip: e.label,
                              // Libellé court : `NavigationDestination` ne propose ni
                              // maxLines ni overflow dans cette version, et n'accepte
                              // qu'UNE ligne — un '\n' dans le texte est donc ignoré et
                              // le titre se retrouve tronqué par la règle ci-dessous.
                              // D'où des libellés réellement courts, pas des titles
                              // qu'on découpe au hasard.
                              label: _shortLabel(e),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.contextMenu): () {
              final state = _scaffoldKey.currentState;
              if (state == null || state.widget.drawer == null) return;
              if (state.isDrawerOpen) {
                state.closeDrawer();
              } else {
                state.openDrawer();
              }
            },
          },
          child: Focus(autofocus: location != '/home', child: scaffold),
        );
      },
    );
  }

  /// Entrées de la barre inférieure (navigation mobile).
  /// La barre mobile inclut l'accès au profil et aux réglages.
  /// En mode M3U (pas de VOD/Séries dédiées) : Contenus à la place.
  static List<_NavEntry> _navEntries(bool isM3u, AppLocalizations l) => [
        _NavEntry(
          icon: Icons.home_rounded,
          label: l.menuHome,
          route: '/home',
        ),
        _NavEntry(
          icon: Icons.live_tv,
          label: l.tvChannels,
          // « Chaînes TV » tronqué donnait « Chaînes . », ponctuation orpheline.
          shortLabel: 'TV',
          route: '/live',
        ),
        if (!isM3u) ...[
          _NavEntry(
            icon: Icons.movie,
            label: l.films,
            route: '/vod',
          ),
          _NavEntry(
            icon: Icons.tv,
            label: l.series,
            route: '/series',
          ),
        ],
        if (isM3u)
          _NavEntry(
            icon: Icons.explore_rounded,
            label: l.menuContent,
            route: '/browse',
          ),
        if (!isM3u)
          const _NavEntry(
            icon: Icons.recommend,
            label: 'Matchmaking',
            shortLabel: 'Match',
            route: '/matchmaking',
          ),
        _NavEntry(
          icon: Icons.person_outline,
          label: l.menuProfile,
          route: '/profiles',
        ),
        _NavEntry(
          icon: Icons.settings,
          label: l.settings,
          route: '/settings',
        ),
      ];

  /// Libellé d'une entrée, tronqué proprement en dernier recours.
  ///
  /// Seule une étiquette explicitement trop longue est coupée, sans laisser
  /// d'espace ni de ponctuation orpheline devant le point.
  static String _shortLabel(_NavEntry entry) {
    final label = entry.shortLabel ?? entry.label.replaceAll('\n', ' ').trim();
    if (label.length <= 9) return label;
    return '${label.substring(0, 8).trimRight()}.';
  }

  /// Index de l'entrée dont la route est un préfixe de la position courante.
  /// Repli sur la première entrée (Accueil) si rien ne correspond.
  static int _indexFor(String location, List<_NavEntry> entries) {
    for (var i = 0; i < entries.length; i++) {
      if (location.startsWith(entries[i].route)) return i;
    }
    return 0;
  }

  String _titleForPath(BuildContext context, String path) {
    final l = AppLocalizations.of(context);
    if (path.startsWith('/live')) return l.tvChannels;
    if (path.startsWith('/series')) return l.series;
    if (path.startsWith('/vod')) return l.films;
    if (path.startsWith('/matchmaking')) return l.forYouMatchmaking;
    if (path.startsWith('/browse')) return l.menuContent;
    if (path.startsWith('/replay')) return l.replay;
    if (path.startsWith('/epg')) return 'EPG';
    if (path.startsWith('/search')) return l.menuSearch;
    if (path.startsWith('/subscriptions')) return l.menuSubscriptions;
    if (path.startsWith('/settings')) return l.settings;
    return AppConstants.appName;
  }
}

/// Entrée de navigation partagée (barre inférieure / rail) : icône, libellé
/// et route associée. L'index sélectionné et la route cible se déduisent de
/// cette table, évitant les switchs fragiles index -> route.
class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.label,
    required this.route,
    this.shortLabel,
  });

  final IconData icon;

  /// Libellé complet, utilisé là où la place existe (rail latéral, tooltips).
  final String label;

  /// Libellé de la barre inférieure, une seule ligne.
  ///
  /// `NavigationDestination` n'accepte ni `maxLines` ni un retour à la ligne :
  /// un titre trop long se retrouve écourté par Flutter, sans contrôle. D'où un
  /// libellé court explicite plutôt qu'une troncature automatique.
  final String? shortLabel;

  final String route;
}
