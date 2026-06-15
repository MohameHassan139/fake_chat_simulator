# 📱 FakeChat Studio

A production-ready **Fake Chat Simulator** Flutter application that creates pixel-perfect replicas of WhatsApp, Messenger, Instagram DM, and Snapchat conversations — complete with a screenshot export engine.

---

## 🗂️ Project Architecture

```
lib/
├── main.dart                         # App entry point, MultiProvider setup
│
├── models/
│   └── chat_models.dart              # ChatSession, ChatMessage, ChatUser, enums
│
├── providers/
│   ├── chat_provider.dart            # All state: sessions, messages, CRUD
│   └── theme_provider.dart           # Dark/light mode toggle
│
├── screens/
│   ├── dashboard_screen.dart         # Home: list of sessions, create new
│   └── chat_screen.dart              # Simulator view: phone frame + editor
│
├── themes/
│   ├── app_theme.dart                # App-level dark/light Material themes
│   └── platform_themes.dart          # Per-platform colors, fonts, bubble styles
│
├── widgets/
│   ├── chat_viewport.dart            # ⭐ Screenshot boundary (ONLY this gets captured)
│   ├── fake_status_bar.dart          # Realistic iOS/Android status bar mock
│   ├── platform_app_bar.dart         # Platform-specific app bars (WA/Msg/IG/SC)
│   ├── platform_input_bar.dart       # Platform-specific bottom input bars
│   ├── message_bubble.dart           # All bubble types: text, image, audio, call
│   ├── editor_panel.dart             # Editor UI (NEVER captured in screenshot)
│   ├── message_list_editor.dart      # Reorderable message list with context menu
│   ├── contact_editor_sheet.dart     # Edit contact: name, avatar, status
│   ├── settings_editor_sheet.dart    # Edit status bar: time, battery, wifi
│   ├── message_editor_sheet.dart     # Add/edit message: text, sender, status, time
│   └── export_overlay.dart           # Screenshot preview + save/share actions
│
└── utils/
    └── screenshot_helper.dart        # Save to gallery / share sheet
```

---

## ✨ Key Features

### Multi-Platform Templates
- **WhatsApp**: Teal header, `#ECE5DD` chat background, green sent bubbles, double-tick receipts, classic font sizing
- **Messenger**: White UI, blue gradient sent bubbles, circular receiver avatars, bottom action icons
- **Instagram**: Gradient story ring on avatar, purple→red gradient sent bubbles, bordered input field
- **Snapchat**: Yellow header, blue sent bubbles, minimal typography, active indicator dot

### Live Chat Editor
- Add/edit **contact** (name, profile picture, online/offline/typing status, last seen time)
- Quick-add messages from the bottom bar
- Full message editor: text, sender side, delivery status (Sending/Sent/Delivered/Read), custom timestamp
- Add **image messages** (pick from gallery)
- Add **audio messages** (with configurable duration and waveform placeholder)
- Add **voice/video call** placeholders
- **Long-press** any message to edit, delete, or flip sender side
- **Drag-to-reorder** messages

### Screenshot Engine
- `Screenshot` widget wraps ONLY `ChatViewport` — editor controls are **outside** the boundary
- 3x pixel ratio capture for crisp exports
- Preview dialog before saving/sharing
- Save to gallery or native share sheet

### Status Bar Mock
- Configurable **time**, **battery level** (with color-coded fill), **WiFi** toggle
- Renders inside the screenshot boundary as part of the chat view
- Realistic battery icon with percentage

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x SDK
- Android Studio / Xcode

### Install dependencies
```bash
flutter pub get
```

### Run
```bash
flutter run
```

### Build release APK
```bash
flutter build apk --release
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `provider ^6.1.1` | State management |
| `screenshot ^2.1.0` | Capture widget as PNG |
| `share_plus ^7.2.1` | Native share sheet |
| `image_gallery_saver ^2.0.3` | Save to device gallery |
| `image_picker ^1.0.7` | Pick photos from gallery/camera |
| `path_provider ^2.1.2` | File system paths |
| `shared_preferences ^2.2.2` | Local persistence |
| `uuid ^4.3.3` | Unique IDs for messages/sessions |
| `equatable ^2.0.5` | Value equality |
| `permission_handler ^11.3.0` | Runtime permissions |

---

## 🔑 Permissions

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS (`Info.plist`)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>To add images and save screenshots</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>To save generated screenshots</string>
<key>NSCameraUsageDescription</key>
<string>To capture photos for conversations</string>
```

---

## 🏗️ Architecture Notes

### Screenshot Isolation (Critical Design)
```
ChatScreen
├── TopBar              ← Editor UI, NOT captured
├── PhoneFrame
│   └── Screenshot()   ← BOUNDARY: only this is exported
│       └── ChatViewport
│           ├── FakeStatusBar
│           ├── PlatformAppBar
│           ├── MessageList
│           └── PlatformInputBar
├── SenderToggle        ← Editor UI, NOT captured
└── EditorPanel         ← Editor UI, NOT captured (slides in/out with animation)
```

The `Screenshot` widget from the `screenshot` package wraps only `ChatViewport`. When the capture button is tapped:
1. The `EditorPanel` animates out (300ms)
2. `ScreenshotController.capture()` is called with 3x pixel ratio
3. The resulting `Uint8List` is shown in `ExportOverlay`
4. User can save or share; editor animates back in

### State Management
`ChatProvider` (ChangeNotifier) holds:
- `List<ChatSession>` — all sessions
- `ChatSession? activeSession` — currently editing
- `bool isSenderMode` — which side the quick-add bar uses

Sessions and messages are modified in-place and `notifyListeners()` triggers UI rebuild.

### Adding a New Platform
1. Add to `Platform` enum in `chat_models.dart`
2. Define a `PlatformTheme` const in `platform_themes.dart`
3. Add a case in `PlatformAppBar`
4. Add a case in `PlatformInputBar`
5. Add platform color/icon/name helpers in `ChatSession`

---

## 🎨 Customization

### Changing Bubble Styles
Edit `PlatformTheme` values in `platform_themes.dart`:
- `bubbleRadius` — corner radius
- `senderBubble` / `receiverBubble` — bubble colors
- `gradientSenderBubble: true` + `senderGradient` — gradient bubbles
- `showReceiverAvatar` — show contact avatar next to their bubbles
- `timestampStyle` / `messageStyle` — typography

### Fonts
The app uses the system font by default. To add custom fonts:
1. Download TTF/OTF files
2. Add to `assets/fonts/`
3. Register in `pubspec.yaml` under `fonts:`
4. Reference in `PlatformTheme.messageStyle`

---

## 📸 Screenshot Tips
- Use **9:41** as the "Apple keynote" time for authenticity
- Set battery to **100%** for a clean look
- Toggle WiFi on
- Use **"online"** status for active conversation feel
- WhatsApp: use green bubbles with double blue ticks for "read" messages

---

*Built with Flutter · Designed for creators and content makers*
