import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';
import 'package:drivesense/domain/models/accident/accident.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:drivesense/ui/driving_history_analysis/view_model/analysis_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';

class DrivingAnalysisView extends StatefulWidget {
  final String drivingHistoryId;

  const DrivingAnalysisView({super.key, required this.drivingHistoryId});

  @override
  State<DrivingAnalysisView> createState() => _DrivingAnalysisViewState();
}

class _DrivingAnalysisViewState extends State<DrivingAnalysisView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        final drivingHistory = viewModel.getDrivingHistoryById(
          widget.drivingHistoryId,
        );

        if (drivingHistory == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Driving Analysis'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            body: const Center(child: Text('Driving session not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Driving Analysis',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing not implemented')),
                  );
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDrivingSummary(context, drivingHistory, viewModel),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A237E),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1A237E),
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'TIMELINE'),
                  Tab(text: 'STATS'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context, drivingHistory, viewModel),
                    _buildTimelineTab(context, drivingHistory, viewModel),
                    _buildStatsTab(context, drivingHistory, viewModel),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNavBar(
            currentRoute: '/driving_history',
          ),
        );
      },
    );
  }

  Widget _buildDrivingSummary(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.formatDate(history.startTime),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '${viewModel.formatTime(history.startTime)} - ${viewModel.formatTime(history.endTime)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                viewModel.getFormattedDuration(history),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '${history.riskyBehaviour.length}',
                'Alerts',
                Icons.warning_amber,
                Colors.amber,
              ),
              _buildSummaryItem(
                '${history.accident.length}',
                'Accidents',
                Icons.car_crash,
                Colors.red,
              ),
              _buildSummaryItem(
                viewModel.calculateRiskScore(history).toString(),
                'Risk Score',
                Icons.speed,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String value,
    String label,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Risk Analysis'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRiskChart(history),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.getRiskAnalysis(history),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (history.riskyBehaviour.isNotEmpty) ...[
            _buildSectionHeader('Risk Alerts'),
            _buildRiskyBehaviorOverview(history.riskyBehaviour),
          ],

          if (history.accident.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Accident Details'),
            _buildAccidentOverview(history.accident),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineTab(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
  ) {
    // Combine accidents and risky behaviors into a single timeline
    final events = <Map<String, dynamic>>[];

    for (var behavior in history.riskyBehaviour) {
      events.add({
        'time': behavior.delectedTime,
        'type': 'behavior',
        'data': behavior,
      });
    }

    for (var accident in history.accident) {
      events.add({
        'time': accident.delectedTime,
        'type': 'accident',
        'data': accident,
      });
    }

    // Sort events by time
    events.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final time = event['time'] as DateTime;
        final type = event['type'] as String;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: type == 'accident' ? Colors.red : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      type == 'accident' ? Icons.car_crash : Icons.warning,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
                if (index != events.length - 1)
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.grey.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('h:mm a').format(time),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: type == 'accident' ? Colors.red : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Card(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child:
                          type == 'accident'
                              ? _buildAccidentTimelineItem(
                                event['data'] as Accident,
                              )
                              : _buildRiskyBehaviorTimelineItem(
                                event['data'] as RiskyBehaviour,
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsTab(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
  ) {
    // Calculate behavior types count
    final behaviorTypeCounts = <String, int>{};
    for (var behavior in history.riskyBehaviour) {
      final type = behavior.behaviourType;
      behaviorTypeCounts[type] = (behaviorTypeCounts[type] ?? 0) + 1;
    }

    final pieChartData =
        behaviorTypeCounts.entries
            .map(
              (entry) => PieChartSectionData(
                value: entry.value.toDouble(),
                title: '${entry.value}',
                color: _getBehaviorTypeColor(entry.key),
                radius: 60,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (behaviorTypeCounts.isNotEmpty) ...[
            _buildSectionHeader('Risk Behavior Distribution'),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: pieChartData,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            ...behaviorTypeCounts.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getBehaviorTypeColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No risk behaviors detected during this drive',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 24),

          _buildSectionHeader('Session Metrics'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetricRow(
                    'Duration',
                    viewModel.getFormattedDuration(history),
                  ),
                  _buildMetricRow(
                    'Risk Alerts',
                    '${history.riskyBehaviour.length}',
                  ),
                  _buildMetricRow('Accidents', '${history.accident.length}'),
                  _buildMetricRow(
                    'Risk Score',
                    viewModel.calculateRiskScore(history).toString(),
                  ),
                  _buildMetricRow(
                    'Start Time',
                    viewModel.formatTime(history.startTime),
                  ),
                  _buildMetricRow(
                    'End Time',
                    viewModel.formatTime(history.endTime),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _buildRiskChart(DrivingHistory history) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${_calculateOverallRisk(history)}%',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              sections: [
                PieChartSectionData(
                  value: _calculateOverallRisk(history).toDouble(),
                  color: _getRiskColor(
                    _calculateOverallRisk(history).toDouble(),
                  ),
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - _calculateOverallRisk(history).toDouble(),
                  color: Colors.grey.shade200,
                  radius: 20,
                  showTitle: false,
                ),
              ],
              centerSpaceRadius: 80,
              sectionsSpace: 0,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateOverallRisk(DrivingHistory history) {
    // Calculate risk percentage based on alerts and duration
    final durationMinutes =
        history.endTime.difference(history.startTime).inMinutes;
    if (durationMinutes == 0) return 0;

    // More alerts in shorter time = higher risk
    final alertsPerHour =
        (history.riskyBehaviour.length * 60) / durationMinutes;

    // Convert to percentage with max value capped
    int riskPercentage = (alertsPerHour * 20).round();
    if (history.accident.isNotEmpty) {
      riskPercentage += 20; // Add 20% for each accident
    }

    return riskPercentage.clamp(0, 100);
  }

  Color _getRiskColor(double risk) {
    if (risk < 30) return Colors.green;
    if (risk < 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRiskyBehaviorOverview(List<RiskyBehaviour> behaviors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              behaviors.map((behavior) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getRiskyBehaviorIcon(behavior.behaviourType),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              behavior.behaviourType,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(behavior.delectedTime),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Alert: ${behavior.alertTypeName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildAccidentOverview(List<Accident> accidents) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              accidents.map((accident) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.car_crash, color: Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accident at ${accident.location}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(accident.delectedTime),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Emergency Contact: ${accident.contactNum}'),
                            Text('Response Time: ${accident.contactTime}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildRiskyBehaviorTimelineItem(RiskyBehaviour behavior) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getRiskyBehaviorIcon(behavior.behaviourType),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                behavior.behaviourType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Alert Type: ${behavior.alertTypeName}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccidentTimelineItem(Accident accident) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accident Detected',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 8),
        Text('Location: ${accident.location}'),
        Text('Emergency Contact: ${accident.contactNum}'),
        Text('Response Time: ${accident.contactTime}'),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _getRiskyBehaviorIcon(String behaviourType) {
    IconData iconData;
    Color iconColor;

    switch (behaviourType.toLowerCase()) {
      case 'drowsiness':
        iconData = Icons.bedtime_outlined;
        iconColor = Colors.purple;
        break;
      case 'distraction':
        iconData = Icons.phone_android;
        iconColor = Colors.blue;
        break;
      case 'intoxication':
        iconData = Icons.local_bar;
        iconColor = Colors.red;
        break;
      case 'phone usage':
        iconData = Icons.smartphone;
        iconColor = Colors.orange;
        break;
      case 'distress':
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.warning_amber;
        iconColor = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  Color _getBehaviorTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'drowsiness':
        return Colors.purple;
      case 'distraction':
        return Colors.blue;
      case 'intoxication':
        return Colors.red;
      case 'phone usage':
        return Colors.orange;
      case 'distress':
        return Colors.red.shade700;
      default:
        return Colors.amber;
    }
  }
}
