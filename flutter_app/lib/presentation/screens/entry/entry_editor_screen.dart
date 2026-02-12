import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/presentation/providers/entry_provider.dart';

/// New or edit journal entry: writing pad + bottom bar.
/// When [entry] is non-null, shows existing content and updates on save.
/// [initialPrompt] pre-fills the content when starting a new entry (e.g. from Today's prompt).
class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({super.key, this.entry, this.initialPrompt});

  final EntryModel? entry;
  /// Optional prompt text to pre-fill content when creating a new entry.
  final String? initialPrompt;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _focusNode = FocusNode();
  final List<XFile> _pendingImages = [];
  bool _isUploadingMedia = false;
  EntryModel? _entryWithMedia;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;
  String _voiceTranscript = '';
  String _voicePartial = '';

  @override
  void initState() {
    super.initState();
    final initialContent = widget.entry?.content ?? widget.initialPrompt ?? '';
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: initialContent);
    if (widget.entry != null) {
      context.read<EntryProvider>().getEntry(widget.entry!.id).then((e) {
        if (mounted && e != null) setState(() => _entryWithMedia = e);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _askInspiration() async {
    final entryProvider = context.read<EntryProvider>();
    final prompt = await entryProvider.getInspirationPrompt();
    if (!mounted) return;
    if (prompt != null && prompt.isNotEmpty) {
      final before = _contentController.text;
      final insert = before.isEmpty ? prompt : '\n\n$prompt';
      _contentController.text = before + insert;
      _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspiration added to your entry')),
      );
    } else if (entryProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entryProvider.error!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 85,
      limit: 10,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() {
      for (final x in picked) {
        if (_pendingImages.length < 10) _pendingImages.add(x);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${picked.length} photo${picked.length == 1 ? '' : 's'} added. Save or publish to upload.')),
      );
    }
  }

  Future<bool> _ensureSpeechReady() async {
    if (_speechInitialized) return _speech.isAvailable;

    // Request microphone permission first (required on Android 6+ and iOS)
    final status = await Permission.microphone.request();
    if (!mounted) return false;
    if (!status.isGranted) {
      final isPermanentlyDenied = status.isPermanentlyDenied;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermanentlyDenied
                  ? 'Microphone permission denied. Enable it in Settings to use voice notes.'
                  : 'Microphone permission is required for voice notes.',
            ),
            backgroundColor: Colors.orange,
            action: isPermanentlyDenied
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: () => openAppSettings(),
                  )
                : null,
          ),
        );
      }
      return false;
    }

    final available = await _speech.initialize(
      onError: (e) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${e.errorMsg}'), backgroundColor: Colors.red),
          );
        }
      },
      onStatus: (status) {
        if (mounted) setState(() {});
      },
    );
    if (available) _speechInitialized = true;
    return available;
  }

  Future<void> _toggleVoiceNote() async {
    if (_isListening) {
      await _stopVoiceNote();
      return;
    }
    final ready = await _ensureSpeechReady();
    if (!mounted) return;
    if (!ready) {
      final errorDetail = _speech.lastError?.errorMsg ?? '';
      final hint = errorDetail.isEmpty
          ? 'Grant microphone access or try on a real device (emulators often don\'t support speech).'
          : errorDetail;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech recognition unavailable. $hint'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    setState(() {
      _voiceTranscript = '';
      _voicePartial = '';
      _isListening = true;
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          if (result.finalResult) {
            final text = result.recognizedWords.trim();
            if (text.isNotEmpty) {
              _voiceTranscript += (_voiceTranscript.isEmpty ? '' : ' ') + text;
            }
            _voicePartial = '';
          } else {
            _voicePartial = result.recognizedWords;
          }
        });
      },
      partialResults: true,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
    );
    if (mounted) setState(() {});
  }

  /// Sanitize voice or user text so it is safe for JSON/API (no control characters).
  static String _sanitizeContent(String s) {
    if (s.isEmpty) return s;
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      if (rune >= 0x20 || rune == 0x0a || rune == 0x09) buffer.writeCharCode(rune);
    }
    return buffer.toString().trim();
  }

  Future<void> _stopVoiceNote() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
    final raw = (_voiceTranscript + (_voicePartial.trim().isNotEmpty ? ' $_voicePartial'.trim() : '')).trim();
    final text = _sanitizeContent(raw);
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No speech detected. Try again in a quieter place.')),
      );
      return;
    }
    final controller = _contentController;
    final before = controller.text;
    final insert = before.isEmpty ? text : '\n\n$text';
    controller.text = before + insert;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voice note added (${text.length} characters)')),
    );
  }

  void _removePendingImage(int index) {
    setState(() => _pendingImages.removeAt(index));
  }

  void _useTemplates() {
    // TODO: open template picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates – coming soon')),
    );
  }

  Future<void> _uploadPendingMedia(String entryId) async {
    if (_pendingImages.isEmpty) return;
    setState(() => _isUploadingMedia = true);
    final entryProvider = context.read<EntryProvider>();
    for (final xFile in _pendingImages) {
      await entryProvider.uploadEntryMedia(entryId, xFile);
      if (!mounted) break;
      if (entryProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(entryProvider.error!), backgroundColor: Colors.red),
        );
        setState(() => _isUploadingMedia = false);
        return;
      }
    }
    if (mounted) {
      setState(() {
        _pendingImages.clear();
        _isUploadingMedia = false;
      });
      // Refresh entry so the strip shows the newly uploaded photos
      final updated = await entryProvider.getEntry(entryId);
      if (mounted && updated != null) setState(() => _entryWithMedia = updated);
    }
  }

  Future<void> _saveDraft() async {
    final content = _sanitizeContent(_contentController.text);
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something to save')),
      );
      return;
    }
    final entryProvider = context.read<EntryProvider>();
    final saved = await entryProvider.saveEntry(
      entryId: widget.entry?.id,
      content: content,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      isDraft: true,
    );
    if (!mounted) return;
    if (saved != null) {
      await _uploadPendingMedia(saved.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
      if (widget.entry == null) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entryProvider.error ?? 'Failed to save'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _publish() async {
    final content = _sanitizeContent(_contentController.text);
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something to publish')),
      );
      return;
    }
    final entryProvider = context.read<EntryProvider>();
    final saved = await entryProvider.saveEntry(
      entryId: widget.entry?.id,
      content: content,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      isDraft: false,
    );
    if (!mounted) return;
    if (saved != null) {
      await _uploadPendingMedia(saved.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry published')),
      );
      await entryProvider.loadRecentEntries();
      await entryProvider.loadUserStats();
      await entryProvider.loadCalendarDates();
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(entryProvider.error ?? 'Failed to save'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.entry != null ? 'Edit draft' : 'New entry'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (_titleController.text.trim().isNotEmpty || _contentController.text.trim().isNotEmpty) {
              final leave = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Discard draft?'),
                  content: const Text('You have unsaved changes. Discard?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
                  ],
                ),
              );
              if (leave == true && mounted) Navigator.of(context).pop();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(onPressed: _saveDraft, child: const Text('Save draft')),
          const SizedBox(width: 8),
          FilledButton(onPressed: _publish, child: const Text('Publish')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Writing pad – title + content (Notion-style)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 12,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind? Start writing your Journal",
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                  // Photos strip (chat-style): existing media + pending picks (medium-size previews)
                  if ((_entryWithMedia?.media?.isNotEmpty ?? widget.entry?.media?.isNotEmpty ?? false) || _pendingImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 212,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...?(_entryWithMedia?.media ?? widget.entry?.media)?.map((m) => _MediaThumbnail.url(url: m.url)),
                          ...List.generate(_pendingImages.length, (i) => _MediaThumbnail.xFile(xFile: _pendingImages[i], onRemove: () => _removePendingImage(i))),
                        ],
                      ),
                    ),
                  ],
                  if (_isUploadingMedia)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Uploading photos…'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _voicePartial.isNotEmpty ? _voicePartial : 'Listening…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: _voicePartial.isEmpty ? FontStyle.italic : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Bottom bar: scrollable so it never overflows (e.g. when keyboard is up)
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BottomBarChip(
                      icon: _isListening ? Icons.stop_rounded : Icons.mic_none_outlined,
                      label: _isListening ? 'Stop & insert' : 'Voice',
                      onTap: _toggleVoiceNote,
                      highlighted: _isListening,
                    ),
                    const SizedBox(width: 12),
                    _BottomBarChip(
                      icon: Icons.auto_awesome,
                      label: 'Ask inspiration',
                      onTap: _askInspiration,
                    ),
                    const SizedBox(width: 12),
                    _BottomBarChip(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Add photos',
                      onTap: _addPhotos,
                    ),
                    const SizedBox(width: 12),
                    _BottomBarChip(
                      icon: Icons.description_outlined,
                      label: 'Use templates',
                      onTap: _useTemplates,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail.url({required String url})
      : url = url,
        xFile = null,
        onRemove = null;

  const _MediaThumbnail.xFile({required XFile xFile, VoidCallback? onRemove})
      : url = null,
        xFile = xFile,
        onRemove = onRemove;

  final String? url;
  final XFile? xFile;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 300,
              height: 300,
              child: url != null
                  ? Image.network(
                      url!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    )
                  : xFile != null
                      ? FutureBuilder<Uint8List>(
                          future: xFile!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image.memory(snapshot.data!, fit: BoxFit.cover);
                            }
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: Material(
                color: Theme.of(context).colorScheme.error,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBarChip extends StatelessWidget {
  const _BottomBarChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = highlighted
        ? colorScheme.primaryContainer.withOpacity(0.8)
        : colorScheme.surfaceContainerHighest.withOpacity(0.6);
    final fgColor = highlighted ? colorScheme.onPrimaryContainer : colorScheme.primary;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fgColor),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: highlighted ? colorScheme.onPrimaryContainer : null)),
            ],
          ),
        ),
      ),
    );
  }
}
