import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../themes/platform_themes.dart';
import '../widgets/message_bubble.dart';
import 'message_editor_sheet.dart';

/// An editable list of messages shown during edit mode
/// (Not captured in screenshot - this is for the dashboard editor view)
class MessageListEditor extends StatelessWidget {
  const MessageListEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final session = chatProvider.activeSession;
    if (session == null) return const SizedBox.shrink();

    final platformTheme = PlatformTheme.of(session.platform);

    if (session.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.white12),
            const SizedBox(height: 12),
            const Text('No messages yet', style: TextStyle(color: Colors.white24)),
            const SizedBox(height: 8),
            const Text(
              'Use the editor below to add messages',
              style: TextStyle(color: Colors.white12, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: session.messages.length,
      buildDefaultDragHandles: false,
      onReorder: chatProvider.reorderMessages,
      itemBuilder: (context, index) {
        final msg = session.messages[index];
        final prevMsg = index > 0 ? session.messages[index - 1] : null;
        final nextMsg = index < session.messages.length - 1 ? session.messages[index + 1] : null;

        return _EditableMessageRow(
          key: ValueKey(msg.id),
          message: msg,
          index: index,
          contactUser: session.contactUser,
          platform: session.platform,
          platformTheme: platformTheme,
          isFirstInGroup: prevMsg == null || prevMsg.isSender != msg.isSender,
          isLastInGroup: nextMsg == null || nextMsg.isSender != msg.isSender,
        );
      },
    );
  }
}

class _EditableMessageRow extends StatelessWidget {
  final ChatMessage message;
  final int index;
  final ChatUser contactUser;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _EditableMessageRow({
    super.key,
    required this.message,
    required this.index,
    required this.contactUser,
    required this.platform,
    required this.platformTheme,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Stack(
        children: [
          MessageBubble(
            message: message,
            contactUser: contactUser,
            platform: platform,
            platformTheme: platformTheme,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
          ),
          // Drag handle
          Positioned(
            top: 8,
            left: message.isSender ? null : 0,
            right: message.isSender ? 0 : null,
            child: ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.drag_handle_rounded,
                  size: 16,
                  color: Colors.white24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageContextMenu(
        message: message,
        onEdit: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<ChatProvider>(),
              child: MessageEditorSheet(editingMessage: message),
            ),
          );
        },
        onReply: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<ChatProvider>(),
              child: MessageEditorSheet(repliedToMessage: message),
            ),
          );
        },
        onDelete: () {
          context.read<ChatProvider>().deleteMessage(message.id);
          Navigator.pop(context);
        },
        onToggleSide: () {
          context.read<ChatProvider>().updateMessage(
            message.id,
            message.copyWith(isSender: !message.isSender),
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _MessageContextMenu extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onEdit;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onToggleSide;

  const _MessageContextMenu({
    required this.message,
    required this.onEdit,
    required this.onReply,
    required this.onDelete,
    required this.onToggleSide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white38),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.text.isEmpty ? '[${message.type.name}]' : message.text,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: message.isSender
                        ? const Color(0xFF6C63FF).withOpacity(0.2)
                        : const Color(0xFF42A5F5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.isSender ? 'Me' : 'Them',
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isSender ? const Color(0xFF6C63FF) : const Color(0xFF42A5F5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (message.type != MessageType.dateDivider)
            _MenuItem(
              icon: Icons.reply_rounded,
              label: 'Reply to this message',
              color: const Color(0xFF4CAF50),
              onTap: onReply,
            ),
          _MenuItem(
            icon: Icons.edit_rounded,
            label: 'Edit Message',
            color: const Color(0xFF6C63FF),
            onTap: onEdit,
          ),
          if (message.type != MessageType.dateDivider)
            _MenuItem(
              icon: Icons.swap_horiz_rounded,
              label: message.isSender ? 'Move to Their side' : 'Move to My side',
              color: const Color(0xFF42A5F5),
              onTap: onToggleSide,
            ),
          _MenuItem(
            icon: Icons.delete_rounded,
            label: 'Delete Message',
            color: Colors.redAccent,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
