import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import '../../models/user_profile.dart';

class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  ConsumerState<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  bool _submitted = false;
  bool _saving = false;
  final List<String> _favoriteGenres = [];

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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(_dateOfBirth == null ? 'Date de naissance' : 'Date: ${_dateOfBirth!.toLocal()}'.split(' ')[0]),
              subtitle: (_submitted && _dateOfBirth == null)
                  ? const Text('Obligatoire', style: TextStyle(color: Colors.red))
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
              items: ['Homme', 'Femme', 'Autre'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 20),
            const Text('Genres favoris'),
            Wrap(
              spacing: 8,
              children: ['Action', 'Comédie', 'Drame', 'Sci-Fi', 'Horreur'].map((genre) {
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
                          );
                          await ref.read(storageServiceProvider).saveProfile(profile);
                          ref.invalidate(profilesProvider);
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Erreur lors de la sauvegarde')),
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
