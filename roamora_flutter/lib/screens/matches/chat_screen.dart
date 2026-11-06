import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/match_model.dart';
import '../../models/message_model.dart';
import '../../models/collectible_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/notifications_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final MatchModel? match;

  const ChatScreen({
    super.key,
    required this.matchId,
    this.match,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(chatProvider(widget.matchId).notifier).sendMessage(text).then((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return 'Today';
    if (msgDate == yesterday) return 'Yesterday';
    return DateFormat('EEEE, d MMMM').format(date);
  }

  void _openGiftSheet(List<CollectibleItemModel> inventory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Text('🎁 ', style: TextStyle(fontSize: 22)),
                Text(
                  'Send a Gift to ${widget.match?.name ?? "your match"}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (inventory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Text('🎒', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Text(
                      'No Collectibles in Backpack',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Find rare drops on the Adventure Map to send gifts!',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: inventory.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = inventory[index];
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await ApiClient.instance.post('/inventory/${item.id}/use', data: {'targetUserId': widget.match?.otherUserId});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 You gifted a ${item.name} to ${widget.match?.name}!'),
                                backgroundColor: AppColors.coral,
                              ),
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not send gift right now.')),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text('x${item.quantity}', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.matchId));
    final notifState = ref.watch(notificationsProvider);
    final matchName = widget.match?.name ?? 'Match';
    final matchImage = widget.match?.image;

    // Auto-scroll when new messages arrive
    if (chatState.messages.length > _lastMessageCount) {
      _lastMessageCount = chatState.messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.coralPale,
              backgroundImage: matchImage != null && matchImage.isNotEmpty
                  ? CachedNetworkImageProvider(matchImage)
                  : null,
              child: matchImage == null || matchImage.isEmpty
                  ? Text(
                      matchName.isNotEmpty ? matchName.substring(0, 1).toUpperCase() : 'M',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coral, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matchName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Active Now',
                    style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppColors.ink, size: 21),
            onPressed: widget.match != null
                ? () {
                    ref.read(callProvider.notifier).initiateCall(widget.match!, audioOnly: true);
                    context.push('/video-call');
                  }
                : null,
            tooltip: 'Voice Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: AppColors.coral, size: 24),
            onPressed: widget.match != null
                ? () {
                    ref.read(callProvider.notifier).initiateCall(widget.match!, audioOnly: false);
                    context.push('/video-call');
                  }
                : null,
            tooltip: 'Live Video Call',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
                : chatState.messages.isEmpty
                    ? _buildEmptyChat(matchName)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatState.messages[index];

                          // Check if date header should be shown
                          bool showDateHeader = false;
                          if (index == 0) {
                            showDateHeader = true;
                          } else {
                            final prev = chatState.messages[index - 1];
                            final prevDate = DateTime(prev.createdAt.year, prev.createdAt.month, prev.createdAt.day);
                            final currDate = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
                            if (prevDate != currDate) {
                              showDateHeader = true;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader) _buildDateHeader(msg.createdAt),
                              _buildMessageBubble(msg),
                            ],
                          );
                        },
                      ),
          ),

          // Message Composer Bar matching website
          Container(
            padding: EdgeInsets.fromLTRB(8, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                // Gift Button
                IconButton(
                  icon: const Icon(Icons.card_giftcard_outlined, color: Color(0xFFD97706), size: 22),
                  onPressed: () => _openGiftSheet(notifState.inventory),
                  tooltip: 'Send Virtual Gift',
                ),

                // Mini-Game Challenge Button
                IconButton(
                  icon: const Icon(Icons.sports_esports_outlined, color: AppColors.coral, size: 22),
                  onPressed: () {
                    ref.read(gamesProvider.notifier).sendGameInvitation(widget.matchId, 'VIBE_CHECK');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎮 Mini-Game invitation sent to your match!'),
                        backgroundColor: AppColors.coral,
                      ),
                    );
                  },
                  tooltip: 'Invite to Mini-Game',
                ),

                // Text Input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send Button
                InkWell(
                  onTap: _sendMessage,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.coralGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coral.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF4ECEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateHeader(date),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat(String name) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.coralPale,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('👋', style: TextStyle(fontSize: 30))),
            ),
            const SizedBox(height: 14),
            Text(
              'Say Hello to $name!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Break the ice with a thoughtful compliment, ask about their favorite hangout, or send an exploration gift.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final fromMe = msg.fromMe;
    final timeStr = DateFormat('h:mm a').format(msg.createdAt);

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: fromMe ? AppColors.coral : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromMe ? 16 : 4),
            bottomRight: Radius.circular(fromMe ? 4 : 16),
          ),
          border: fromMe ? null : Border.all(color: AppColors.border),
          boxShadow: AppColors.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.body,
              style: TextStyle(
                color: fromMe ? Colors.white : AppColors.ink,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: fromMe ? Colors.white70 : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
