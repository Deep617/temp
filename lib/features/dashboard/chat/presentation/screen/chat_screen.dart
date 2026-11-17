import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seshlly/core/api/api_endpoints.dart';
import 'package:seshlly/core/api/dio_client.dart';
import 'package:seshlly/core/services/secure_storage_service.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/features/dashboard/session/data/repositories/session_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/errors/app_error.dart';
import '../../../../../core/widgets/camera/sesh_camera_view.dart';
import '../../../../safety/presentation/widgets/safety_sheet.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../session/presentation/widgets/proof_confirm_sheet.dart';
import '../../data/response_ml/message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/strike_bloc.dart';
import '../widgets/session_invite_status.dart';
import '../../../../../core/services/monitoring_service.dart';
import '../../../../../core/services/growth_service.dart';

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

  bool _showEmoji = false;

  // matchId is needed for Flash + streaks. Most routes into the chat don't
  // pass it (Flash used to be sent with the USER id → "match not found").
  String? _matchId;
  String _lastDraft = '';        // restored if sending fails
  int _shownCount = 0;           // auto-scroll only when NEW messages arrive
  Timer? _typingTimeout;         // hide "typing…" if typing:stop never comes
  Timer? _readDebounce;

  // Near the top → fetch the previous page and keep the view where it was
  double? _extentBeforeOlder;
  void _maybeLoadOlder() {
    if (!_scroll.hasClients || _scroll.position.pixels > 80) return;
    final bloc = context.read<ChatBloc>();
    if (!bloc.state.hasOlder || bloc.state.loadingOlder) return;
    _extentBeforeOlder = _scroll.position.maxScrollExtent;
    bloc.add(ChatOlderMessagesLoaded(chatId: widget.chatId));
  }

  Future<void> _resolveMatchId() async {
    if (_matchId != null || widget.buddyId.isEmpty) return;
    try {
      final res = await getIt<DioClient>().get('/chat/with/${widget.buddyId}');
      final id = ((res.data as Map)['data'] as Map)['matchId'] as String?;
      if (!mounted || id == null) return;
      setState(() => _matchId = id);
      _refreshStreak();
    } catch (_) {/* Flash stays disabled */}
  }

  @override
  void initState() {
    super.initState();
    _matchId = widget.matchId;
    _resolveMatchId();
    _scroll.addListener(_maybeLoadOlder);
    // Load messages via BLoC
    context.read<ChatBloc>().add(ChatMessagesLoaded(chatId: widget.chatId));
    context.read<ChatBloc>().add(ChatMarkedRead(chatId: widget.chatId));

    // Load strike streak + pending count via BLoC
    if (_matchId != null) {
      context.read<StrikeBloc>().add(
        StrikeLoadRequested(matchId: _matchId!, buddyId: widget.buddyId),
      );
    }

    _initSocket();
  }

  @override
  void dispose() {
    _socket?.emit('chat:leave', {'chatId': widget.chatId});
    _typingTimeout?.cancel();
    _readDebounce?.cancel();
    // remove listeners + free the socket (old screens' handlers leaked before)
    _socket?.clearListeners();
    _socket?.dispose();
    _msgCtrl.dispose();
    _scroll.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // Refresh strike streak via BLoC
  void _refreshStreak() {
    if (_matchId == null) return;
    context.read<StrikeBloc>().add(
      StrikeLoadRequested(matchId: _matchId!, buddyId: widget.buddyId),
    );
  }

  // Open camera → dispatch to StrikeBloc + animate PageView
// AFTER — permission check add kiya:
  /// Group session chats have no single buddy (no Flash / profile / block)
  bool get _isGroup => widget.buddyId.isEmpty;

  Future<void> _openCamera() async {
    if (_isGroup) return;
    // Permission check
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isDenied || status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission required for Sesh Flash'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surface3,
        ),
      );
      return;
    }

    // Permission granted → open camera
    context.read<StrikeBloc>().add(const StrikeCameraOpened());
    _pageCtrl.animateToPage(1,
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
    if (_matchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not load this buddy yet — try again in a moment'),
        behavior: SnackBarBehavior.floating,
      ));
      _resolveMatchId();
      return;
    }
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
          matchId: _matchId ?? '',
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
            .enableForceNew() // own connection per chat screen (no stale handlers)
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
          // I'm looking at it → mark read (debounced) so badges clear
          _readDebounce?.cancel();
          _readDebounce = Timer(const Duration(seconds: 1), () {
            if (mounted) context.read<ChatBloc>().add(ChatMarkedRead(chatId: widget.chatId));
          });
        }
      });

      // A card changed on the server (invite answered / expired, proof confirmed)
      _socket!.on('message:updated', (data) {
        if (!mounted || data is! Map) return;
        if (data['chatId'] != widget.chatId || data['id'] == null) return;
        final meta = data['metadata'];
        context.read<ChatBloc>().add(ChatMessageUpdated(
          messageId: data['id'] as String,
          metadata: meta is Map ? Map<String, dynamic>.from(meta) : null,
        ));
      });

      // Other user switched 24h / Normal mode
      _socket!.on('chat:mode', (data) {
        if (!mounted || data is! Map) return;
        if (data['chatId'] != widget.chatId) return;
        context.read<ChatBloc>().add(ChatModeReceived(
          chatId: widget.chatId,
          disappearing: data['disappearing'] == true,
        ));
      });

      _socket!.on('typing:start', (_) {
        if (!mounted) return;
        setState(() => _isTyping = true);
        // If the buddy leaves mid-typing, typing:stop never arrives
        _typingTimeout?.cancel();
        _typingTimeout = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _isTyping = false);
        });
      });
      _socket!.on('typing:stop', (_) {
        _typingTimeout?.cancel();
        if (mounted) setState(() => _isTyping = false);
      });
    }); // end storage.read().then()
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _lastDraft = text; // put back if the send fails (no tokens / offline)
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
        if (_lastDraft.isNotEmpty && _msgCtrl.text.isEmpty) {
          _msgCtrl.text = _lastDraft;
          _lastDraft = '';
        }
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
      // Android back on the Flash camera page closes the camera instead of
      // leaving the whole chat
      child: PopScope(
        canPop: _pageIndex == 0,
        onPopInvoked: (didPop) {
          if (!didPop && _pageIndex != 0) _closeCamera();
        },
        child: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(), // manual control only
        onPageChanged: (i) => setState(() => _pageIndex = i),
        children: [
          // ── Page 0: Chat ──────────────────────────────
          PopScope(
            // Back: close emoji first. (The camera page is handled by the
            // PopScope around the whole PageView below.)
            canPop: !_showEmoji,
            onPopInvoked: (didPop) {
              if (!didPop && _showEmoji) {
                setState(() => _showEmoji = false);
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
                actions: [
                  // 24h / Normal messages — the dotted-circle "disappearing
                  // messages" icon (the stopwatch read as a workout timer)
                  BlocBuilder<ChatBloc, ChatState>(
                    buildWhen: (p, c) => p.disappearing != c.disappearing,
                    builder: (_, cs) => IconButton(
                      key: const ValueKey('chat-mode-button'),
                      tooltip: cs.disappearing
                          ? 'Disappearing messages: 24 hours'
                          : 'Disappearing messages: off',
                      onPressed: () => _showModeSheet(cs.disappearing),
                      icon: Icon(
                        Icons.history_toggle_off_rounded,
                        color: cs.disappearing
                            ? AppColors.teal
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  // 🏋️ Sesh Flash button in app bar (1:1 chats only)
                  if (!_isGroup)
                  GestureDetector(
                    onTap: _openCamera,
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
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
                  // ⋮ Report / Block
                  if (!_isGroup)
                  SafetyMenuButton(
                    userId: widget.buddyId,
                    name: widget.buddyName,
                    source: 'chat',
                    onBlocked: () {
                      if (mounted) context.pop();
                    },
                  ),
                ],
                title: GestureDetector(
                  // Was passing the CHAT id as the user id → profile never loaded
                  onTap: _isGroup
                      ? null
                      : () => context.push(
                            AppRoutes.buddyProfile.replaceAll(':userId', widget.buddyId),
                            extra: {'chatId': widget.chatId},
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
                  // ⏱ 24h mode banner
                  BlocBuilder<ChatBloc, ChatState>(
                    buildWhen: (p, c) => p.disappearing != c.disappearing,
                    builder: (_, cs) {
                      if (!cs.disappearing) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => _showModeSheet(true),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 16,
                          ),
                          color: AppColors.teal.withOpacity(0.10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_toggle_off_rounded,
                                  size: 14, color: AppColors.teal),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Messages disappear after 24 hours',
                                  style: AppTextStyles.caption(
                                    color: AppColors.teal,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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

                        // Scroll to bottom only when messages were ADDED
                        // (it used to yank the user down on every rebuild —
                        // typing indicator, card updates — while reading history)
                        // Older page was prepended → stay on the same message
                        if (_extentBeforeOlder != null && !state.loadingOlder &&
                            messages.length > _shownCount) {
                          final before = _extentBeforeOlder!;
                          _extentBeforeOlder = null;
                          _shownCount = messages.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_scroll.hasClients) return;
                            final pos = _scroll.position;
                            _scroll.jumpTo(pos.pixels + (pos.maxScrollExtent - before));
                          });
                        } else if (messages.length > _shownCount) {
                          final firstLoad = _shownCount == 0;
                          if (!firstLoad) _lastDraft = ''; // send went through
                          _shownCount = messages.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_scroll.hasClients) return;
                            final pos = _scroll.position;
                            final nearBottom = pos.maxScrollExtent - pos.pixels < 300;
                            if (firstLoad || nearBottom) {
                              _scroll.jumpTo(pos.maxScrollExtent);
                            }
                          });
                        } else if (messages.length < _shownCount) {
                          _shownCount = messages.length;
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
                                  if (msg.type == 'system')
                                    _SystemMessage(msg: msg)
                                  else
                                    _MessageBubble(
                                      msg: msg,
                                      isMe: isMe,
                                      myId: myId,
                                      buddyName: widget.buddyName,
                                    ),
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
                      child: BlocBuilder<ChatBloc, ChatState>(
                        builder: (context, chatState) {
                          final hasText = _msgCtrl.text.trim().isNotEmpty;
                          return Row(
                            children: [
                              // LEFT — 📷 Camera (feed/gallery ke liye)
                              GestureDetector(
                                onTap: _pickFromGallery,
                                child: Container(
                                  width: 38, height: 38,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.12)),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                ),
                              ),

                              // MIDDLE — Text field with emoji suffix
                              Expanded(
                                child: TextField(
                                  controller: _msgCtrl,
                                  style: AppTextStyles.body(color: AppColors.textPrimary),
                                  maxLines: 4,
                                  minLines: 1,
                                  onTap: () {
                                    // Keyboard opens → close emoji panel
                                    if (_showEmoji) {
                                      setState(() => _showEmoji = false);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Message ${widget.buddyName}...',
                                    hintStyle: AppTextStyles.body(color: AppColors.textMuted),
                                    filled: true,
                                    fillColor: AppColors.surface2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                          _showEmoji
                                              ? Icons.keyboard_outlined
                                              : Icons.emoji_emotions_outlined,
                                          color: _showEmoji
                                              ? AppColors.primary
                                              : AppColors.textMuted,
                                          size: 20),
                                      onPressed: () {
                                        FocusScope.of(context).unfocus();
                                        setState(() => _showEmoji = !_showEmoji);
                                      },
                                    ),
                                  ),
                                  onChanged: (v) {
                                    setState(() {}); // hasText rebuild ke liye
                                    if (v.isEmpty) return;
                                    _lastTyped = DateTime.now();
                                    _socket?.emit('typing:start', {'chatId': widget.chatId});
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (DateTime.now()
                                          .difference(_lastTyped).inSeconds >= 2) {
                                        _socket?.emit('typing:stop', {'chatId': widget.chatId});
                                      }
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(width: 8),

                              // RIGHT — Sesh Flash (no text) OR Send (has text)
                              (hasText || _isGroup)
                                  ? GestureDetector(
                                onTap: chatState.isSending ? null : _send,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: chatState.isSending
                                        ? AppColors.surface3
                                        : AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(
                                        color: AppColors.primaryGlow, blurRadius: 12)],
                                  ),
                                  child: chatState.isSending
                                      ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black),
                                  )
                                      : const Icon(Icons.send_rounded,
                                      color: Colors.black, size: 20),
                                ),
                              )
                                  : GestureDetector(
                                onTap: _openCamera,
                                child: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/sesh_flash.png',
                                      width: 22, height: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (_showEmoji)
                    SizedBox(
                      height: 280,
                      child: EmojiPicker(
                        // Picker inserts/deletes in _msgCtrl itself (cursor-aware).
                        // Callbacks only rebuild so Send/Flash button toggles.
                        textEditingController: _msgCtrl,
                        onEmojiSelected: (_, __) => setState(() {}),
                        onBackspacePressed: () => setState(() {}),
                        config: Config(
                          height: 280,
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: AppColors.surface1,
                            emojiSizeMax: 28,
                            noRecents: Text(
                              'No recents',
                              style: AppTextStyles.bodySM(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          categoryViewConfig: const CategoryViewConfig(
                            backgroundColor: AppColors.surface2,
                            indicatorColor: AppColors.primary,
                            iconColor: AppColors.textMuted,
                            iconColorSelected: AppColors.primary,
                            backspaceColor: AppColors.primary,
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            backgroundColor: AppColors.surface2,
                            buttonColor: AppColors.surface2,
                            buttonIconColor: AppColors.textMuted,
                          ),
                          searchViewConfig: const SearchViewConfig(
                            backgroundColor: AppColors.surface1,
                            buttonIconColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ── Page 1: Camera ────────────────────────────────
          BlocBuilder<StrikeBloc, StrikeState>(
            buildWhen: (p, c) => p.streak != c.streak,
            builder: (_, st) => SeshCameraView(
              active: _pageIndex == 1,
              title: 'Flash to ${widget.buddyName}',
              badge: st.streak > 0 ? '🔥${st.streak}' : null,
              onClose: _closeCamera,
              onCapture: (file) {
                _closeCamera();
                _showStrikePreview(file);
              },
              onGallery: _pickFromGallery,
            ),
          ),
        ], // end PageView children
      ), // end PageView
      ), // end PopScope
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ⏱ Choose 24h / Normal
  void _showModeSheet(bool current) {
    final chatBloc = context.read<ChatBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Disappearing messages', style: AppTextStyles.h3()),
              const SizedBox(height: 4),
              Text(
                'Applies to new messages only. Both of you will see the change.',
                style: AppTextStyles.bodySM(),
              ),
              const SizedBox(height: 14),
              _ModeOption(
                icon: Icons.chat_bubble_outline,
                title: 'Normal',
                subtitle: 'Messages are kept',
                selected: !current,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (current) {
                    MonitoringService.instance.log('chat_mode', {'mode': 'normal'});
                    chatBloc.add(ChatModeChanged(
                        chatId: widget.chatId, disappearing: false));
                  }
                },
              ),
              const SizedBox(height: 8),
              _ModeOption(
                icon: Icons.history_toggle_off_rounded,
                title: '24 hours',
                subtitle: 'New messages disappear after 24 hours',
                selected: current,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (!current) {
                    MonitoringService.instance.log('chat_mode', {'mode': '24h'});
                    chatBloc.add(ChatModeChanged(
                        chatId: widget.chatId, disappearing: true));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: selected ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle(
                    color: AppColors.textPrimary)),
                Text(subtitle, style: AppTextStyles.caption()),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.textMuted,
          ),
        ],
      ),
    ),
  );
}

// ── System message ("⏱ Rahul turned on 24h messages") ─────
class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.msg});

  final Message msg;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          msg.content,
          style: AppTextStyles.caption(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

// ── Proof card (buddy session) — one-tap confirm ───────────
// metadata: { sessionId, imageUrl, activity, uploaderId, confirmerId,
//             deadline, potentialXp, status: pending|confirmed|expired }
class _ProofCard extends StatefulWidget {
  const _ProofCard({
    required this.msg,
    required this.isMe,
    required this.myId,
    required this.buddyName,
  });

  final Message msg;
  final bool isMe;
  final String myId;
  final String buddyName;

  @override
  State<_ProofCard> createState() => _ProofCardState();
}

class _ProofCardState extends State<_ProofCard> {
  Timer? _ticker;
  bool _confirming = false;
  String? _localStatus; // after confirming here

  Map<String, dynamic> get _meta => widget.msg.metadata ?? const {};

  DateTime? get _deadline =>
      DateTime.tryParse(_meta['deadline']?.toString() ?? '')?.toLocal();

  String get _status {
    if (_localStatus != null) return _localStatus!;
    final s = _meta['status']?.toString() ?? 'pending';
    if (s == 'pending' &&
        _deadline != null &&
        _deadline!.isBefore(DateTime.now())) {
      return 'expired';
    }
    return s;
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirm() async {
    final sessionId = _meta['sessionId']?.toString();
    if (sessionId == null || _confirming) return;
    setState(() => _confirming = true);
    try {
      await getIt<SessionRepository>().confirmProof(sessionId);
      MonitoringService.instance.log('proof_confirmed', {'source': 'chat_card'});
      GrowthService.instance.onSessionCompleted();
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _localStatus = 'confirmed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Confirmed! +${_meta['potentialXp'] ?? ''} XP'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              e is AppError ? e.message : AppError.fromException(e).message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _meta['imageUrl']?.toString();
    final status = _status;
    final iConfirm = _meta['confirmerId']?.toString() == widget.myId;
    final left = _deadline?.difference(DateTime.now()) ?? Duration.zero;
    final urgent = left.inMinutes < 15;
    final xp = _meta['potentialXp'];

    String footer;
    Color footerColor;
    switch (status) {
      case 'confirmed':
        footer = '✅ Confirmed';
        footerColor = AppColors.teal;
        break;
      case 'expired':
        footer = '⌛ Not confirmed in time';
        footerColor = AppColors.textMuted;
        break;
      default:
        footer = iConfirm
            ? '⏳ ${formatTimeLeft(left)} left${xp != null ? ' · +$xp XP' : ''}'
            : '⏳ Waiting for ${widget.buddyName} to confirm · ${formatTimeLeft(left)} left';
        footerColor = urgent ? AppColors.error : AppColors.warning;
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? AppColors.warning.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl != null)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.surface3),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              '📸 ${_meta['activity'] ?? 'Session'} proof',
              style: AppTextStyles.subtitle(color: AppColors.textPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              footer,
              style: AppTextStyles.caption(color: footerColor)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (status == 'pending' && iConfirm)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: PrimaryButton(
                label: '✅ Confirm',
                loading: _confirming,
                onPressed: _confirming ? null : _confirm,
                height: 40,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    this.myId = '',
    this.buddyName = '',
  });

  final Message msg;
  final bool isMe;
  final String myId;
  final String buddyName;

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
                  _SessionInviteCard(msg: msg, buddyName: buddyName)
                else if (msg.type == 'proof' && msg.metadata != null)
                  _ProofCard(
                    msg: msg,
                    isMe: isMe,
                    myId: myId,
                    buddyName: buddyName,
                  )
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
  const _SessionInviteCard({required this.msg, this.buddyName = ''});

  final Message msg;
  final String buddyName; // the other person in this 1:1 chat

  @override
  State<_SessionInviteCard> createState() => _SessionInviteCardState();
}

class _SessionInviteCardState extends State<_SessionInviteCard> {
  bool _responding = false;
  String? _respondedAction; // 'confirm' | 'decline' | 'expired' — after responding

  Future<void> _respond(String action) async {
    final data = widget.msg.metadata ?? {};
    final sessionId = data['sessionId'] as String?;
    if (sessionId == null) return;
    setState(() => _responding = true);
    try {
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
    } catch (e) {
      if (!mounted) return;
      final err = e is AppError ? e : AppError.fromException(e);
      final st = statusFromRespondError(err.statusCode, null);
      setState(() {
        _responding = false;
        if (st == InviteCardStatus.expired && err.statusCode == 410) {
          _respondedAction = 'expired';
        }
      });
      // 409 = already answered (maybe on another device) → reload real state
      if (err.statusCode == 409) {
        context.read<ChatBloc>().add(ChatMessagesLoaded(chatId: widget.msg.chatId));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final data        = widget.msg.metadata ?? {};
    final activity    = data['activity']    as String? ?? 'Workout';
    final scheduledAt = data['scheduledAt'] as String?;
    final endTimeStr  = data['endTime']     as String?;
    final duration    = data['durationMins'] as int?   ?? 60;
    final gymName     = data['gymName']     as String?;

    // ── isScheduler check — sirf receiver ko buttons dikhenge ──
    final myId        = context.read<AuthBloc>().state.user?.id ?? '';
    final scheduledBy =  widget.msg.senderId;

    final isScheduler = scheduledBy == myId;

    // Server sends UTC — always show the phone's local time
    DateTime? dt;
    DateTime? endDt;
    if (scheduledAt != null) dt    = DateTime.tryParse(scheduledAt)?.toLocal();
    if (endTimeStr  != null) endDt = DateTime.tryParse(endTimeStr)?.toLocal();

    final dateStr = dt != null
        ? '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)} · ${_fmt12(dt)}'
        : '';
    final endTimeLabel = endDt != null ? 'ends ${_fmt12(endDt)}' : '';
    final durationStr  = duration == 45
        ? '45 mins'
        : duration == 60
        ? '1 hour'
        : duration == 90
        ? '1.5 hours'
        : '2 hours';

    // State comes from the server card + time (see session_invite_status.dart)
    final cardStatus = resolveInviteStatus(
      metadata:    widget.msg.metadata,
      myId:        myId,
      isScheduler: isScheduler,
      localAction: _respondedAction,
    );
    final isConfirmed = cardStatus == InviteCardStatus.confirmed;
    final isDeclined  = cardStatus == InviteCardStatus.declined;
    final isExpired   = cardStatus == InviteCardStatus.expired;
    final isPending   = cardStatus == InviteCardStatus.pending;

    final headerBg = isConfirmed
        ? AppColors.teal.withOpacity(0.1)
        : isDeclined
        ? AppColors.error.withOpacity(0.08)
        : isExpired
        ? AppColors.surface3
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
        : isExpired
        ? AppColors.textMuted
        : AppColors.primary;

    final headerLabel = isConfirmed
        ? 'Session Confirmed'
        : isDeclined
        ? 'Session Declined'
        : isExpired
        ? 'Invite Expired'
        : 'Session Invite';

    final headerIcon = isConfirmed
        ? '✅'
        : isDeclined
        ? '❌'
        : isExpired
        ? '⌛'
        : _activityEmoji(activity);

    final otherName = widget.buddyName.trim().isNotEmpty
        ? widget.buddyName.trim().split(' ').first
        : 'your buddy';

    return Opacity(
      opacity: (isDeclined || isExpired) ? 0.85 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color:        AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: cardBorder, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:  headerBg,
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
                mainAxisSize:       MainAxisSize.min,
                children: [
                  // Activity
                  Text(
                    _capitalize(activity),
                    style: AppTextStyles.subtitle().copyWith(
                      fontSize:   15,
                      decoration: (isDeclined || isExpired)
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
                      icon:  Icons.calendar_today,
                      text:  dateStr,
                      faded: isDeclined,
                    ),
                  const SizedBox(height: 3),

                  // Duration + end time
                  _InfoRow(
                    icon:  Icons.timer_outlined,
                    text:  endTimeLabel.isNotEmpty
                        ? '$durationStr · $endTimeLabel'
                        : durationStr,
                    faded: isDeclined,
                  ),

                  // Gym
                  if (gymName != null) ...[
                    const SizedBox(height: 3),
                    _InfoRow(
                      icon:  Icons.location_on,
                      text:  gymName,
                      faded: isDeclined,
                    ),
                  ],

                  const SizedBox(height: 10),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),

                  // ── Pending state ───────────────────────
                  if (isPending) ...[
                    // SCHEDULER — waiting for buddy to confirm
                    if (isScheduler)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface3,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                           /* const SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),*/
                            Text(
                              'Waiting for $otherName to confirm…',
                              style: AppTextStyles.bodySM(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )

                    // RECEIVER — show confirm/decline buttons
                    else if (_responding)
                      const Center(
                        child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          // Decline
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
                                      vertical: 9),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.error.withOpacity(0.3)),
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
                          // Confirm
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
                                      vertical: 9),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color:
                                        AppColors.primary.withOpacity(0.4)),
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
                  ],

                  // ── Confirmed badge ─────────────────────
                  if (isConfirmed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border:
                        Border.all(color: AppColors.teal.withOpacity(0.2)),
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
                                      color: AppColors.teal),
                                ),
                                if (dateStr.isNotEmpty)
                                  Text(
                                    'See you on ${dateStr.split('·').first.trim()}',
                                    style: AppTextStyles.bodySM(
                                        color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Declined badge ──────────────────────
                  if (isDeclined)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.15)),
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
                                      color: AppColors.error),
                                ),
                                Text(
                                  'This session was cancelled',
                                  style: AppTextStyles.bodySM(
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Expired badge (start time passed, nobody answered) ──
                  if (isExpired)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Text('⌛', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite expired',
                                  style: AppTextStyles.subtitle(
                                      color: AppColors.textMuted),
                                ),
                                Text(
                                  isScheduler
                                      ? 'Not confirmed before the start time'
                                      : 'The session time has passed',
                                  style: AppTextStyles.bodySM(
                                      color: AppColors.textMuted),
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

    final bloc = context.read<StrikeBloc>();
    final messenger = ScaffoldMessenger.of(context);

    // Wait for the BLoC result (upload → /strikes → /flash/send)
    final resultFuture = bloc.stream.firstWhere(
      (s) =>
          s.status == StrikeStatus.sent ||
          (s.status == StrikeStatus.photoPreview && s.errorMessage != null),
    );

    bloc.add(
      StrikeSendRequested(
        matchId: widget.matchId,
        receiverId: widget.receiverId,
        imageFile: widget.imageFile,
        caption: _captionCtrl.text.trim().isNotEmpty
            ? _captionCtrl.text.trim()
            : null,
      ),
    );

    final result = await resultFuture;
    if (!mounted) return;

    if (result.status == StrikeStatus.sent) {
      MonitoringService.instance.log('flash_sent');
      Navigator.of(context).pop();
      widget.onSent();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sesh Flash sent to ${widget.buddyName}! 🏋️'),
          backgroundColor: const Color(0xFF0A84FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not send strike. Try again.'),
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
