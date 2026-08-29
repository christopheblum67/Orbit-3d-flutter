import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final service = ref.read(historyServiceProvider);
    final hist = await service.getHistory();
    if (mounted) setState(() => _history = hist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final parts = _history[index].split('|');
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(parts[0]),
            subtitle: Text(parts.length > 1 ? parts[1] : ''),
          );
        },
      ),
    );
  }
}
