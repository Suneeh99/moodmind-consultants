import 'package:moodmind_consultant_app/models/mood_entry.dart';

class MoodStatisticsModel {
  final int totalEntries;
  final Map<String, double> emotionPercentages;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final String dominantMood;
  final double averageConfidence;

  MoodStatisticsModel({
    required this.totalEntries,
    required this.emotionPercentages,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.dominantMood,
    required this.averageConfidence,
  });

  factory MoodStatisticsModel.fromEntries(
    List<MoodEntry> entries,
    String period,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (entries.isEmpty) {
      return MoodStatisticsModel(
        totalEntries: 0,
        emotionPercentages: {},
        period: period,
        startDate: startDate,
        endDate: endDate,
        dominantMood: 'neutral',
        averageConfidence: 0.0,
      );
    }

    // Calculate weighted sentiment scores from all entries
    final aggregatedEmotions = <String, double>{
      'Joy': 0.0,
      'Sadness': 0.0,
      'Anger': 0.0,
      'Fear': 0.0,
      'Neutral': 0.0,
    };

    double totalConfidence = 0.0;
    int analyzedEntries = 0;

    // Process each entry's sentiment analysis
    for (final entry in entries) {
      if (entry.dominantEmotion != 'undefined' &&
          entry.sentimentAnalysis.isNotEmpty) {
        analyzedEntries++;
        totalConfidence += entry.confidenceScore;

        // Add weighted sentiment scores from this entry
        for (final emotion in entry.sentimentAnalysis.entries) {
          final emotionKey = _mapEmotionKey(emotion.key);
          if (aggregatedEmotions.containsKey(emotionKey)) {
            // Weight by confidence score for more accurate representation
            aggregatedEmotions[emotionKey] =
                aggregatedEmotions[emotionKey]! +
                (emotion.value * entry.confidenceScore);
          }
        }
      } else {
        // For undefined entries, add small neutral weight
        aggregatedEmotions['Neutral'] = aggregatedEmotions['Neutral']! + 0.1;
      }
    }

    // Normalize the aggregated emotions to percentages
    final totalEmotionScore = aggregatedEmotions.values.reduce((a, b) => a + b);
    if (totalEmotionScore > 0) {
      aggregatedEmotions.updateAll(
        (key, value) => (value / totalEmotionScore) * 100,
      );
    }

    // Find dominant mood from aggregated data
    String dominantMood = 'Neutral';
    double maxPercentage = 0.0;
    for (final entry in aggregatedEmotions.entries) {
      if (entry.value > maxPercentage) {
        maxPercentage = entry.value;
        dominantMood = entry.key;
      }
    }

    // Calculate average confidence
    final averageConfidence = analyzedEntries > 0
        ? totalConfidence / analyzedEntries
        : 0.0;

    print('Mood statistics calculated:');
    print('Total entries: ${entries.length}');
    print('Analyzed entries: $analyzedEntries');
    print('Aggregated emotions: $aggregatedEmotions');
    print(
      'Dominant mood: $dominantMood (${maxPercentage.toStringAsFixed(1)}%)',
    );

    return MoodStatisticsModel(
      totalEntries: entries.length,
      emotionPercentages: aggregatedEmotions,
      period: period,
      startDate: startDate,
      endDate: endDate,
      dominantMood: dominantMood,
      averageConfidence: averageConfidence,
    );
  }

  static String _mapEmotionKey(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happiness':
      case 'happy':
        return 'Joy';
      case 'sadness':
      case 'sad':
        return 'Sadness';
      case 'anger':
      case 'angry':
        return 'Anger';
      case 'fear':
      case 'anxiety':
      case 'anxious':
        return 'Fear';
      case 'neutral':
      case 'undefined':
      default:
        return 'Neutral';
    }
  }

  String getRiskLevel() {
    final negativeEmotions =
        (emotionPercentages['Sadness'] ?? 0.0) +
        (emotionPercentages['Anger'] ?? 0.0) +
        (emotionPercentages['Fear'] ?? 0.0);

    if (negativeEmotions > 60) {
      return 'high';
    } else if (negativeEmotions > 30) {
      return 'moderate';
    } else {
      return 'low';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'totalEntries': totalEntries,
      'emotionPercentages': emotionPercentages,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dominantMood': dominantMood,
      'averageConfidence': averageConfidence,
    };
  }

  factory MoodStatisticsModel.fromMap(Map<String, dynamic> map) {
    return MoodStatisticsModel(
      totalEntries: map['totalEntries'] ?? 0,
      emotionPercentages: Map<String, double>.from(
        map['emotionPercentages'] ?? {},
      ),
      period: map['period'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      dominantMood: map['dominantMood'] ?? 'neutral',
      averageConfidence: map['averageConfidence'] ?? 0.0,
    );
  }
}
