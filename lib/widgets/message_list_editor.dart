import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/platform_themes.dart';
import '../utils/language_helper.dart';
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
    final isAr = context.watch<ThemeProvider>().isArabic;
    if (session == null) return const SizedBox.shrink();

    final platformTheme = PlatformTheme.of(session.platform);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (session.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 12),
            Text(LanguageHelper.translate('no_messages_yet', isAr), style: TextStyle(color: isDark ? Colors.white24 : Colors.black38)),
            const SizedBox(height: 8),
            Text(
              LanguageHelper.translate('use_editor_below', isAr),
              style: TextStyle(color: isDark ? Colors.white12 : Colors.black26, fontSize: 12),
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
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) => showMessageActions(context, message);
}

/// Tap or long-press on a message in the chat: reply, edit, mark it as
/// deleted or edited (the way the real apps show it), move it, or remove it.
void showMessageActions(BuildContext context, ChatMessage message) {
  final chat = context.read<ChatProvider>();
  void openEditor({ChatMessage? editing, ChatMessage? replyTo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: chat,
        child: MessageEditorSheet(editingMessage: editing, repliedToMessage: replyTo),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheet) => _MessageContextMenu(
      message: message,
      onEdit: () {
        Navigator.pop(sheet);
        openEditor(editing: message);
      },
      onReply: () {
        Navigator.pop(sheet);
        openEditor(replyTo: message);
      },
      onDelete: () {
        chat.deleteMessage(message.id);
        Navigator.pop(sheet);
      },
      onToggleSide: () {
        chat.updateMessage(message.id, message.copyWith(isSender: !message.isSender));
        Navigator.pop(sheet);
      },
      onToggleDeleted: () {
        chat.updateMessage(message.id, message.copyWith(isDeleted: !message.isDeleted));
        Navigator.pop(sheet);
      },
      onToggleEdited: () {
        chat.updateMessage(message.id, message.copyWith(isEdited: !message.isEdited));
        Navigator.pop(sheet);
      },
    ),
  );
}

class _MessageContextMenu extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onEdit;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onToggleSide;
  final VoidCallback onToggleDeleted;
  final VoidCallback onToggleEdited;

  const _MessageContextMenu({
    required this.message,
    required this.onEdit,
    required this.onReply,
    required this.onDelete,
    required this.onToggleSide,
    required this.onToggleDeleted,
    required this.onToggleEdited,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16, color: isDark ? Colors.white38 : Colors.black45),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.text.isEmpty ? (LanguageHelper.pick(isAr, '[مكون]', '[${message.type.name}]')) : message.text,
                    style: TextStyle(color: textColor, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: message.isSender
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                        : const Color(0xFF42A5F5).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.isSender ? (LanguageHelper.pick(isAr, 'أنا', 'Me')) : (LanguageHelper.pick(isAr, 'الطرف الآخر', 'Them')),
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
              label: LanguageHelper.translate('reply_to_this_message', isAr),
              color: const Color(0xFF4CAF50),
              onTap: onReply,
            ),
          _MenuItem(
            icon: Icons.edit_rounded,
            label: LanguageHelper.translate('edit_message', isAr),
            color: const Color(0xFF6C63FF),
            onTap: onEdit,
          ),
          if (message.type != MessageType.dateDivider)
            _MenuItem(
              icon: Icons.swap_horiz_rounded,
              label: message.isSender ? LanguageHelper.translate('move_to_their_side', isAr) : LanguageHelper.translate('move_to_my_side', isAr),
              color: const Color(0xFF42A5F5),
              onTap: onToggleSide,
            ),
          if (MessageFeatureRules.canBeDeleted(message.type))
            _MenuItem(
              icon: Icons.block_rounded,
              label: LanguageHelper.translate(message.isDeleted ? 'unmark_deleted' : 'show_as_deleted', isAr),
              color: const Color(0xFFFFA726),
              onTap: onToggleDeleted,
            ),
          if (message.type == MessageType.text && !message.isDeleted)
            _MenuItem(
              icon: Icons.edit_note_rounded,
              label: LanguageHelper.translate(message.isEdited ? 'unmark_edited' : 'show_as_edited', isAr),
              color: const Color(0xFF26A69A),
              onTap: onToggleEdited,
            ),
          _MenuItem(
            icon: Icons.delete_rounded,
            label: LanguageHelper.translate('remove_from_chat', isAr),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

