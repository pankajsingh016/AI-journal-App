import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';

/// Three-dot menu with Delete for entry/draft cards. Keeps trailing height bounded for list layout.
class EntryCardActions extends StatelessWidget {
  const EntryCardActions({
    super.key,
    required this.entry,
    required this.isDraft,
    this.onDeleted,
  });

  final EntryModel entry;
  final bool isDraft;
  final VoidCallback? onDeleted;

  Future<void> _onDeletePressed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDraft ? 'Delete draft?' : 'Delete entry?'),
        content: Text(
          isDraft
              ? 'This draft will be permanently removed.'
              : 'This journal entry will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<EntryProvider>();
    final ok = await provider.deleteEntry(entry.id);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft ? 'Draft deleted' : 'Entry deleted'),
        ),
      );
      onDeleted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to delete'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      iconSize: 22,
      onPressed: () async {
        final result = await showMenu<String>(
          context: context,
          position: _getMenuPosition(context),
          items: [
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        if (result == 'delete' && context.mounted) {
          await _onDeletePressed(context);
        }
      },
    );
  }

  RelativeRect _getMenuPosition(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      return RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        offset.dy + box.size.height + 8,
      );
    }
    return const RelativeRect.fromLTRB(0, 0, 0, 0);
  }
}
