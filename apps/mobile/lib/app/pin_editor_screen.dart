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
              : Icon(
                  _statusMessage == 'Đã lưu offline. Sẽ đồng bộ khi có mạng.'
                      ? Icons.cloud_download
                      : Icons.push_pin,
                ),
          label: Text(
            _isSaving
                ? 'Đang lưu...'
                : (_statusMessage == 'Đã lưu offline. Sẽ đồng bộ khi có mạng.'
                    ? 'Lưu offline'
                    : 'Lưu kỷ niệm'),
          ),
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
                      _HeaderCard(coordinates: _coordinates),
                      const SizedBox(height: 24),
                      const Text(
                        'Tiêu đề',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey<String>('pin-editor-title-field'),
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tiêu đề kỷ niệm',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateTitle,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ghi chú',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey<String>('pin-editor-note-field'),
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Viết vài dòng ghi chú...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ngày kỷ niệm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const ValueKey<String>('pin-editor-date-field'),
                        onTap: _pickMemoryDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                            ),
                          ),
                          child: Text(_formatDate(_memoryDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Vĩ độ / Kinh độ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _LocationCard(
                        coordinates: _coordinates,
                        error: _locationError,
                        onChangeLocation: _changeLocation,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nội dung đính kèm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 48),
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
  const _HeaderCard({required this.coordinates});

  final Coordinates? coordinates;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Map background mock
              const Center(
                child: Icon(Icons.map, size: 64, color: Colors.black12),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 36,
                      color: Color(0xFFB5935A),
                    ),
                    if (coordinates != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Vị trí đã chọn',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                'Chỉ mình tôi · Hiển thị trên bản đồ cá nhân',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
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
    final bool hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasError ? const Color(0xFFD67D6F) : Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: hasError ? const Color(0xFFFDECEA) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: hasError
                          ? const Color(0xFFD67D6F)
                          : const Color(0xFF3B5B43),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        coordinates != null
                            ? 'Vị trí đã chọn trên bản đồ'
                            : 'Chưa chọn vị trí',
                        style: TextStyle(
                          fontSize: 14,
                          color: hasError
                              ? const Color(0xFFD67D6F)
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Color(0xFFD67D6F),
                ),
                const SizedBox(width: 4),
                Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFFD67D6F),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onChangeLocation,
                    child: const Text('Chọn lại trên bản đồ'),
                  ),
                ),
              ],
            ),
          ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attachments.isEmpty)
          InkWell(
            key: const ValueKey<String>('pin-editor-add-content'),
            onTap: () => _showAddContentSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1EB),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.black12, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm nội dung',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Ảnh, văn bản hoặc ghi âm',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (attachments.isNotEmpty) ...[
          ...attachments.map((PinEditorAttachmentDraft draft) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AttachmentTile(
                draft: draft,
                onRemove: onRemove,
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey<String>('pin-editor-add-content'),
            onPressed: () => _showAddContentSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Thêm nội dung khác'),
          ),
        ],
      ],
    );
  }

  void _showAddContentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    'Thêm nội dung',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AddContentAction(
                key: const ValueKey<String>('pin-editor-add-image'),
                icon: Icons.image,
                title: 'Ảnh',
                subtitle: 'Thêm ảnh từ thư viện hoặc chụp mới',
                onTap: () {
                  Navigator.pop(context);
                  onAdd(PinMediaType.image);
                },
              ),
              _AddContentAction(
                key: const ValueKey<String>('pin-editor-add-text'),
                icon: Icons.notes,
                title: 'Văn bản',
                subtitle: 'Ghi lại suy nghĩ hoặc câu chuyện',
                onTap: () {
                  Navigator.pop(context);
                  onAdd(PinMediaType.text);
                },
              ),
              _AddContentAction(
                key: const ValueKey<String>('pin-editor-add-audio'),
                icon: Icons.mic,
                title: 'Ghi âm',
                subtitle: 'Ghi lại âm thanh hoặc giọng nói',
                onTap: () {
                  Navigator.pop(context);
                  onAdd(PinMediaType.audio);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddContentAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddContentAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF3B5B43)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
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

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.draft,
    required this.onRemove,
  });

  final PinEditorAttachmentDraft draft;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _AttachmentLeading(draft: draft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  draft.mediaType == PinMediaType.audio
                      ? '00:00 - Chờ đồng bộ'
                      : 'Đã thêm',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey<String>('pin-editor-remove-${draft.id}'),
            onPressed: () => onRemove(draft.id),
            icon: const Icon(Icons.close, color: Colors.black54),
            tooltip: 'Xóa tệp',
          ),
        ],
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
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        switch (draft.mediaType) {
          PinMediaType.image => Icons.image_outlined,
          PinMediaType.text => Icons.notes_outlined,
          PinMediaType.audio => Icons.play_arrow,
        },
        color: const Color(0xFF3B5B43),
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
