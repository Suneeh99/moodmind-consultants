import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'chat_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/mood_stats_service.dart';
import 'package:moodmind_consultant_app/screens/stats/statistics_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // Formats relative time for last message
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Color strip based on avg mood
  Color _getMoodColor(double? averageMood) {
    if (averageMood == null || averageMood == 0) return Colors.grey;
    if (averageMood < 2) return Colors.red;
    if (averageMood < 3) return Colors.orange;
    if (averageMood < 4) return Colors.amber;
    return Colors.green;
  }

  // Try multiple fields to resolve a display name; fallback to email username or chat envelope hint.
  String _resolveDisplayName(
    Map<String, dynamic>? userData, {
    Map<String, dynamic>? chatData,
  }) {
    // From user doc
    final displayName = (userData?['displayName'] as String?)?.trim();
    final name = (userData?['name'] as String?)?.trim();
    final fullName = (userData?['fullName'] as String?)?.trim();

    String? firstLast;
    if ((userData?['firstName'] != null) || (userData?['lastName'] != null)) {
      final first = (userData?['firstName'] ?? '').toString().trim();
      final last = (userData?['lastName'] ?? '').toString().trim();
      final combo = '$first $last'.trim();
      if (combo.isNotEmpty) firstLast = combo;
    }

    String? emailUser;
    final email = userData?['email'] as String?;
    if (email != null && email.contains('@')) {
      emailUser = email.split('@').first.trim();
    }

    // From chat envelope as a last hint
    final envelopeName = (chatData?['patientName'] as String?)?.trim();

    return [
      displayName,
      name,
      fullName,
      firstLast,
      emailUser,
      envelopeName,
    ].firstWhere((v) => v != null && v.isNotEmpty, orElse: () => 'Patient')!;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final svc = context.read<FirestoreService>();
    final moodStatsService = MoodStatsService.instance;
    final myId = auth.user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: svc.myChats(myId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No active chats yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final chat = docs[i];
              final data = chat.data();

              // Find the patient in participants (the one who is not me)
              final participants =
                  (data['participants'] as List<dynamic>?) ?? const [];
              final patientId = participants.cast<String>().firstWhere(
                (id) => id != myId,
                orElse: () => '',
              );

              final lastMsg = (data['lastMessage'] as String?) ?? '';
              final ts =
                  (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                  (data['updatedAt'] as Timestamp?)?.toDate();

              if (patientId.isEmpty) {
                // No valid patient — skip rendering this tile
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: svc.userDoc(patientId),
                builder: (context, userSnap) {
                  final userData = userSnap.data?.data();
                  final displayName = _resolveDisplayName(
                    userData,
                    chatData: data,
                  );

                  return FutureBuilder<MoodStatsData>(
                    future: moodStatsService.fetchStats(
                      userId: patientId,
                      days: 7,
                    ),
                    builder: (context, statsSnap) {
                      final moodData = statsSnap.data;
                      final moodColor = _getMoodColor(moodData?.average);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chat.id,
                                  patientId: patientId,
                                  patientName: displayName,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Mood indicator strip
                                Container(
                                  width: 10,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: moodColor,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Chat info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTime(ts),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMsg.isNotEmpty
                                            ? lastMsg
                                            : 'No messages yet',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (moodData != null &&
                                          moodData.total > 0) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.emoji_emotions_outlined,
                                              size: 14,
                                              color: moodColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Avg. Mood: ${moodData.average.toStringAsFixed(1)}/5.0',
                                              style: TextStyle(
                                                color: moodColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${moodData.total} entries',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'See mood details',
                                              icon: const Icon(
                                                Icons.insights_outlined,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        StatisticsScreen(
                                                          patientId: patientId,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
