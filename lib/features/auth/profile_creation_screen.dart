import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';

class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  ConsumerState<ProfileCreationScreen> createState() =>
      _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  bool _submitted = false;
  bool _saving = false;
  final List<String> _favoriteGenres = [];
  String _avatarId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(_dateOfBirth == null
                  ? 'Date de naissance'
                  : 'Date: ${_dateOfBirth!.toLocal()}'.split(' ')[0],),
              subtitle: (_submitted && _dateOfBirth == null)
                  ? Text(
                      'Obligatoire',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : null,
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dateOfBirth = picked);
              },
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Genre'),
              items: ['Homme', 'Femme', 'Autre']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 20),
            const Text('Genres favoris'),
            Wrap(
              spacing: 8,
              children: ['Action', 'Comédie', 'Drame', 'Sci-Fi', 'Horreur']
                  .map((genre) {
                return FilterChip(
                  label: Text(genre),
                  selected: _favoriteGenres.contains(genre),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _favoriteGenres.add(genre);
                      } else {
                        _favoriteGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Avatar'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: profileAvatarOptions.map((option) {
                final selected = _avatarId == option.id;
                return InkWell(
                  onTap: () => setState(
                    () => _avatarId = selected ? '' : option.id,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            option.color,
                            Color.lerp(option.color, Colors.white, 0.25)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(option.icon, size: 26, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate() &&
                          _dateOfBirth != null &&
                          _gender != null) {
                        setState(() => _saving = true);
                        try {
                          final profile = UserProfile(
                            id: const Uuid().v4(),
                            firstName: _firstNameController.text.trim(),
                            dateOfBirth: _dateOfBirth!,
                            gender: _gender!,
                            favoriteGenres: _favoriteGenres,
                            avatarUrl:
                                _avatarId.isEmpty ? '' : 'icone:$_avatarId',
                          );
                          await ref
                              .read(storageServiceProvider)
                              .saveProfile(profile);
                          ref.invalidate(profilesProvider);
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Erreur lors de la sauvegarde'),),
                            );
                          }
                          setState(() => _saving = false);
                        }
                      } else {
                        setState(() => _submitted = true);
                      }
                    },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
