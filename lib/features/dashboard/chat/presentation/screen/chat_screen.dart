import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seshlly/core/api/api_endpoints.dart';
import 'package:seshlly/core/services/secure_storage_service.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/features/dashboard/session/data/repositories/session_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/response_ml/message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/strike_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.buddyName,
    required this.buddyId,
    this.buddyAvatar,
    this.matchId,
  });

  final String chatId;
  final String buddyName;
  final String buddyId;
  final String? buddyAvatar;
  final String? matchId; // needed for Strike streak + send

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _pageCtrl = PageController(initialPage: 0);
  bool _isTyping = false;
  IO.Socket? _socket;

  // Strike 2 camera
  final _picker = ImagePicker();
  int _pageIndex = 0; // 0=chat, 1=camera (PageView)

  // Debounce timer — emits typing:stop 2 s after the user pauses
  DateTime _lastTyped = DateTime(0);

  @override
  void initState() {
    super.initState();
    // Load messages via BLoC
    context.read<ChatBloc>().add(ChatMessagesLoaded(chatId: widget.chatId));
    context.read<ChatBloc>().add(ChatMarkedRead(chatId: widget.chatId));

    // Load strike streak + pending count via BLoC
    if (widget.matchId != null) {
      context.read<StrikeBloc>().add(
        StrikeLoadRequested(matchId: widget.matchId!, buddyId: widget.buddyId),
      );
    }

    _initSocket();
  }

  @override
  void dispose() {
    _socket?.emit('chat:leave', {'chatId': widget.chatId});
    _socket?.disconnect();
    _msgCtrl.dispose();
    _scroll.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // Refresh strike streak via BLoC
  void _refreshStreak() {
    if (widget.matchId == null) return;
    context.read<StrikeBloc>().add(
      StrikeLoadRequested(matchId: widget.matchId!, buddyId: widget.buddyId),
    );
  }

  // Open camera → dispatch to StrikeBloc + animate PageView
  void _openCamera() {
    context.read<StrikeBloc>().add(const StrikeCameraOpened());
    _pageCtrl.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _pageIndex = 1);
  }

  void _closeCamera() {
    context.read<StrikeBloc>().add(const StrikeCameraClosed());
    _pageCtrl.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _pageIndex = 0);
  }

  // Pick photo from gallery for strike
  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img == null || !mounted) return;
    _closeCamera();
    _showStrikePreview(File(img.path));
  }

  // Take photo for strike
  Future<void> _takePicture() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (img == null || !mounted) return;
    _closeCamera();
    _showStrikePreview(File(img.path));
  }

  // Photo captured → dispatch to StrikeBloc + show preview sheet
  void _showStrikePreview(File imageFile) {
    context.read<StrikeBloc>().add(
      StrikePhotoCaptured(imagePath: imageFile.path),
    );
    final strikeBloc = context.read<StrikeBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: strikeBloc,
        child: _StrikePreviewSheet(
          imageFile: imageFile,
          buddyName: widget.buddyName,
          matchId: widget.matchId ?? widget.buddyId,
          receiverId: widget.buddyId,
          streak: strikeBloc.state.streak,
          onSent: () => _refreshStreak(),
        ),
      ),
    );
  }

  // Read the stored access token so the Socket.io server can authenticate
  // this connection via the JWT middleware in src/socket/socket.js.

  _initSocket() {
    getIt<SecureStorageService>().getAccessToken().then((token) {
      if (!mounted) return;
      _socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token ?? ''})
            .build(),
      );

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
    context.read<ChatBloc>().add(
      ChatMessageSent(chatId: widget.chatId, content: text),
    );
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎫', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Out of Chat Tokens', style: AppTextStyles.h3()),
            const SizedBox(height: 8),
            Text(
              'You need chat tokens to send messages.\nEarn them by completing sessions or buy more.',
              style: AppTextStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Buy Tokens',
              onPressed: () {
                Navigator.pop(ctx);
                ctx.push(AppRoutes.subscription);
              },
            ),
            const SizedBox(height: 12),
            GhostButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
            const SizedBox(height: 8),
          ],
        ),
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
            SnackBar(
              content: Text(
                state.error!.message,
                style: AppTextStyles.bodySM(color: AppColors.error),
              ),
            ),
          );
        }
      },
      child: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(), // manual control only
        onPageChanged: (i) => setState(() => _pageIndex = i),
        children: [
          // ── Page 0: Chat ──────────────────────────────
          Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.surface1,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              titleSpacing: 0,
              actions: [
                // 🏋️ Sesh Flash button in app bar
                GestureDetector(
                  onTap: _openCamera,
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0A84FF).withOpacity(0.3),
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/sesh_flash.png',
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ],
              title: GestureDetector(
                onTap: () => context.push(
                  AppRoutes.buddyProfile.replaceAll(':userId', widget.chatId),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      name: widget.buddyName,
                      imageUrl: widget.buddyAvatar,
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.buddyName, style: AppTextStyles.subtitle()),
                        BlocBuilder<ChatBloc, ChatState>(
                          builder: (_, state) => Text(
                            _isTyping ? 'typing...' : 'tap to view profile',
                            style: AppTextStyles.caption(
                              color: _isTyping
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            body: Column(
              children: [
                // Streak banner
                BlocBuilder<StrikeBloc, StrikeState>(
                  buildWhen: (p, c) => p.streak != c.streak,
                  builder: (_, st) {
                    if (st.streak <= 0) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _openCamera,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 16,
                        ),
                        color: const Color(0xFFF59E0B).withOpacity(0.08),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '${st.streak} day streak · Send a Strike to keep it!',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Image.asset(
                              'assets/images/sesh_flash.png',
                              width: 18,
                              height: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Message list
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state.isLoading && state.messages.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      final messages = state.messages;

                      // Scroll to bottom after fresh load
                      if (messages.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scroll.hasClients &&
                              _scroll.position.maxScrollExtent > 0 &&
                              _scroll.offset <
                                  _scroll.position.maxScrollExtent - 200) {
                            _scroll.jumpTo(_scroll.position.maxScrollExtent);
                          }
                        });
                      }

                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: messages.length + (_isTyping ? 1 : 0),
                        // Key each item by message ID so Flutter only rebuilds changed items
                        // This stops the full list rebuild (blink) when session invite responds
                        itemBuilder: (_, i) {
                          if (_isTyping && i == messages.length)
                            return _TypingBubble();

                          final msg = messages[i];
                          final isMe = msg.senderId == myId;
                          final showDate =
                              i == 0 ||
                              !_sameDay(
                                messages[i - 1].createdAt,
                                msg.createdAt,
                              );

                          return KeyedSubtree(
                            key: ValueKey(msg.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDate) _DateDivider(date: msg.createdAt),
                                _MessageBubble(msg: msg, isMe: isMe),
                              ],
                            ),
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
                    child: Row(
                      children: [
                        // 🏋️ Sesh Flash button
                        GestureDetector(
                          onTap: _openCamera,
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A84FF).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0A84FF).withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/sesh_flash.png',
                                width: 22,
                                height: 22,
                              ),
                            ),
                          ),
                        ),

                        // 📷 Gallery button
                        GestureDetector(
                          onTap: _pickFromGallery,
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Center(
                              child: Text('📷', style: TextStyle(fontSize: 15)),
                            ),
                          ),
                        ),

                        // Session shortcut
                        GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.scheduleSession,
                            extra: {
                              'buddyId': widget.buddyId,
                              'buddyName': widget.buddyName,
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Session',
                                  style: AppTextStyles.bodySM(
                                    color: AppColors.primary,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Text field
                        Expanded(
                          child: BlocBuilder<ChatBloc, ChatState>(
                            builder: (context, state) => TextField(
                              controller: _msgCtrl,
                              style: AppTextStyles.body(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Message ${widget.buddyName}...',
                                hintStyle: AppTextStyles.body(
                                  color: AppColors.textMuted,
                                ),
                                filled: true,
                                fillColor: AppColors.surface2,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (v) {
                                if (v.isEmpty) return;
                                _lastTyped = DateTime.now();
                                _socket?.emit('typing:start', {
                                  'chatId': widget.chatId,
                                });
                                // Auto-stop after 2 s of no keystrokes
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (DateTime.now()
                                          .difference(_lastTyped)
                                          .inSeconds >=
                                      2) {
                                    _socket?.emit('typing:stop', {
                                      'chatId': widget.chatId,
                                    });
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
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: state.isSending
                                    ? AppColors.surface3
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGlow,
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: state.isSending
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Page 1: Camera ────────────────────────────────
          BlocBuilder<StrikeBloc, StrikeState>(
            buildWhen: (p, c) => p.streak != c.streak,
            builder: (_, st) => _StrikeCameraScreen(
              buddyName: widget.buddyName,
              streak: st.streak,
              onClose: _closeCamera,
              onCapture: _showStrikePreview,
              onGallery: _pickFromGallery,
            ),
          ),
        ], // end PageView children
      ), // end PageView
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Message Bubble ────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isMe});

  final Message msg;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AppAvatar(
              name: msg.senderName,
              imageUrl: msg.senderAvatar,
              size: 28,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Session invite — NO bubble wrapper (buttons need direct taps)
                if (msg.type == 'session_invite')
                  _SessionInviteCard(msg: msg)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface2,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      msg.content,
                      style: isMe
                          ? AppTextStyles.body(color: Colors.black)
                          : AppTextStyles.body(),
                    ),
                  ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            : AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
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
  String? _respondedAction; // 'confirm' | 'decline' — after responding

  Future<void> _respond(String action) async {
    setState(() => _responding = true);
    try {
      final data = widget.msg.metadata ?? {};
      final sessionId = data['sessionId'] as String?;
      if (sessionId == null) return;
      await getIt<SessionRepository>().respondToSessionInvite(
        sessionId,
        action,
      );
      if (mounted) {
        setState(() {
          _responding = false;
          _respondedAction = action;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'confirm'
                  ? 'Session confirmed! 🤝'
                  : 'Session declined',
            ),
            backgroundColor: action == 'confirm'
                ? AppColors.teal
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _responding = false);
    }
  }

  // Activity emoji based on type
  String _activityEmoji(String activity) {
    const map = {
      'gym': '🏋️',
      'running': '🏃',
      'cycling': '🚴',
      'swimming': '🏊',
      'boxing': '🥊',
      'yoga': '🧘',
      'hiit': '💥',
      'crossfit': '🔥',
      'hyrox': '⚡',
    };
    return map[activity.toLowerCase()] ?? '💪';
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates this widget's repaints from parent ListView
    // This stops the screen blink when state changes
    return RepaintBoundary(child: _buildCard(context));
  }

  Widget _buildCard(BuildContext context) {
    final data = widget.msg.metadata ?? {};
    final activity = data['activity'] as String? ?? 'Workout';
    final scheduledAt = data['scheduledAt'] as String?;
    final endTimeStr = data['endTime'] as String?;
    final duration = data['durationMins'] as int? ?? 60;
    final gymName = data['gymName'] as String?;

    DateTime? dt;
    DateTime? endDt;
    if (scheduledAt != null) dt = DateTime.tryParse(scheduledAt);
    if (endTimeStr != null) endDt = DateTime.tryParse(endTimeStr);

    final dateStr = dt != null
        ? '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)} · ${_fmt12(dt)}'
        : '';
    final endTimeLabel = endDt != null ? 'ends ${_fmt12(endDt)}' : '';
    final durationStr = duration == 45
        ? '45 mins'
        : duration == 60
        ? '1 hour'
        : duration == 90
        ? '1.5 hours'
        : '2 hours';

    // State colors
    final isConfirmed = _respondedAction == 'confirm';
    final isDeclined = _respondedAction == 'decline';
    final isPending = _respondedAction == null;

    final headerBg = isConfirmed
        ? AppColors.teal.withOpacity(0.1)
        : isDeclined
        ? AppColors.error.withOpacity(0.08)
        : AppColors.primary.withOpacity(0.1);

    final headerBorder = isConfirmed
        ? AppColors.teal.withOpacity(0.15)
        : isDeclined
        ? AppColors.error.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.15);

    final cardBorder = isConfirmed
        ? AppColors.teal.withOpacity(0.3)
        : isDeclined
        ? AppColors.error.withOpacity(0.25)
        : AppColors.border2;

    final headerColor = isConfirmed
        ? AppColors.teal
        : isDeclined
        ? AppColors.error
        : AppColors.primary;

    final headerLabel = isConfirmed
        ? 'Session Confirmed'
        : isDeclined
        ? 'Session Declined'
        : 'Session Invite';

    final headerIcon = isConfirmed
        ? '✅'
        : isDeclined
        ? '❌'
        : _activityEmoji(activity);

    return Opacity(
      opacity: isDeclined ? 0.85 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(bottom: BorderSide(color: headerBorder)),
              ),
              child: Row(
                children: [
                  Text(headerIcon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    headerLabel.toUpperCase(),
                    style: AppTextStyles.label(
                      color: headerColor,
                    ).copyWith(letterSpacing: 0.3),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Activity — capitalized, strikethrough if declined
                  Text(
                    _capitalize(activity),
                    style: AppTextStyles.subtitle().copyWith(
                      fontSize: 15,
                      decoration: isDeclined
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isDeclined
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date row
                  if (dateStr.isNotEmpty)
                    _InfoRow(
                      icon: Icons.calendar_today,
                      text: dateStr,
                      faded: isDeclined,
                    ),
                  const SizedBox(height: 3),

                  // Duration + end time
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    text: endTimeLabel.isNotEmpty
                        ? '$durationStr · $endTimeLabel'
                        : durationStr,
                    faded: isDeclined,
                  ),

                  // Gym
                  if (gymName != null) ...[
                    const SizedBox(height: 3),
                    _InfoRow(
                      icon: Icons.location_on,
                      text: gymName,
                      faded: isDeclined,
                    ),
                  ],

                  const SizedBox(height: 10),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),

                  // ── Pending: show buttons ───────────────
                  if (isPending)
                    _responding
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Material(
                                  color: AppColors.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: _responding
                                        ? null
                                        : () => _respond('decline'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.error.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Decline ✕',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodySM(
                                          color: AppColors.error,
                                        ).copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Material(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: _responding
                                        ? null
                                        : () => _respond('confirm'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.4,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Confirm ✓',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodySM(
                                          color: AppColors.primary,
                                        ).copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                  // ── Confirmed: status badge ─────────────
                  if (isConfirmed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.teal.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🤝', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session Confirmed!',
                                  style: AppTextStyles.subtitle(
                                    color: AppColors.teal,
                                  ),
                                ),
                                if (dateStr.isNotEmpty)
                                  Text(
                                    'See you on ${dateStr.split('·').first.trim()}',
                                    style: AppTextStyles.bodySM(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Declined: status badge ──────────────
                  if (isDeclined)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('😔', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Declined',
                                  style: AppTextStyles.subtitle(
                                    color: AppColors.error,
                                  ),
                                ),
                                Text(
                                  'This session was cancelled',
                                  style: AppTextStyles.bodySM(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  String _weekday(int w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  String _month(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _fmt12(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? "PM" : "AM"}';
  }
}

// Info row helper
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.faded = false});

  final IconData icon;
  final String text;
  final bool faded;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 12,
        color: faded
            ? AppColors.textMuted.withOpacity(0.4)
            : AppColors.textMuted,
      ),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: AppTextStyles.bodySM(
            color: faded
                ? AppColors.textMuted.withOpacity(0.5)
                : AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
              3,
              (i) =>
                  Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(
                        onPlay: (c) => c.repeat(),
                        delay: Duration(milliseconds: i * 150),
                      )
                      .moveY(
                        begin: 0,
                        end: -4,
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .moveY(
                        begin: -4,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

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
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label, style: AppTextStyles.caption()),
          ),
          Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _StrikeCameraScreen — Page 1 of PageView (swipe up)
//  Snapchat-style full screen camera
// ─────────────────────────────────────────────────────────
class _StrikeCameraScreen extends StatelessWidget {
  const _StrikeCameraScreen({
    required this.buddyName,
    required this.streak,
    required this.onClose,
    required this.onCapture,
    required this.onGallery,
  });

  final String buddyName;
  final int streak;
  final VoidCallback onClose;
  final void Function(File) onCapture;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera viewfinder (placeholder — real camera uses camera package)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF07090F),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      'Camera ready',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close (swipe down hint)
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '✕',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),

                    // Buddy + streak info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Flash to $buddyName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (streak > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '🔥$streak',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Flip camera (placeholder)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '↺',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Swipe down hint
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      '↓',
                      style: TextStyle(color: Colors.white30, fontSize: 18),
                    ),
                    Text(
                      'Swipe down to close',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: onGallery,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Center(
                          child: Text('🖼️', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),

                    // Shutter button
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                        );
                        if (img != null) {
                          onCapture(File(img.path));
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 4,
                          ),
                        ),
                      ),
                    ),

                    // Flash toggle placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/sesh_flash.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _StrikePreviewSheet — Preview before sending
// ─────────────────────────────────────────────────────────
class _StrikePreviewSheet extends StatefulWidget {
  const _StrikePreviewSheet({
    required this.imageFile,
    required this.buddyName,
    required this.matchId,
    required this.receiverId,
    required this.onSent,
    this.streak = 0,
  });

  final File imageFile;
  final String buddyName;
  final String matchId;
  final String receiverId;
  final VoidCallback onSent;
  final int streak;

  @override
  State<_StrikePreviewSheet> createState() => _StrikePreviewSheetState();
}

class _StrikePreviewSheetState extends State<_StrikePreviewSheet> {
  final _captionCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      // Dispatch to StrikeBloc — handles upload + send
      context.read<StrikeBloc>().add(
        StrikeSendRequested(
          matchId: widget.matchId,
          receiverId: widget.receiverId,
          imageFile: widget.imageFile,
          caption: _captionCtrl.text.trim().isNotEmpty
              ? _captionCtrl.text.trim()
              : null,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSent();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sesh Flash sent to ${widget.buddyName}! 🏋️'),
          backgroundColor: const Color(0xFF0A84FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send strike. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF07090F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white54,
                    size: 28,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Send Strike to ${widget.buddyName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.streak > 0)
                        Text(
                          '🔥 ${widget.streak} day streak',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),

          // Image preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(widget.imageFile, fit: BoxFit.cover),
                    // Disappear badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A84FF).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          '🏋️ Disappears after viewing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Caption + send
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _captionCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _sending
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFF0A84FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send Flash',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
