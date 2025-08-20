import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moodmind_consultant_app/screens/stats/statistics_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String patientId;
  final String patientName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController textC = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final String _me; // consultantId
  late final String _patientId;
  late final String _chatId;
  late final FirestoreService svc;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    svc = context.read<FirestoreService>();
    _me = auth.user!.uid;
    _patientId = widget.patientId;
    _chatId = widget.chatId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await svc.markChatSeenForConsultant(chatId: _chatId, consultantId: _me);
      _focusNode.addListener(_onFocusChange);
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollCtrl.dispose();
    textC.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) return DateFormat('MMM d, yyyy').format(time);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _sendMessage() async {
    final text = textC.text.trim();
    if (text.isEmpty) return;
    try {
      await svc.sendMessage(
        chatId: _chatId,
        senderId: _me,
        text: text,
        isConsultant: true, // consultant app
      );
      textC.clear();
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  bool _closeInTime(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ta = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final tb = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return tb.difference(ta).inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    final headerGradient = const LinearGradient(
      colors: [Color(0xFF667eea), Color(0xFFf093fb)],
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: headerGradient),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.patientName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mood stats',
              icon: const Icon(Icons.insights_outlined, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StatisticsScreen(patientId: widget.patientId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: svc.chatMessages(widget.chatId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                // Auto-scroll & mark seen on each update
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent + 120,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                  await svc.markChatSeenForConsultant(
                    chatId: _chatId,
                    consultantId: _me,
                  );
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final cur = docs[i].data();
                    final prev = i > 0 ? docs[i - 1].data() : null;
                    final next = i + 1 < docs.length
                        ? docs[i + 1].data()
                        : null;

                    final isMe = cur['senderId'] == _me;
                    final prevSame =
                        prev != null &&
                        prev['senderId'] == cur['senderId'] &&
                        _closeInTime(prev, cur);
                    final nextSame =
                        next != null &&
                        next['senderId'] == cur['senderId'] &&
                        _closeInTime(next, cur);

                    final isFirst = !prevSame;
                    final isLast = !nextSame;

                    final ts = (cur['createdAt'] as Timestamp?)?.toDate();
                    final text = (cur['text'] as String?) ?? '';
                    final isConsultant =
                        (cur['isConsultant'] as bool?) ?? false;
                    final seenBy = List<String>.from(
                      cur['seenBy'] ?? const <String>[],
                    );
                    final isFromPatient = !isConsultant;
                    final isSeen = isFromPatient || seenBy.contains(_patientId);

                    return _MessageBubble(
                      isMe: isMe,
                      isFirstInGroup: isFirst,
                      isLastInGroup: isLast,
                      text: text,
                      timeLabel: isLast ? _formatTime(ts) : null,
                      showStatus: isMe && isLast,
                      seen: isSeen,
                      isFromPatient: isFromPatient,
                    );
                  },
                );
              },
            ),
          ),

          // Composer
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textC,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SendButton(onTap: _sendMessage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFFf093fb)],
        ),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.send, color: Colors.blue),
        tooltip: 'Send message',
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String text;
  final String? timeLabel;
  final bool showStatus;
  final bool seen;
  final bool showAvatar;
  final bool isFromPatient;

  const _MessageBubble({
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.text,
    this.timeLabel,
    this.showStatus = false,
    this.seen = false,
    this.showAvatar = false,
    this.isFromPatient = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final radiusTop = Radius.circular(isFirstInGroup ? 18 : 8);
    final radiusBottom = Radius.circular(isLastInGroup ? 18 : 8);

    final borderRadius = isMe
        ? BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: radiusTop,
            bottomLeft: const Radius.circular(18),
            bottomRight: radiusBottom,
          )
        : BorderRadius.only(
            topRight: const Radius.circular(18),
            topLeft: radiusTop,
            bottomRight: const Radius.circular(18),
            bottomLeft: radiusBottom,
          );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).primaryColor
            : (isFromPatient ? Colors.blue[50] : Colors.grey[100]),
        borderRadius: borderRadius,
        border: isFromPatient && !isMe
            ? Border.all(color: Colors.blue[200]!)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isMe
                  ? Colors.white
                  : (isFromPatient ? Colors.blue[900] : Colors.black87),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          if (timeLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              timeLabel!,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: bubble),
            if (isMe && showStatus)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Icon(
                  seen ? Icons.done_all_rounded : Icons.check_rounded,
                  size: 16,
                  color: seen ? Colors.lightBlueAccent : Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
