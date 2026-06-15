import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../themes/platform_themes.dart';

class PlatformInputBar extends StatelessWidget {
  final Platform platform;
  final PlatformTheme platformTheme;

  const PlatformInputBar({
    super.key,
    required this.platform,
    required this.platformTheme,
  });

  @override
  Widget build(BuildContext context) {
    switch (platform) {
      case Platform.whatsapp:
        return _WhatsAppInput(theme: platformTheme);
      case Platform.messenger:
        return _MessengerInput(theme: platformTheme);
      case Platform.instagram:
        return _InstagramInput(theme: platformTheme);
      case Platform.snapchat:
        return _SnapchatInput(theme: platformTheme);
    }
  }
}

// ─── WhatsApp Input ────────────────────────────────────────────────────────────

class _WhatsAppInput extends StatelessWidget {
  final PlatformTheme theme;
  const _WhatsAppInput({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.inputFieldBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF667781), size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Message',
                      style: TextStyle(color: Color(0xFF667781), fontSize: 16),
                    ),
                  ),
                  Transform.rotate(
                    angle: -0.7,
                    child: const Icon(Icons.attach_file, color: Color(0xFF667781), size: 23),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.camera_alt_rounded, color: Color(0xFF667781), size: 23),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.sendButtonColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 23),
          ),
        ],
      ),
    );
  }
}

// ─── Messenger Input ──────────────────────────────────────────────────────────

class _MessengerInput extends StatelessWidget {
  final PlatformTheme theme;
  const _MessengerInput({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: theme.inputBarBg,
        border: const Border(top: BorderSide(color: Color(0xFFECECEC), width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.sendButtonColor, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.camera_alt, color: theme.sendButtonColor, size: 23),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.image_rounded, color: theme.sendButtonColor, size: 23),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.mic, color: theme.sendButtonColor, size: 23),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.inputFieldBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Aa',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.thumb_up, color: theme.sendButtonColor, size: 23),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─── Instagram Input ──────────────────────────────────────────────────────────

class _InstagramInput extends StatelessWidget {
  final PlatformTheme theme;
  const _InstagramInput({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      decoration: BoxDecoration(
        color: theme.inputBarBg,
        border: const Border(top: BorderSide(color: Color(0xFFF2F2F2), width: 0.8)),
      ),
      child: Row(
        children: [
          // Gradient circular camera container on the left
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC32E96), Color(0xFF9035B9), Color(0xFF4A55D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E2E2), width: 1.0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sentiment_satisfied_alt_rounded, color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Message...',
                      style: TextStyle(color: Color(0xFF999999), fontSize: 14.5),
                    ),
                  ),
                  const Icon(Icons.mic_none_outlined, color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  const Icon(Icons.image_outlined, color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite_border, color: Colors.black54, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Snapchat Input ───────────────────────────────────────────────────────────

class _SnapchatInput extends StatelessWidget {
  final PlatformTheme theme;
  const _SnapchatInput({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF2F2F2), width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.black87, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Send a chat',
                      style: TextStyle(
                        color: Color(0xFF656667),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF656667), size: 21),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.mic_none_outlined, color: Color(0xFF656667), size: 21),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_rounded, color: Colors.black87, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
