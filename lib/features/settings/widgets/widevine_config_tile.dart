import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/drm/drm_provider.dart';
import 'package:orbit_3d_flutter/drm/widevine_config_store.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

class WidevineConfigTile extends ConsumerWidget {
  const WidevineConfigTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final subscription = ref.watch(activeSubscriptionProvider);
    final config = subscription == null || subscription.id.trim().isEmpty
        ? null
        : ref.watch(widevineConfigProvider(subscription.id));
    return SettingsNavTile(
      icon: Icons.key_outlined,
      title: 'Widevine DRM',
      subtitle: subscription == null || subscription.id.trim().isEmpty
          ? l.widevineSelectSubscription
          : config!.when(
              loading: () => l.widevineLoading,
              error: (error, stack) => l.widevineLoadFailed,
              data: (value) => value == null
                  ? l.widevineNoLicense(subscription.name)
                  : '${subscription.name} : ${value.licenseUrl}',
            ),
      onTap: () {
        if (subscription == null || subscription.id.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.widevineSelectFirst),
          ));
          return;
        }
        final current = config;
        if (current == null || !current.hasValue || current.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.widevineUnavailable),
          ));
          return;
        }
        showDialog<void>(
          context: context,
          builder: (_) => _WidevineConfigDialog(
            subscriptionId: subscription.id,
            subscriptionName: subscription.name,
            initialConfig: current.value,
          ),
        );
      },
    );
  }
}

class _WidevineConfigDialog extends ConsumerStatefulWidget {
  const _WidevineConfigDialog({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.initialConfig,
  });

  final String subscriptionId;
  final String subscriptionName;
  final WidevineConfig? initialConfig;

  @override
  ConsumerState<_WidevineConfigDialog> createState() =>
      _WidevineConfigDialogState();
}

class _WidevineConfigDialogState extends ConsumerState<_WidevineConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseUrl;
  late final TextEditingController _headers;
  late final TextEditingController _certificate;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _licenseUrl = TextEditingController(text: config?.licenseUrl ?? '');
    _headers = TextEditingController(
      text: config == null
          ? ''
          : const JsonEncoder.withIndent('  ').convert(config.headers),
    );
    _certificate = TextEditingController(text: config?.certificateBase64 ?? '');
  }

  @override
  void dispose() {
    _licenseUrl.dispose();
    _headers.dispose();
    _certificate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final headers = _decodeHeaders(_headers.text);
    if (headers == null) return;

    try {
      await WidevineConfigStore.instance.saveForSubscription(
        widget.subscriptionId,
        WidevineConfig(
          licenseUrl: _licenseUrl.text.trim(),
          headers: headers,
          certificateBase64: _certificate.text.trim().isEmpty
              ? null
              : _certificate.text.trim(),
        ),
      );
      if (mounted) {
        ref.invalidate(widevineConfigProvider(widget.subscriptionId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .widevineSaveFailed(error.toString()))),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    try {
      await WidevineConfigStore.instance.saveForSubscription(
        widget.subscriptionId,
        null,
      );
      if (mounted) {
        ref.invalidate(widevineConfigProvider(widget.subscriptionId));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .widevineClearFailed(error.toString()))),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasConfig = widget.initialConfig != null;
    final legacy = ref.watch(legacyWidevineConfigProvider).value;
    return AlertDialog(
      title: Text('Widevine — ${widget.subscriptionName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _licenseUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l.widevineLicenseUrl,
                ),
                validator: (value) {
                  final uri = Uri.tryParse(value?.trim() ?? '');
                  if (uri == null ||
                      !uri.hasAuthority ||
                      uri.host.isEmpty ||
                      uri.scheme != 'https') {
                    return l.widevineInvalidUrl;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _headers,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l.widevineHeaders,
                  hintText: '{"Authorization": "Bearer …"}',
                ),
                validator: (value) => _decodeHeaders(value ?? '') == null
                    ? l.widevineInvalidHeaders
                    : null,
              ),
              TextFormField(
                controller: _certificate,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.widevineCertificate,
                ),
              ),
              const SizedBox(height: 12),
              Text(l.widevineStorageHelp),
              if (!hasConfig && legacy != null)
                TextButton(
                  onPressed: () {
                    _licenseUrl.text = legacy.licenseUrl;
                    _headers.text = const JsonEncoder.withIndent('  ')
                        .convert(legacy.headers);
                    _certificate.text = legacy.certificateBase64 ?? '';
                  },
                  child: Text(l.widevineCopyLegacy),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (hasConfig)
          TextButton(
            onPressed: _clear,
            child: Text(l.widevineClear),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l.profileSaveAction),
        ),
      ],
    );
  }

  Map<String, String>? _decodeHeaders(String text) {
    if (text.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      final headers = <String, String>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! String) return null;
        headers[entry.key as String] = entry.value as String;
      }
      return headers;
    } on FormatException {
      return null;
    }
  }
}
