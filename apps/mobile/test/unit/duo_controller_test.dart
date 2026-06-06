import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/duo_controller.dart';
import 'package:memory_map_mobile/data/mock/fake_map_repository.dart';
import 'package:memory_map_mobile/data/mock/mock_data.dart';

void main() {
  test('creates a Duo Map and immediately creates a pending invitation',
      () async {
    final MockBackendState state = MockBackendState.seeded();
    final DuoController controller = DuoController(
      mapRepository: FakeMapRepository(state),
    );

    await controller.load();
    await controller.createDuoMap();

    expect(controller.state.duoMap?.type.name, 'duo');
    expect(controller.state.duoMap?.members, hasLength(1));
    expect(
      controller.state.duoMap?.pendingInvitation?.code,
      startsWith('INV-'),
    );
    expect(controller.state.errorCode, isNull);

    controller.dispose();
  });

  test('surfaces the 409 pending invitation error inline', () async {
    final MockBackendState state = MockBackendState.seeded();
    final DuoController controller = DuoController(
      mapRepository: FakeMapRepository(state),
    );

    await controller.load();
    await controller.createDuoMap();
    await controller.createInvitation();

    expect(controller.state.errorCode, 'invitation_pending_exists');

    controller.dispose();
  });

  test('accepts a pasted invite link by extracting the code', () async {
    final MockBackendState state = MockBackendState.seeded();
    final DuoController controller = DuoController(
      mapRepository: FakeMapRepository(state),
    );

    await controller.load();
    controller.openJoinForm('https://memo.app/inv/INV-DEMO');
    await controller.acceptInvitation();

    expect(controller.state.showJoinForm, isFalse);
    expect(controller.state.duoMap?.members, hasLength(2));
    expect(controller.state.notice, 'Đã tham gia Duo Map.');
    expect(controller.state.errorCode, isNull);

    controller.dispose();
  });

  test('returns invalid invitation for blank or unknown codes', () async {
    final MockBackendState state = MockBackendState.seeded();
    final DuoController controller = DuoController(
      mapRepository: FakeMapRepository(state),
    );

    await controller.load();
    controller.openJoinForm();
    await controller.acceptInvitation();

    expect(controller.state.errorCode, 'invalid_invitation');

    controller.setJoinInput('INV-MISSING');
    await controller.acceptInvitation();

    expect(controller.state.errorCode, 'invalid_invitation');

    controller.dispose();
  });
}
