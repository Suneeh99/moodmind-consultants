class MoodEntry {
  final String id;
  final String mood;
  final String? note;
  final DateTime? timestamp;
  final String dominantEmotion;
  final Map<String, double> sentimentAnalysis;
  final double confidenceScore;

  MoodEntry({
    required this.id,
    required this.mood,
    this.note,
    this.timestamp,
    this.dominantEmotion = 'undefined',
    this.sentimentAnalysis = const {},
    this.confidenceScore = 0.0,
  });

  factory MoodEntry.fromMap(String id, Map<String, dynamic> data) {
    return MoodEntry(
      id: id,
      mood: (data['mood'] ?? '') as String,
      note: data['note'] as String?,
      timestamp: (data['timestamp'] as dynamic)?.toDate(),
      dominantEmotion: (data['dominantEmotion'] ?? 'undefined') as String,
      sentimentAnalysis: Map<String, double>.from(
        data['sentimentAnalysis'] ?? {},
      ),
      confidenceScore: (data['confidenceScore'] ?? 0.0) as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mood': mood,
      'note': note,
      'timestamp': timestamp,
      'dominantEmotion': dominantEmotion,
      'sentimentAnalysis': sentimentAnalysis,
      'confidenceScore': confidenceScore,
    };
  }
}
