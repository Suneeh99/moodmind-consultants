import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodmind_consultant_app/models/mood_entry.dart';
import 'package:moodmind_consultant_app/services/firestore_service.dart';
import '../models/mood_statistics_model.dart';

class DiaryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'diary_entries';

  // Get diary entries for a date range
  static Future<List<MoodEntry>> getDiaryEntries({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    try {
      // Normalize dates
      final normalizedStartDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final normalizedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStartDate),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(normalizedEndDate),
          )
          .orderBy('date', descending: true)
          .get();

      final entries = querySnapshot.docs
          .map((doc) => MoodEntry.fromMap(doc.id, doc.data()))
          .toList();

      return entries;
    } catch (e) {
      return [];
    }
  }

  // Get mood statistics for different periods
  static Future<MoodStatisticsModel> getMoodStatistics(
    String period,
    String userId,
  ) async {
    DateTime endDate = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Today':
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        break;
      case 'This week':
        // Get start of current week (Monday)
        int daysFromMonday = endDate.weekday - 1;
        startDate = endDate.subtract(Duration(days: daysFromMonday));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        break;
      case 'This Month':
        startDate = DateTime(endDate.year, endDate.month, 1);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        break;
      default:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
    }

    final entries = await getDiaryEntries(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    return MoodStatisticsModel.fromEntries(entries, period, startDate, endDate);
  }

  // Get all diary entries for a user (for debugging)
  static Future<List<MoodEntry>> getAllUserEntries(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      final entries = querySnapshot.docs
          .map((doc) => MoodEntry.fromMap(doc.id, doc.data()))
          .toList();

      return entries;
    } catch (e) {
      print('Error getting all user entries: $e');
      return [];
    }
  }
}
