import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:fake_chat_simulator/main.dart';
import 'package:fake_chat_simulator/models/chat_models.dart';
import 'package:fake_chat_simulator/providers/theme_provider.dart';
import 'package:fake_chat_simulator/themes/platform_themes.dart';
import 'package:fake_chat_simulator/utils/background_remover_helper.dart';
import 'package:fake_chat_simulator/widgets/message_bubble.dart';

Widget _wrapBubble(ChatMessage message, Platform platform) {
  return ChangeNotifierProvider<ThemeProvider>(
    create: (_) => ThemeProvider(),
    child: MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: message,
          contactUser: ChatUser(id: 'contact-1', name: 'Sam'),
          platform: platform,
          platformTheme: PlatformTheme.of(platform),
          isFirstInGroup: true,
          isLastInGroup: true,
        ),
      ),
    ),
  );
}

ChatMessage _msg({
  required MessageType type,
  required bool isSender,
  bool isDeleted = false,
  bool isOneTime = false,
  bool isOneTimeOpened = false,
}) {
  return ChatMessage(
    id: 'm-${DateTime.now().microsecondsSinceEpoch}',
    text: '',
    type: type,
    isSender: isSender,
    timestamp: DateTime.now(),
    isDeleted: isDeleted,
    isOneTime: isOneTime,
    isOneTimeOpened: isOneTimeOpened,
  );
}

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('sessions_box');
    await Hive.openBox('settings_box');
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FakeChatSimulatorApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('ChatMessage sticker, isDeleted, isOneTime model serialization test', () {
    final msg = ChatMessage(
      id: 'test-1',
      text: 'Sticker Message',
      type: MessageType.sticker,
      isSender: true,
      timestamp: DateTime.now(),
      isDeleted: true,
      isOneTime: true,
      isOneTimeOpened: false,
    );

    final map = msg.toMap();
    expect(map['type'], MessageType.sticker.index);
    expect(map['isDeleted'], true);
    expect(map['isOneTime'], true);
    expect(map['isOneTimeOpened'], false);

    final deserialized = ChatMessage.fromMap(map);
    expect(deserialized.type, MessageType.sticker);
    expect(deserialized.isDeleted, true);
    expect(deserialized.isOneTime, true);
    expect(deserialized.isOneTimeOpened, false);
  });

  test('BackgroundRemoverHelper corner color detection test', () {
    final image = img.Image(width: 2, height: 2);
    image.setPixelRgb(0, 0, 255, 255, 255);
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    final color = BackgroundRemoverHelper.autoDetectCornerColor(pngBytes);
    expect(color, isNotNull);
  });

  test('MessageFeatureRules one-time capability matrix matches real apps', () {
    // WhatsApp and Snapchat support one-time voice notes; Instagram and
    // Messenger do not.
    expect(MessageFeatureRules.canBeOneTime(Platform.whatsapp, MessageType.audio), isTrue);
    expect(MessageFeatureRules.canBeOneTime(Platform.snapchat, MessageType.audio), isTrue);
    expect(MessageFeatureRules.canBeOneTime(Platform.instagram, MessageType.audio), isFalse);
    expect(MessageFeatureRules.canBeOneTime(Platform.messenger, MessageType.audio), isFalse);

    // Photo/video one-time is supported everywhere.
    for (final p in Platform.values) {
      expect(MessageFeatureRules.canBeOneTime(p, MessageType.image), isTrue);
      expect(MessageFeatureRules.canBeOneTime(p, MessageType.video), isTrue);
    }

    // Text, stickers, calls, and date dividers are never one-time anywhere.
    for (final p in Platform.values) {
      expect(MessageFeatureRules.canBeOneTime(p, MessageType.text), isFalse);
      expect(MessageFeatureRules.canBeOneTime(p, MessageType.sticker), isFalse);
      expect(MessageFeatureRules.canBeOneTime(p, MessageType.voiceCall), isFalse);
      expect(MessageFeatureRules.canBeOneTime(p, MessageType.dateDivider), isFalse);
    }
  });

  group('Deleted message bubble copy', () {
    testWidgets('WhatsApp shows sender vs receiver deleted text', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.text, isSender: true, isDeleted: true), Platform.whatsapp));
      await tester.pumpAndSettle();
      expect(find.text('You deleted this message'), findsOneWidget);

      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.text, isSender: false, isDeleted: true), Platform.whatsapp));
      await tester.pumpAndSettle();
      expect(find.text('This message was deleted'), findsOneWidget);
    });

    testWidgets('Messenger embeds contact name for receiver-deleted messages', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.text, isSender: false, isDeleted: true), Platform.messenger));
      await tester.pumpAndSettle();
      expect(find.text('Sam removed a message'), findsOneWidget);
    });

    testWidgets('Instagram embeds contact name for receiver-deleted messages', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.text, isSender: false, isDeleted: true), Platform.instagram));
      await tester.pumpAndSettle();
      expect(find.text('Sam unsent a message'), findsOneWidget);
    });

    testWidgets('Snapchat shows "Deleted a Chat" for receiver', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.text, isSender: false, isDeleted: true), Platform.snapchat));
      await tester.pumpAndSettle();
      expect(find.text('Deleted a Chat'), findsOneWidget);
    });

    testWidgets('deleted call record is not rendered as a native call log on Messenger', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.voiceCall, isSender: true, isDeleted: true), Platform.messenger));
      await tester.pumpAndSettle();
      expect(find.text('You removed a message'), findsOneWidget);
    });
  });

  group('One-time message bubble copy', () {
    testWidgets('WhatsApp labels unopened voice one-time as Voice message', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.audio, isSender: true, isOneTime: true), Platform.whatsapp));
      await tester.pumpAndSettle();
      expect(find.text('Voice message'), findsOneWidget);
    });

    testWidgets('Instagram labels unopened video one-time as Video', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.video, isSender: true, isOneTime: true), Platform.instagram));
      await tester.pumpAndSettle();
      expect(find.text('Video'), findsOneWidget);
    });

    testWidgets('Messenger labels unopened photo one-time as View once photo', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.image, isSender: true, isOneTime: true), Platform.messenger));
      await tester.pumpAndSettle();
      expect(find.text('View once photo'), findsOneWidget);
    });

    testWidgets('Snapchat distinguishes New Snap / video / audio note', (tester) async {
      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.image, isSender: true, isOneTime: true), Platform.snapchat));
      await tester.pumpAndSettle();
      expect(find.text('New Snap'), findsOneWidget);

      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.video, isSender: true, isOneTime: true), Platform.snapchat));
      await tester.pumpAndSettle();
      expect(find.text('New video Snap'), findsOneWidget);

      await tester.pumpWidget(_wrapBubble(_msg(type: MessageType.audio, isSender: true, isOneTime: true), Platform.snapchat));
      await tester.pumpAndSettle();
      expect(find.text('New audio note'), findsOneWidget);
    });

    testWidgets('opened one-time message shows Opened regardless of platform', (tester) async {
      await tester.pumpWidget(_wrapBubble(
        _msg(type: MessageType.image, isSender: true, isOneTime: true, isOneTimeOpened: true),
        Platform.whatsapp,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Opened'), findsOneWidget);
    });
  });
}
