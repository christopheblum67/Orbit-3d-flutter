import 'package:flutter/material.dart';

class SettingsTabBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsTabBar({
    super.key,
    required this.controller,
    required this.labels,
  }) : assert(labels.length == icons.length);

  final TabController controller;
  final List<String> labels;

  static const icons = [
    Icons.person_outline,
    Icons.wifi_tethering,
    Icons.play_circle_outline,
    Icons.security_outlined,
    Icons.equalizer,
    Icons.tune,
  ];

  static const _darkColors = [
    Color(0xFF64B5F6),
    Color(0xFF4DD0E1),
    Color(0xFFFFB74D),
    Color(0xFFEF9A9A),
    Color(0xFFCE93D8),
    Color(0xFFAED581),
  ];

  static const _lightColors = [
    Color(0xFF1565C0),
    Color(0xFF006978),
    Color(0xFFA64E00),
    Color(0xFFB71C1C),
    Color(0xFF7B1FA2),
    Color(0xFF387200),
  ];

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? _darkColors
        : _lightColors;
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: [
        for (var i = 0; i < icons.length; i++)
          Tab(
            icon: Builder(
              builder: (context) => Icon(
                icons[i],
                size: Focus.maybeOf(context)?.hasFocus == true ? 34 : 24,
                color: colors[i],
              ),
            ),
            text: labels[i],
          ),
      ],
    );
  }
}
