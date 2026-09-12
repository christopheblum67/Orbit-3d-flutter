import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Écran de sélection de profils pour le mode Duo (2-4 profils)
class DuoProfileSelectionScreen extends ConsumerStatefulWidget {
  const DuoProfileSelectionScreen({super.key});

  @override
  ConsumerState<DuoProfileSelectionScreen> createState() =>
      _DuoProfileSelectionScreenState();
}

class _DuoProfileSelectionScreenState
    extends ConsumerState<DuoProfileSelectionScreen> {
  final Set<String> _selectedIds = {};
  UserProfile? _currentProfile;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final currentProfile = ref.watch(currentProfileProvider);
    _currentProfile = currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Duo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_selectedIds.length >= 2)
            TextButton(
              onPressed: _launchDuo,
              child: const Text(
                'Lancer',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
        ],
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('Aucun profil disponible'));
          }
          final others =
              profiles.where((p) => p.id != currentProfile?.id).toList();
          return _buildBody(context, others);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<UserProfile> others) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        if (_currentProfile != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: _currentProfile!.avatarUrl.isNotEmpty
                      ? NetworkImage(_currentProfile!.avatarUrl)
                      : null,
                  child: _currentProfile!.avatarUrl.isEmpty
                      ? Text(
                          _currentProfile!.firstName.isNotEmpty
                              ? _currentProfile!.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil principal',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _currentProfile!.firstName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '1',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: others.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final profile = others[index];
              final selected = _selectedIds.contains(profile.id);
              const maxAdditional = 3;
              final disabled =
                  !selected && _selectedIds.length >= maxAdditional;

              return ListTile(
                onTap: disabled
                    ? null
                    : () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(profile.id);
                          } else {
                            _selectedIds.add(profile.id);
                          }
                        });
                      },
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: selected
                      ? scheme.primaryContainer
                      : disabled
                          ? scheme.surfaceContainerHighest
                          : scheme.surfaceContainerHighest,
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? NetworkImage(profile.avatarUrl)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? Text(
                          profile.firstName.isNotEmpty
                              ? profile.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : disabled
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  profile.firstName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: disabled ? scheme.onSurfaceVariant : null,
                  ),
                ),
                subtitle: Text(
                  profile.favoriteGenres.take(3).join(", "),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: selected
                    ? Icon(Icons.check_circle, color: scheme.primary, size: 28)
                    : disabled
                        ? Icon(Icons.lock_outline,
                            color: scheme.onSurfaceVariant, size: 24,)
                        : Icon(Icons.circle_outlined,
                            color: scheme.outline, size: 24,),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedIds.length < 2
                    ? 'Sélectionnez au moins 2 profils au total (${_selectedIds.length + 1}/4)'
                    : '${_selectedIds.length + 1} profils sélectionnés — prêt pour le Duo',
                style: TextStyle(
                  color:
                      _selectedIds.length < 2 ? scheme.error : scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedIds.length < 2 ? null : _launchDuo,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Lancer le Duo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _launchDuo() {
    if (_currentProfile == null) return;
    if (_selectedIds.length < 2) return;

    final group = [_currentProfile!.id, ..._selectedIds];
    context.go('/matchmaking/duo', extra: group);
  }
}
