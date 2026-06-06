import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/repository_providers.dart';

final duoControllerProvider =
    StateNotifierProvider.autoDispose<DuoController, DuoMapState>((ref) {
  return DuoController(mapRepository: ref.watch(mapRepositoryProvider));
});

class DuoMapState {
  const DuoMapState({
    this.maps = const <MapDto>[],
    this.duoMap,
    this.joinInput = '',
    this.isLoading = false,
    this.isMutating = false,
    this.showJoinForm = false,
    this.errorCode,
    this.notice,
  });

  final List<MapDto> maps;
  final MapDto? duoMap;
  final String joinInput;
  final bool isLoading;
  final bool isMutating;
  final bool showJoinForm;
  final String? errorCode;
  final String? notice;

  bool get hasDuoMap => duoMap != null;
  bool get isFull => (duoMap?.members.length ?? 0) >= 2;
  bool get hasPendingInvitation => duoMap?.pendingInvitation != null;

  DuoMapState copyWith({
    List<MapDto>? maps,
    Object? duoMap = _unset,
    String? joinInput,
    bool? isLoading,
    bool? isMutating,
    bool? showJoinForm,
    Object? errorCode = _unset,
    Object? notice = _unset,
  }) {
    return DuoMapState(
      maps: maps ?? this.maps,
      duoMap: identical(duoMap, _unset) ? this.duoMap : duoMap as MapDto?,
      joinInput: joinInput ?? this.joinInput,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      showJoinForm: showJoinForm ?? this.showJoinForm,
      errorCode:
          identical(errorCode, _unset) ? this.errorCode : errorCode as String?,
      notice: identical(notice, _unset) ? this.notice : notice as String?,
    );
  }
}

class DuoController extends StateNotifier<DuoMapState> {
  DuoController({required MapRepository mapRepository})
      : _mapRepository = mapRepository,
        super(const DuoMapState());

  final MapRepository _mapRepository;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      errorCode: null,
      notice: null,
    );

    try {
      final List<MapDto> maps = await _mapRepository.listMaps();

      state = state.copyWith(
        maps: maps,
        duoMap: _firstDuoMap(maps),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorCode: 'duo_load_failed',
      );
    }
  }

  void openJoinForm([String? code]) {
    state = state.copyWith(
      joinInput: code == null ? state.joinInput : normalizeInvitationCode(code),
      showJoinForm: true,
      errorCode: null,
      notice: null,
    );
  }

  void closeJoinForm() {
    state = state.copyWith(
      showJoinForm: false,
      errorCode: null,
      notice: null,
    );
  }

  void setJoinInput(String value) {
    state = state.copyWith(joinInput: value, errorCode: null, notice: null);
  }

  Future<void> createDuoMap() async {
    state = state.copyWith(isMutating: true, errorCode: null, notice: null);

    try {
      final MapDto map = await _mapRepository.createDuoMap();
      final InvitationDto invitation = await _mapRepository.createInvitation(
        mapId: map.id,
      );
      final MapDto mapWithInvitation = map.copyWith(
        pendingInvitation: invitation,
      );

      _putMap(
        mapWithInvitation,
        showJoinForm: false,
        notice: 'Đã tạo lời mời Duo Map.',
      );
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorCode: _errorCode(error),
      );
    }
  }

  Future<void> createInvitation() async {
    final MapDto? map = state.duoMap;
    if (map == null) {
      return;
    }

    state = state.copyWith(isMutating: true, errorCode: null, notice: null);

    try {
      final InvitationDto invitation = await _mapRepository.createInvitation(
        mapId: map.id,
      );
      _putMap(
        map.copyWith(pendingInvitation: invitation),
        notice: 'Đã tạo lời mời Duo Map.',
      );
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorCode: _errorCode(error),
      );
    }
  }

  Future<void> revokeInvitation() async {
    final MapDto? map = state.duoMap;
    final InvitationDto? invitation = map?.pendingInvitation;
    if (map == null || invitation == null) {
      return;
    }

    state = state.copyWith(isMutating: true, errorCode: null, notice: null);

    try {
      await _mapRepository.revokeInvitation(
        mapId: map.id,
        invitationId: invitation.id,
      );
      _putMap(
        map.copyWith(pendingInvitation: null),
        notice: 'Đã thu hồi lời mời.',
      );
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorCode: _errorCode(error),
      );
    }
  }

  Future<void> acceptInvitation() async {
    final String normalizedCode = normalizeInvitationCode(state.joinInput);
    if (normalizedCode.isEmpty) {
      state = state.copyWith(errorCode: 'invalid_invitation');
      return;
    }

    state = state.copyWith(
      joinInput: normalizedCode,
      isMutating: true,
      errorCode: null,
      notice: null,
    );

    try {
      final AcceptInvitationResponseDto response =
          await _mapRepository.acceptInvitation(code: normalizedCode);

      _putMap(
        response.map,
        showJoinForm: false,
        notice: 'Đã tham gia Duo Map.',
      );
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorCode: _errorCode(error),
      );
    }
  }

  Future<void> removeMember(String userId) async {
    final MapDto? map = state.duoMap;
    if (map == null) {
      return;
    }

    state = state.copyWith(isMutating: true, errorCode: null, notice: null);

    try {
      await _mapRepository.removeMember(mapId: map.id, userId: userId);
      final MapDto updatedMap = map.copyWith(
        members: map.members
            .where((MapMemberDto member) => member.userId != userId)
            .toList(growable: false),
      );

      _putMap(updatedMap, notice: 'Đã gỡ thành viên.');
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorCode: _errorCode(error),
      );
    }
  }

  void refreshSoon() {
    unawaited(load());
  }

  void _putMap(
    MapDto map, {
    bool? showJoinForm,
    String? notice,
  }) {
    final List<MapDto> maps = _replaceMap(state.maps, map);

    state = state.copyWith(
      maps: maps,
      duoMap: map,
      isMutating: false,
      showJoinForm: showJoinForm,
      errorCode: null,
      notice: notice,
    );
  }

  String _errorCode(Object error) {
    if (error is ApiException) {
      return error.apiError.error;
    }

    return 'duo_unexpected_error';
  }

  static MapDto? _firstDuoMap(List<MapDto> maps) {
    for (final MapDto map in maps) {
      if (map.type == MemoryMapType.duo) {
        return map;
      }
    }

    return null;
  }

  static List<MapDto> _replaceMap(List<MapDto> maps, MapDto map) {
    final int index = maps.indexWhere((MapDto item) => item.id == map.id);
    if (index < 0) {
      return <MapDto>[...maps, map];
    }

    return <MapDto>[
      ...maps.take(index),
      map,
      ...maps.skip(index + 1),
    ];
  }
}

const Object _unset = Object();
