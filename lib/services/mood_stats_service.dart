import 'package:cloud_firestore/cloud_firestore.dart';

class MoodStatsData {
  final Map<int, int> counts; // mood 1..5 -> count
  final int total;
  final double average; // 1..5

  const MoodStatsData({
    required this.counts,
    required this.total,
    required this.average,
  });
}

class MoodStatsService {
  MoodStatsService._();
  static final MoodStatsService instance = MoodStatsService._();

  final _db = FirebaseFirestore.instance;

  /// Fetch last [days] days of mood entries for a user and aggregate.
  /// Tries root `diary_entries`, falls back to `users/{id}/diary_entries`.
  Future<MoodStatsData> fetchStats({
    required String userId,
    int days = 30,
  }) async {
    final from = DateTime.now().subtract(Duration(days: days));

    // Preferred: root collection
    final root = await _db
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .get();

    QuerySnapshot<Map<String, dynamic>> snap = root;

    if (root.docs.isEmpty) {
      // Fallback: users/{id}/diary_entries
      snap = await _db
          .collection('users')
          .doc(userId)
          .collection('diary_entries')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .get();
    }

    final counts = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
    var total = 0;
    var weighted = 0;

    for (final d in snap.docs) {
      final moodRaw = d.data()['mood'];
      int? mood;
      if (moodRaw is int) {
        mood = moodRaw;
      } else if (moodRaw is String) {
        mood = int.tryParse(moodRaw);
      }

      if (mood != null && mood >= 1 && mood <= 5) {
        counts[mood] = (counts[mood] ?? 0) + 1;
        total += 1;
        weighted += mood;
      }
    }

    final avg = total == 0 ? 0.0 : weighted / total;
    return MoodStatsData(counts: counts, total: total, average: avg);
  }
}
