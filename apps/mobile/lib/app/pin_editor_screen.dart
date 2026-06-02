import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'pin_editor_save_flow.dart';

typedef DateTimeFactory = DateTime Function();

abstract interface class PinEditorAttachmentActions {
  Future<PinEditorAttachmentDraft?> pickImage(BuildContext context);
  Future<PinEditorAttachmentDraft?> pickText(BuildContext context);
  Future<PinEditorAttachmentDraft?> pickAudio(BuildContext context);
}

class PinEditorScreen extends ConsumerStatefulWidget {
  const PinEditorScreen({
    this.pinId,
    this.initialCoordinates,
    this.attachmentActions = const DefaultPinEditorAttachmentActions(),
    this.now = _defaultNow,
    super.key,
  });

  final String? pinId;
  final Coordinates? initialCoordinates;
  final PinEditorAttachmentActions attachmentActions;
  final DateTimeFactory now;

  @override
  ConsumerState<PinEditorScreen> createState() => _PinEditorScreenState();
}

class _PinEditorScreenState extends ConsumerState<PinEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<PinEditorAttachmentDraft> _attachments =
      <PinEditorAttachmentDraft>[];

  PinDto? _existingPin;
  Coordinates? _coordinates;
  late DateTime _memoryDate;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _statusMessage;
  String? _locationError;

  bool get _isEditing => widget.pinId != null;

  @override
  void initState() {
    super.initState();
    _coordinates = widget.initialCoordinates;
    _memoryDate = _dateOnly(widget.now().toUtc());

    if (_isEditing) {
      _isLoading = true;
      unawaited(_loadPin());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa kỷ niệm' : 'Kỷ niệm mới'),
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
          label: Text(_isSaving ? 'Đang lưu...' : 'Lưu kỷ niệm'),
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
                          labelText: 'Tên kỷ niệm',
                          hintText: 'Ví dụ: Cà phê Đà Lạt',
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
                          labelText: 'Câu chuyện',
                          hintText: 'Bạn muốn nhớ điều gì về khoảnh khắc này?',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        key: const ValueKey<String>('pin-editor-date-field'),
                        onTap: _pickMemoryDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày kỷ niệm',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_formatDate(_memoryDate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LocationCard(
                        coordinates: _coordinates,
                        error: _locationError,
                        onChangeLocation: _changeLocation,
                      ),
                      const SizedBox(height: 16),
                      _AttachmentSection(
                        attachments: _attachments,
                        onAdd: _addAttachment,
                        onRemove: _removeAttachment,
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
        _memoryDate = _dateOnly(pin.memoryDate ?? widget.now().toUtc());
        _coordinates = widget.initialCoordinates ??
            Coordinates(
              lat: pin.lat,
              lng: pin.lng,
            );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'Không thể tải kỷ niệm này.';
      });
    }
  }

  Future<void> _pickMemoryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _memoryDate,
      firstDate: DateTime.utc(1900),
      lastDate: DateTime.utc(2100),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _memoryDate = _dateOnly(picked);
    });
  }

  Future<void> _addAttachment(PinMediaType mediaType) async {
    final Future<PinEditorAttachmentDraft?> draftFuture = switch (mediaType) {
      PinMediaType.image => widget.attachmentActions.pickImage(context),
      PinMediaType.text => widget.attachmentActions.pickText(context),
      PinMediaType.audio => widget.attachmentActions.pickAudio(context),
    };
    final PinEditorAttachmentDraft? draft = await draftFuture;

    if (draft == null || !mounted) {
      return;
    }

    setState(() {
      _attachments.add(draft);
    });
  }

  void _removeAttachment(String id) {
    setState(() {
      _attachments
          .removeWhere((PinEditorAttachmentDraft item) => item.id == id);
    });
  }

  void _changeLocation() {
    final String query = _isEditing && widget.pinId != null
        ? '?pick=1&editPinId=${Uri.encodeComponent(widget.pinId!)}'
        : '?pick=1';
    context.go('/$query');
  }

  Future<void> _save() async {
    final FormState? form = _formKey.currentState;
    final Coordinates? coordinates = _coordinates;
    final bool hasValidLocation = _isValidLatitude(coordinates?.lat) &&
        _isValidLongitude(coordinates?.lng);

    setState(() {
      _locationError = hasValidLocation
          ? null
          : 'Hãy chọn vị trí trên bản đồ trước khi lưu.';
    });

    if (form == null || !form.validate() || !hasValidLocation) {
      return;
    }

    final String title = _titleController.text.trim();
    final String note = _noteController.text.trim();

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
        mediaRepository: ref.read(mediaRepositoryProvider),
        objectUploadClient: ref.read(objectUploadClientProvider),
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
          memoryDate: _memoryDate,
          lat: coordinates!.lat,
          lng: coordinates.lng,
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
        _statusMessage = switch (result.status) {
          PinEditorSaveStatus.synced => 'Kỷ niệm đã lưu.',
          PinEditorSaveStatus.pendingPin =>
            'Đã lưu offline. Sẽ đồng bộ khi có mạng.',
          PinEditorSaveStatus.mediaPending =>
            'Kỷ niệm đã lưu, tệp sẽ tải lên lại sau.',
        };
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _statusMessage = 'Không thể lưu kỷ niệm.';
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
                    ? 'Cập nhật câu chuyện, ngày, vị trí và tệp đính kèm.'
                    : 'Lưu lại khoảnh khắc tại đúng nơi nó diễn ra.',
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.coordinates,
    required this.error,
    required this.onChangeLocation,
  });

  final Coordinates? coordinates;
  final String? error;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = _isValidLatitude(coordinates?.lat) &&
        _isValidLongitude(coordinates?.lng);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      key: const ValueKey<String>('pin-editor-location-card'),
      margin: EdgeInsets.zero,
      color:
          error == null ? null : colors.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: hasLocation
                  ? colors.secondaryContainer
                  : colors.errorContainer,
              child: Icon(
                hasLocation
                    ? Icons.my_location_outlined
                    : Icons.location_disabled_outlined,
                color: hasLocation
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
                    hasLocation ? 'Vị trí đã chọn' : 'Chưa chọn vị trí',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasLocation
                        ? 'Đã lưu điểm trên bản đồ cho kỷ niệm này.'
                        : 'Hãy chọn một điểm trên bản đồ trước khi lưu.',
                  ),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      error!,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: onChangeLocation,
              child: Text(hasLocation ? 'Đổi vị trí' : 'Chọn vị trí'),
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
    required this.onRemove,
  });

  final List<PinEditorAttachmentDraft> attachments;
  final ValueChanged<PinMediaType> onAdd;
  final ValueChanged<String> onRemove;

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
              'Tệp đính kèm',
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
                  label: const Text('Chọn ảnh'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('pin-editor-add-text'),
                  onPressed: () => onAdd(PinMediaType.text),
                  icon: const Icon(Icons.notes_outlined),
                  label: const Text('Tệp văn bản'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('pin-editor-add-audio'),
                  onPressed: () => onAdd(PinMediaType.audio),
                  icon: const Icon(Icons.graphic_eq_outlined),
                  label: const Text('Âm thanh'),
                ),
              ],
            ),
            if (attachments.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ...attachments.map((PinEditorAttachmentDraft draft) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AttachmentTile(
                    draft: draft,
                    onRemove: onRemove,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.draft,
    required this.onRemove,
  });

  final PinEditorAttachmentDraft draft;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        minLeadingWidth: 40,
        leading: _AttachmentLeading(draft: draft),
        title: Text(draft.label),
        subtitle: Text(_formatBytes(draft.sizeBytes)),
        trailing: IconButton(
          key: ValueKey<String>('pin-editor-remove-${draft.id}'),
          onPressed: () => onRemove(draft.id),
          icon: const Icon(Icons.close),
          tooltip: 'Xóa tệp',
        ),
      ),
    );
  }
}

class _AttachmentLeading extends StatelessWidget {
  const _AttachmentLeading({required this.draft});

  final PinEditorAttachmentDraft draft;

  @override
  Widget build(BuildContext context) {
    if (draft.mediaType == PinMediaType.image &&
        File(draft.localPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(draft.localPath),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }

    return CircleAvatar(
      child: Icon(
        switch (draft.mediaType) {
          PinMediaType.image => Icons.image_outlined,
          PinMediaType.text => Icons.notes_outlined,
          PinMediaType.audio => Icons.mic_none_outlined,
        },
      ),
    );
  }
}

class DefaultPinEditorAttachmentActions implements PinEditorAttachmentActions {
  const DefaultPinEditorAttachmentActions();

  @override
  Future<PinEditorAttachmentDraft?> pickImage(BuildContext context) async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (file == null) {
      return null;
    }

    final int sizeBytes = await file.length();
    final String fileName = _fileNameFromPath(file.path, fallback: 'photo.jpg');

    return PinEditorAttachmentDraft(
      id: createAttachmentId(PinMediaType.image),
      mediaType: PinMediaType.image,
      label: fileName,
      localPath: file.path,
      mimeType: file.mimeType ?? _mimeTypeFor(fileName, PinMediaType.image),
      sizeBytes: sizeBytes,
      fileName: fileName,
    );
  }

  @override
  Future<PinEditorAttachmentDraft?> pickText(BuildContext context) async {
    final String? text = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => const _TextAttachmentDialog(),
    );
    final String normalized = text?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final Directory directory = await getTemporaryDirectory();
    final String id = createAttachmentId(PinMediaType.text);
    final String fileName = '$id.txt';
    final File file =
        File('${directory.path}${Platform.pathSeparator}$fileName');
    final List<int> bytes = utf8.encode(normalized);
    await file.writeAsBytes(bytes);

    return PinEditorAttachmentDraft(
      id: id,
      mediaType: PinMediaType.text,
      label: 'Văn bản đính kèm',
      localPath: file.path,
      mimeType: 'text/plain',
      sizeBytes: bytes.length,
      fileName: fileName,
    );
  }

  @override
  Future<PinEditorAttachmentDraft?> pickAudio(BuildContext context) async {
    final _AudioAttachmentChoice? choice =
        await showModalBottomSheet<_AudioAttachmentChoice>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) =>
          const _AudioAttachmentChoiceSheet(),
    );
    if (!context.mounted) {
      return null;
    }

    return switch (choice) {
      _AudioAttachmentChoice.record =>
        showModalBottomSheet<PinEditorAttachmentDraft>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext sheetContext) => const _AudioRecorderSheet(),
        ),
      _AudioAttachmentChoice.pickFile => _pickAudioFile(),
      null => null,
    };
  }

  Future<PinEditorAttachmentDraft?> _pickAudioFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    final PlatformFile? picked =
        result == null || result.files.isEmpty ? null : result.files.single;
    final String? path = picked?.path;
    if (picked == null || path == null || path.trim().isEmpty) {
      return null;
    }

    final File file = File(path);
    final int sizeBytes = picked.size > 0
        ? picked.size
        : await file.exists()
            ? await file.length()
            : 1;
    final String fileName = picked.name.trim().isEmpty
        ? _fileNameFromPath(path, fallback: 'audio.m4a')
        : picked.name;

    return PinEditorAttachmentDraft(
      id: createAttachmentId(PinMediaType.audio),
      mediaType: PinMediaType.audio,
      label: fileName,
      localPath: path,
      mimeType: _mimeTypeFor(fileName, PinMediaType.audio),
      sizeBytes: sizeBytes,
      fileName: fileName,
    );
  }
}

class _TextAttachmentDialog extends StatefulWidget {
  const _TextAttachmentDialog();

  @override
  State<_TextAttachmentDialog> createState() => _TextAttachmentDialogState();
}

class _TextAttachmentDialogState extends State<_TextAttachmentDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo tệp văn bản'),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 6,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Nhập nội dung cho tệp văn bản...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}

enum _AudioAttachmentChoice {
  record,
  pickFile,
}

class _AudioAttachmentChoiceSheet extends StatelessWidget {
  const _AudioAttachmentChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Âm thanh',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm âm thanh bằng cách ghi mới hoặc chọn file đã có trên máy.',
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.mic_none_outlined)),
              title: const Text('Ghi âm mới'),
              subtitle: const Text('Thu một đoạn âm thanh ngay bây giờ.'),
              onTap: () =>
                  Navigator.of(context).pop(_AudioAttachmentChoice.record),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const CircleAvatar(child: Icon(Icons.audio_file_outlined)),
              title: const Text('Chọn file âm thanh'),
              subtitle: const Text('Dùng file m4a, mp3, wav hoặc audio khác.'),
              onTap: () =>
                  Navigator.of(context).pop(_AudioAttachmentChoice.pickFile),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Video cần backend hỗ trợ mediaType video nên chưa bật ở đây.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioRecorderSheet extends StatefulWidget {
  const _AudioRecorderSheet();

  @override
  State<_AudioRecorderSheet> createState() => _AudioRecorderSheetState();
}

class _AudioRecorderSheetState extends State<_AudioRecorderSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _path;
  String? _error;

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Ghi âm mới',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? 'Đang ghi âm. Bấm dừng để thêm vào kỷ niệm.'
                  : 'Ghi một đoạn âm thanh ngắn cho kỷ niệm này.',
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isRecording ? _stop : _start,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Dừng' : 'Bắt đầu'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed:
                      _isRecording ? null : () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    final bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() {
        _error = 'Ứng dụng cần quyền micro để ghi âm.';
      });
      return;
    }

    final Directory directory = await getTemporaryDirectory();
    final String id = createAttachmentId(PinMediaType.audio);
    final String path = '${directory.path}${Platform.pathSeparator}$id.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _path = path;
      _error = null;
      _isRecording = true;
    });
  }

  Future<void> _stop() async {
    final String? stoppedPath = await _recorder.stop();
    final String? path = stoppedPath ?? _path;
    if (path == null) {
      setState(() {
        _isRecording = false;
        _error = 'Không tìm thấy tệp ghi âm.';
      });
      return;
    }

    final File file = File(path);
    final int sizeBytes = await file.exists() ? await file.length() : 1;
    final String fileName = _fileNameFromPath(path, fallback: 'voice.m4a');

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      PinEditorAttachmentDraft(
        id: fileName.replaceAll('.m4a', ''),
        mediaType: PinMediaType.audio,
        label: fileName,
        localPath: path,
        mimeType: 'audio/mp4',
        sizeBytes: sizeBytes,
        fileName: fileName,
      ),
    );
  }
}

String? _validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Tên kỷ niệm là bắt buộc.';
  }

  return null;
}

bool _isValidLatitude(double? value) {
  return value != null && value >= -90 && value <= 90;
}

bool _isValidLongitude(double? value) {
  return value != null && value >= -180 && value <= 180;
}

DateTime _dateOnly(DateTime value) {
  return DateTime.utc(value.year, value.month, value.day);
}

String _formatDate(DateTime value) {
  final DateTime utc = value.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}';
}

String _formatBytes(int value) {
  if (value < 1024) {
    return '$value B';
  }
  if (value < 1024 * 1024) {
    return '${(value / 1024).toStringAsFixed(1)} KB';
  }
  return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String createAttachmentId(PinMediaType mediaType) {
  return switch (mediaType) {
    PinMediaType.image => 'image_${DateTime.now().microsecondsSinceEpoch}',
    PinMediaType.text => 'text_${DateTime.now().microsecondsSinceEpoch}',
    PinMediaType.audio => 'audio_${DateTime.now().microsecondsSinceEpoch}',
  };
}

String _fileNameFromPath(String path, {required String fallback}) {
  final String normalized = path.replaceAll('\\', '/');
  final String fileName = normalized.split('/').last.trim();
  return fileName.isEmpty ? fallback : fileName;
}

String _mimeTypeFor(String fileName, PinMediaType mediaType) {
  final String lower = fileName.toLowerCase();
  if (mediaType == PinMediaType.image) {
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
  if (mediaType == PinMediaType.audio) {
    if (lower.endsWith('.mp3')) {
      return 'audio/mpeg';
    }
    if (lower.endsWith('.wav')) {
      return 'audio/wav';
    }
    if (lower.endsWith('.aac')) {
      return 'audio/aac';
    }
    if (lower.endsWith('.ogg')) {
      return 'audio/ogg';
    }
    return 'audio/mp4';
  }
  return 'text/plain';
}

DateTime _defaultNow() => DateTime.now().toUtc();
