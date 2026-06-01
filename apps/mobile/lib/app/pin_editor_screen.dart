import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'pin_editor_save_flow.dart';

class PinEditorScreen extends ConsumerStatefulWidget {
  const PinEditorScreen({
    this.pinId,
    this.initialCoordinates,
    super.key,
  });

  final String? pinId;
  final Coordinates? initialCoordinates;

  @override
  ConsumerState<PinEditorScreen> createState() => _PinEditorScreenState();
}

class _PinEditorScreenState extends ConsumerState<PinEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _memoryDateController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final List<PinEditorAttachmentDraft> _attachments =
      <PinEditorAttachmentDraft>[];

  PinDto? _existingPin;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _statusMessage;

  bool get _isEditing => widget.pinId != null;

  @override
  void initState() {
    super.initState();
    final Coordinates? initialCoordinates = widget.initialCoordinates;
    if (initialCoordinates != null) {
      _latController.text = _formatCoordinate(initialCoordinates.lat);
      _lngController.text = _formatCoordinate(initialCoordinates.lng);
    }

    if (_isEditing) {
      _isLoading = true;
      unawaited(_loadPin());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _memoryDateController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Memory' : 'New Memory'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          key: const ValueKey<String>('pin-editor-save'),
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Saving...' : 'Save memory'),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _HeaderCard(isEditing: _isEditing),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey<String>('pin-editor-title-field'),
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Da Lat cafe',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateTitle,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey<String>('pin-editor-note-field'),
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'What happened here?',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey<String>(
                          'pin-editor-memory-date-field',
                        ),
                        controller: _memoryDateController,
                        decoration: const InputDecoration(
                          labelText: 'Memory date',
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        keyboardType: TextInputType.datetime,
                        textInputAction: TextInputAction.next,
                        validator: _validateMemoryDate,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'pin-editor-lat-field',
                              ),
                              controller: _latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[-+0-9.]'),
                                ),
                              ],
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              validator: _validateLatitude,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey<String>(
                                'pin-editor-lng-field',
                              ),
                              controller: _lngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[-+0-9.]'),
                                ),
                              ],
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              validator: _validateLongitude,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _CoordinateConfirmationCard(
                        latitude: _parseCoordinate(_latController.text),
                        longitude: _parseCoordinate(_lngController.text),
                      ),
                      const SizedBox(height: 16),
                      _AttachmentSection(
                        attachments: _attachments,
                        onAdd: _addAttachment,
                      ),
                      if (_statusMessage != null) ...<Widget>[
                        const SizedBox(height: 16),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_statusMessage!),
                          ),
                        ),
                      ],
                      const SizedBox(height: 88),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _loadPin() async {
    try {
      final PinDto pin = await ref.read(pinRepositoryProvider).getPin(
            widget.pinId!,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _existingPin = pin;
        _titleController.text = pin.title;
        _noteController.text = pin.note ?? '';
        _memoryDateController.text = _formatDate(pin.memoryDate);
        _latController.text = _formatCoordinate(pin.lat);
        _lngController.text = _formatCoordinate(pin.lng);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'Could not load this memory.';
      });
    }
  }

  void _addAttachment(PinMediaType mediaType) {
    setState(() {
      _attachments.add(
        PinEditorAttachmentDraft.placeholder(
          mediaType: mediaType,
          id: createAttachmentPlaceholderId(mediaType),
        ),
      );
    });
  }

  Future<void> _save() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final String title = _titleController.text.trim();
    final String note = _noteController.text.trim();
    final double lat = _parseCoordinate(_latController.text)!;
    final double lng = _parseCoordinate(_lngController.text)!;
    final DateTime? memoryDate = _parseMemoryDate(_memoryDateController.text);

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final MapDto map = _existingPin == null
          ? await ref.read(mapRepositoryProvider).getDefaultMap()
          : MapDto(
              id: _existingPin!.mapId,
              type: MemoryMapType.personal,
              ownerId: '',
            );
      final PinEditorSaveFlow saveFlow = PinEditorSaveFlow(
        pinRepository: ref.read(pinRepositoryProvider),
        localPinsDao: ref.read(localPinsDaoProvider),
        uploadQueueDao: ref.read(uploadQueueDaoProvider),
      );
      final PinEditorSaveResult result = await saveFlow.save(
        PinEditorSaveInput(
          mapId: map.id,
          pinId: widget.pinId,
          existingPin: _existingPin,
          title: title,
          note: note.isEmpty ? null : note,
          memoryDate: memoryDate,
          lat: lat,
          lng: lng,
          attachments: List<PinEditorAttachmentDraft>.unmodifiable(
            _attachments,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _existingPin = result.pin;
        _isSaving = false;
        _statusMessage = result.pendingSync
            ? 'Saved offline. Will sync when you are back online.'
            : 'Memory saved.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _statusMessage = 'Could not save memory.';
      });
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(
              isEditing ? Icons.edit_location_alt_outlined : Icons.add_location,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEditing
                    ? 'Update the story, date, place and queued media.'
                    : 'Capture a memory exactly where it happened.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinateConfirmationCard extends StatelessWidget {
  const _CoordinateConfirmationCard({
    required this.latitude,
    required this.longitude,
  });

  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final bool isValid = _isValidLatitude(latitude) &&
        _isValidLongitude(
          longitude,
        );
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      key: const ValueKey<String>('pin-editor-coordinate-confirmation'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor:
                  isValid ? colors.secondaryContainer : colors.errorContainer,
              child: Icon(
                isValid
                    ? Icons.my_location_outlined
                    : Icons.location_disabled_outlined,
                color: isValid
                    ? colors.onSecondaryContainer
                    : colors.onErrorContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Coordinate confirmation',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isValid
                        ? 'Lat ${_formatCoordinate(latitude!)}, Lng ${_formatCoordinate(longitude!)}'
                        : 'Enter valid latitude and longitude before saving.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  const _AttachmentSection({
    required this.attachments,
    required this.onAdd,
  });

  final List<PinEditorAttachmentDraft> attachments;
  final ValueChanged<PinMediaType> onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Attachments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  key: const ValueKey<String>('pin-editor-add-image'),
                  onPressed: () => onAdd(PinMediaType.image),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Choose image'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('pin-editor-add-text'),
                  onPressed: () => onAdd(PinMediaType.text),
                  icon: const Icon(Icons.notes_outlined),
                  label: const Text('Add text'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('pin-editor-add-audio'),
                  onPressed: () => onAdd(PinMediaType.audio),
                  icon: const Icon(Icons.mic_none_outlined),
                  label: const Text('Record audio'),
                ),
              ],
            ),
            if (attachments.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments.map((PinEditorAttachmentDraft draft) {
                  return Chip(
                    avatar: Icon(_iconFor(draft.mediaType), size: 18),
                    label: Text(draft.label),
                  );
                }).toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PinMediaType mediaType) {
    return switch (mediaType) {
      PinMediaType.image => Icons.image_outlined,
      PinMediaType.text => Icons.notes_outlined,
      PinMediaType.audio => Icons.mic_none_outlined,
    };
  }
}

String? _validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Title is required.';
  }

  return null;
}

String? _validateLatitude(String? value) {
  if (!_isValidLatitude(_parseCoordinate(value))) {
    return 'Latitude must be between -90 and 90.';
  }

  return null;
}

String? _validateLongitude(String? value) {
  if (!_isValidLongitude(_parseCoordinate(value))) {
    return 'Longitude must be between -180 and 180.';
  }

  return null;
}

String? _validateMemoryDate(String? value) {
  final String raw = value?.trim() ?? '';
  if (raw.isEmpty || _parseMemoryDate(raw) != null) {
    return null;
  }

  return 'Use date format YYYY-MM-DD.';
}

double? _parseCoordinate(String? value) {
  final double? parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || !parsed.isFinite) {
    return null;
  }

  return parsed;
}

bool _isValidLatitude(double? value) {
  return value != null && value >= -90 && value <= 90;
}

bool _isValidLongitude(double? value) {
  return value != null && value >= -180 && value <= 180;
}

DateTime? _parseMemoryDate(String value) {
  final String raw = value.trim();
  if (raw.isEmpty) {
    return null;
  }

  final RegExpMatch? match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})$',
  ).firstMatch(raw);
  if (match == null) {
    return null;
  }

  final int year = int.parse(match.group(1)!);
  final int month = int.parse(match.group(2)!);
  final int day = int.parse(match.group(3)!);
  final DateTime date = DateTime.utc(year, month, day);

  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }

  return date;
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '';
  }

  final DateTime utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}

String _formatCoordinate(double value) => value.toStringAsFixed(6);

String createAttachmentPlaceholderId(PinMediaType mediaType) {
  return switch (mediaType) {
    PinMediaType.image => 'image_${DateTime.now().microsecondsSinceEpoch}',
    PinMediaType.text => 'text_${DateTime.now().microsecondsSinceEpoch}',
    PinMediaType.audio => 'audio_${DateTime.now().microsecondsSinceEpoch}',
  };
}
