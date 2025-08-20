import 'package:flutter/material.dart';
import 'package:moodmind_consultant_app/models/mood_entry.dart';
import '../../widgets/mood_pie_chart.dart';
import '../../services/diary_service.dart';
import '../../models/mood_statistics_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key, required this.patientId}) : super(key: key);

  final String patientId;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'This week', 'This Month'];

  MoodStatisticsModel? _currentStats;
  List<MoodEntry> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      DateTime endDate = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
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
          final daysFromMonday = endDate.weekday - 1;
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

      final entries = await DiaryService.getDiaryEntries(
        startDate: startDate,
        endDate: endDate,
        userId: widget.patientId, // your service accepts userId here
      );

      final stats = await DiaryService.getMoodStatistics(
        _selectedPeriod,
        widget.patientId, // mood stats by uid
      );

      setState(() {
        _entries = entries;
        _currentStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // <-- white scaffold bg
      appBar: AppBar(
        backgroundColor: Colors.white, // <-- white appbar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistics',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadStatistics();
            },
            itemBuilder: (context) => _periods
                .map(
                  (period) =>
                      PopupMenuItem<String>(value: period, child: Text(period)),
                )
                .toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black87,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // <-- white body container (replaces gradient)
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, // <-- white card
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _entries.isEmpty
                        ? _buildNoDataView()
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                if (_currentStats != null &&
                                    _currentStats!.totalEntries > 0) ...[
                                  // Give the chart a fixed height so it lays out nicely
                                  SizedBox(
                                    child: MoodPieChart(
                                      data: _currentStats!.emotionPercentages,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No diary entries found for $_selectedPeriod',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing in your diary to see mood statistics!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
