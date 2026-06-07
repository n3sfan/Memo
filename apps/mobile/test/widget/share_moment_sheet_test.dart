import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/share_launcher.dart';
import 'package:memory_map_mobile/app/share_moment_sheet.dart';
import 'package:memory_map_mobile/data/mock/fake_share_repository.dart';
import 'package:memory_map_mobile/data/mock/mock_data.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates, copies, shares and revokes a pin link', (tester) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          final Object? arguments = methodCall.arguments;
          if (arguments is Map<Object?, Object?>) {
            clipboardText = arguments['text'] as String?;
          }
          return null;
        }
        if (methodCall.method == 'Clipboard.getData') {
          return <String, Object?>{'text': clipboardText};
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final MockBackendState state = MockBackendState.seeded();
    final FakeShareRepository repository = FakeShareRepository(state);
    final RecordingShareLauncher launcher = RecordingShareLauncher();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shareRepositoryProvider.overrideWithValue(repository),
          shareLauncherProvider.overrideWithValue(launcher),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ShareMomentSheet(pin: state.pins.first),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('share_moment_loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('share_moment_link')), findsOneWidget);
    expect(find.textContaining('https://memo.app/p/'), findsOneWidget);

    await tester.tap(find.byKey(const Key('share_moment_copy')));
    await tester.pump(const Duration(milliseconds: 50));
    final ClipboardData? copied =
        await Clipboard.getData(Clipboard.kTextPlain);
    expect(copied?.text, contains('https://memo.app/p/'));
    expect(find.text('Đã sao chép'), findsOneWidget);

    await tester.tap(find.byKey(const Key('share_moment_share')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(launcher.sharedTexts.single, contains('https://memo.app/p/'));

    await tester.tap(find.byKey(const Key('share_moment_revoke')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Liên kết đã thu hồi'), findsOneWidget);
  });
}

class RecordingShareLauncher implements ShareLauncher {
  final List<String> sharedTexts = <String>[];

  @override
  Future<void> shareText(String text, {String? subject}) async {
    sharedTexts.add(text);
  }
}
