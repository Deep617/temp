import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/core/services/secure_storage_service.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/features/dashboard/session/data/repositories/session_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/response_ml/message.dart';
import '../bloc/chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.buddyName,
    required this.buddyId,
    this.buddyAvatar,
  });
  final String  chatId;
  final String  buddyName;
  final String  buddyId;
  final String? buddyAvatar;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scroll  = ScrollController();
  bool    _isTyping = false;
  IO.Socket? _socket;
  // Debounce timer — emits typing:stop 2 s after the user pauses
  DateTime _lastTyped = DateTime(0);

  @override
  void initState() {
    super.initState();
    // Load messages via BLoC
    context.read<ChatBloc>().add(ChatMessagesLoaded(chatId: widget.chatId));
    context.read<ChatBloc>().add(ChatMarkedRead(chatId: widget.chatId));
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.emit('chat:leave', {'chatId': widget.chatId});
    _socket?.disconnect();
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _initSocket() {
    // Read the stored access token so the Socket.io server can authenticate
    // this connection via the JWT middleware in src/socket/socket.js.
     getIt<SecureStorageService>().getAccessToken().then((token) {
      if (!mounted) return;
      _socket = IO.io(ApiEndpoints.socketUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token ?? ''})
          .build());

      _socket!.onConnect((_) {
        // Join the chat room so we receive message:new events for this chat
        _socket!.emit('chat:join', {'chatId': widget.chatId});
      });

      _socket!.connect();

      // Push incoming messages into ChatBloc
      _socket!.on('message:new', (data) {
        final msg = Message.fromJson(data as Map<String, dynamic>);
        if (msg.chatId == widget.chatId && mounted) {
          context.read<ChatBloc>().add(ChatMessageReceived(message: msg));
          _scrollToBottom();
        }
      });

      _socket!.on('typing:start', (_) {
        if (mounted) setState(() => _isTyping = true);
      });
      _socket!.on('typing:stop', (_) {
        if (mounted) setState(() => _isTyping = false);
      });
    }); // end storage.read().then()
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    context.read<ChatBloc>().add(ChatMessageSent(
      chatId:  widget.chatId,
      content: text,
    ));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showTokenError(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎫', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Out of Chat Tokens', style: AppTextStyles.h3()),
          const SizedBox(height: 8),
          Text(
            'You need chat tokens to send messages.\nEarn them by completing sessions or buy more.',
            style: AppTextStyles.body(), textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Buy Tokens',
            onPressed: () { Navigator.pop(ctx); ctx.push(AppRoutes.subscription); },
          ),
          const SizedBox(height: 12),
          GhostButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthBloc>().state.user?.id ?? '';

    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, curr) =>
      curr.status == ChatStatus.failure && curr.error != null,
      listener: (context, state) {
        if (state.error?.statusCode == 402) {
          _showTokenError(context);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!.message,
                style: AppTextStyles.bodySM(color: AppColors.error))),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: GestureDetector(
            onTap: () => context.push(
                AppRoutes.buddyProfile.replaceAll(':userId', widget.chatId)),
            child: Row(children: [
              AppAvatar(
                name:     widget.buddyName,
                imageUrl: widget.buddyAvatar,
                size:     36,
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.buddyName, style: AppTextStyles.subtitle()),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (_, state) => Text(
                    _isTyping ? 'typing...' : 'tap to view profile',
                    style: AppTextStyles.caption(
                        color: _isTyping ? AppColors.primary : AppColors.textMuted),
                  ),
                ),
              ]),
            ]),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.video_call_outlined, color: AppColors.textMuted),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
              onPressed: () {},
            ),
          ],
        ),

        body: Column(children: [
          // Message list
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isLoading && state.messages.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }

                final messages = state.messages;

                // Scroll to bottom after fresh load
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients &&
                        _scroll.position.maxScrollExtent > 0 &&
                        _scroll.offset < _scroll.position.maxScrollExtent - 200) {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    }
                  });
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isTyping && i == messages.length) return _TypingBubble();

                    final msg    = messages[i];
                    final isMe   = msg.senderId == myId;
                    final showDate = i == 0 ||
                        !_sameDay(messages[i - 1].createdAt, msg.createdAt);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        _MessageBubble(msg: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface1,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(children: [
                // Session shortcut
                GestureDetector(
                  onTap: () => context.push(AppRoutes.scheduleSession,
                      extra: {'buddyId': widget.buddyId, 'buddyName': widget.buddyName}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.fitness_center, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('Session',
                          style: AppTextStyles.bodySM(color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),

                // Text field
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) => TextField(
                      controller: _msgCtrl,
                      style:    AppTextStyles.body(color: AppColors.textPrimary),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText:      'Message...',
                        hintStyle:     AppTextStyles.body(color: AppColors.textDim),
                        filled:        true,
                        fillColor:     AppColors.surface2,
                        border:        OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:  BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onChanged: (v) {
                        if (v.isEmpty) return;
                        _lastTyped = DateTime.now();
                        _socket?.emit('typing:start', {'chatId': widget.chatId});
                        // Auto-stop after 2 s of no keystrokes
                        Future.delayed(const Duration(seconds: 2), () {
                          if (DateTime.now().difference(_lastTyped).inSeconds >= 2) {
                            _socket?.emit('typing:stop', {'chatId': widget.chatId});
                          }
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) => GestureDetector(
                    onTap: state.isSending ? null : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color:  state.isSending ? AppColors.surface3 : AppColors.primary,
                        shape:  BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: AppColors.primaryGlow, blurRadius: 12)],
                      ),
                      child: state.isSending
                          ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.send_rounded,
                          color: Colors.black, size: 20),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Message Bubble ────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isMe});
  final Message msg;
  final bool    isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4, bottom: 4,
        left:  isMe ? 60 : 0,
        right: isMe ?  0 : 60,
      ),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AppAvatar(
                name: msg.senderName, imageUrl: msg.senderAvatar, size: 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface2,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4  : 18),
                    ),
                    boxShadow: isMe
                        ? [BoxShadow(
                        color: AppColors.primaryGlow, blurRadius: 8)]
                        : null,
                  ),
                  child: msg.type == 'session_invite'
                      ? _SessionInviteCard(msg: msg)
                      : Text(
                    msg.content,
                    style: isMe
                        ? AppTextStyles.body(color: Colors.black)
                        : AppTextStyles.body(),
                  ),
                ),
                const SizedBox(height: 3),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    timeago.format(msg.createdAt, locale: 'en_short'),
                    style: AppTextStyles.caption(),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead ? Icons.done_all : Icons.done,
                      size: 13,
                      color: msg.isRead
                          ? AppColors.primary
                          : AppColors.textDim,
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
  }
}

class _SessionInviteCard extends StatefulWidget {
  const _SessionInviteCard({required this.msg});
  final Message msg;
  @override
  State<_SessionInviteCard> createState() => _SessionInviteCardState();
}

class _SessionInviteCardState extends State<_SessionInviteCard> {
  bool _responding = false;

  Future<void> _respond(String action) async {
    setState(() => _responding = true);
    try {
      final data      = widget.msg.metadata ?? {};
      final sessionId = data['sessionId'] as String?;
      if (sessionId == null) return;
      await getIt<SessionRepository>().respondToSessionInvite(sessionId,
          action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'confirm'
              ? 'Session confirmed! 🤝' : 'Session declined'),
          backgroundColor: action == 'confirm'
              ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data        = widget.msg.metadata ?? {};
    final activity    = data['activity']    as String? ?? 'Workout';
    final scheduledAt = data['scheduledAt'] as String?;
    final duration    = data['durationMins'] as int?   ?? 60;
    final gymName     = data['gymName']     as String?;

    DateTime? dt;
    if (scheduledAt != null) dt = DateTime.tryParse(scheduledAt);
    final dateStr = dt != null
        ? '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)} · '
        '${_fmt12(dt)}'
        : '';

    final durationStr = duration == 45 ? '45 mins'
        : duration == 60  ? '1 hour'
        : duration == 90  ? '1.5 hours'
        : '2 hours';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(children: [
          const Icon(Icons.fitness_center,
              color: AppColors.primary, size: 14),
          const SizedBox(width: 5),
          Text('Session Invite',
              style: AppTextStyles.label(color: AppColors.primary)),
        ]),
        const SizedBox(height: 8),
        // Activity
        Text(activity,
            style: AppTextStyles.subtitle(color: Colors.black)),
        const SizedBox(height: 3),
        // Date/time
        if (dateStr.isNotEmpty)
          Text(dateStr,
              style: AppTextStyles.bodySM(color: Colors.black54)),
        // Duration
        Row(children: [
          const Icon(Icons.timer_outlined,
              size: 12, color: Colors.black38),
          const SizedBox(width: 3),
          Text(durationStr,
              style: AppTextStyles.bodySM(color: Colors.black54)),
          if (gymName != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.location_on,
                size: 12, color: Colors.black38),
            const SizedBox(width: 3),
            Flexible(child: Text(gymName,
                style: AppTextStyles.bodySM(color: Colors.black54),
                overflow: TextOverflow.ellipsis)),
          ],
        ]),
        const SizedBox(height: 12),
        // Confirm / Decline buttons
        if (!_responding)
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _respond('decline'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:        Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text('Decline ❌',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySM(
                          color: Colors.red)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _respond('confirm'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:        AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Text('Confirm ✅',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySM(
                          color: AppColors.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ])
        else
          const Center(child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          )),
      ],
    );
  }

  String _weekday(int w) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][w-1];
  String _month(int m)   =>
      ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
  String _fmt12(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2,'0');
    return '$h:$m ${dt.hour >= 12 ? "PM" : "AM"}';
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ...List.generate(3, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6, height: 6,
            decoration: const BoxDecoration(
                color: AppColors.textMuted, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat(),
              delay: Duration(milliseconds: i * 150))
              .moveY(begin: 0, end: -4,
              duration: 400.ms, curve: Curves.easeInOut)
              .then()
              .moveY(begin: -4, end: 0,
              duration: 400.ms, curve: Curves.easeInOut)),
        ]),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);

    String label;
    if (d == today) {
      label = 'Today';
    } else if (d == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: AppTextStyles.caption()),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ]),
    );
  }
}
