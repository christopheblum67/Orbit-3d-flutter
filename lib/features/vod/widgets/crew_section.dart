import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:orbit_3d_flutter/models/cast.dart';

/// Section équipe technique - groupée par département
class CrewSection extends StatelessWidget {
  final List<CrewMember> crew;

  const CrewSection({super.key, required this.crew});

  @override
  Widget build(BuildContext context) {
    if (crew.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final crewByDept = <String, List<CrewMember>>{};

    for (final member in crew) {
      crewByDept.putIfAbsent(member.department, () => []).add(member);
    }

    // Ordre des départements pour l'affichage
    final deptOrder = [
      'Directing',
      'Writing',
      'Production',
      'Sound',
      'Camera',
      'Editing',
      'Art',
      'Costume & Make-Up',
      'Visual Effects',
      'Lighting',
      'Editing',
      'Crew',
    ];

    final sortedDepts = crewByDept.keys.toList()
      ..sort((a, b) => deptOrder.indexOf(a).compareTo(deptOrder.indexOf(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Équipe technique',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedDepts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final dept = sortedDepts[index];
            final members = crewByDept[dept]!;
            return _DepartmentSection(
              department: dept,
              members: members,
            );
          },
        ),
      ],
    );
  }
}

class _DepartmentSection extends StatelessWidget {
  final String department;
  final List<CrewMember> members;

  const _DepartmentSection({
    required this.department,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final firstMember = members.first;
    final deptColor = firstMember.departmentColor;
    final deptIcon = firstMember.departmentIcon;

    // Titre du département en français
    final deptLabel = switch (department.toLowerCase()) {
      'directing' => 'Réalisation',
      'writing' => 'Scénario',
      'production' => 'Production',
      'sound' => 'Son',
      'camera' => 'Image',
      'editing' => 'Montage',
      'art' => 'Direction artistique',
      'costume & make-up' => 'Costumes & Maquillage',
      'visual effects' => 'Effets visuels',
      'lighting' => 'Éclairage',
      'editing' => 'Montage',
      _ => department,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(deptIcon, size: 18, color: deptColor),
            const SizedBox(width: 8),
            Text(
              deptLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: deptColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: members.map((member) => _CrewMemberChip(member: member)).toList(),
        ),
      ],
    );
  }
}

class _CrewMemberChip extends StatelessWidget {
  final CrewMember member;

  const _CrewMemberChip({required this.member});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deptColor = member.departmentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: deptColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: deptColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.hasProfile) ...[
            CircleAvatar(
              radius: 12,
              backgroundImage: CachedNetworkImageProvider(member.profileUrl),
              backgroundColor: Colors.grey[800],
            ),
            const SizedBox(width: 6),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                member.job,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          ],
        ),
      );
  }
}