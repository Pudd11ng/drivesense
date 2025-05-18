import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';
import 'package:drivesense/domain/models/accident/accident.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:drivesense/ui/driving_history_analysis/view_model/analysis_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return Consumer<AnalysisViewModel>(
      builder: (context, viewModel, child) {
        final drivingHistory = viewModel.getDrivingHistoryById(
          widget.drivingHistoryId,
        );

        if (drivingHistory == null) {
          return Scaffold(
            appBar: AppHeaderBar(
              title: 'Driving Analysis',
              leading: Icon(Icons.arrow_back),
              onLeadingPressed: () => context.pop(),
            ),
            body: Center(
              child: Text(
                'Driving session not found',
                style: TextStyle(color: textColor),
              ),
            ),
            backgroundColor: backgroundColor,
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppHeaderBar(
            title: 'Driving Analysis',
            leading: Icon(Icons.arrow_back),
            onLeadingPressed: () => context.pop(),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: accentColor),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sharing not implemented'),
                      backgroundColor: accentColor,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDrivingSummary(context, drivingHistory, viewModel, isDarkMode),
              TabBar(
                controller: _tabController,
                labelColor: accentColor,
                unselectedLabelColor: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                indicatorColor: accentColor,
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
                    _buildOverviewTab(context, drivingHistory, viewModel, isDarkMode),
                    _buildTimelineTab(context, drivingHistory, viewModel, isDarkMode),
                    _buildStatsTab(context, drivingHistory, viewModel, isDarkMode),
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
    bool isDarkMode,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [AppColors.darkBlue, AppColors.blue.withValues(alpha: 0.8)]
              : [AppColors.darkBlue, AppColors.blue],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withValues(alpha: 0.1),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                '${viewModel.formatTime(history.startTime)} - ${viewModel.formatTime(history.endTime)}',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer, color: AppColors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                viewModel.getFormattedDuration(history),
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                '${history.riskyBehaviour.length}',
                'Alerts',
                Icons.warning_amber,
                Colors.amber,
              ),
              _buildSummaryItem(
                context,
                '${history.accident.length}',
                'Accidents',
                Icons.car_crash,
                Colors.red,
              ),
              _buildSummaryItem(
                context,
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
    BuildContext context,
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
            color: iconColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.9),
              ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
    bool isDarkMode,
  ) {
    final cardColor = isDarkMode ? AppColors.darkGrey.withValues(alpha: 0.3) : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Risk Analysis', accentColor, textColor),
          Card(
            color: cardColor,
            elevation: isDarkMode ? 0 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isDarkMode
                  ? BorderSide(color: AppColors.greyBlue.withValues(alpha: 0.2))
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRiskChart(history, textColor, isDarkMode),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.getRiskAnalysis(history),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (history.riskyBehaviour.isNotEmpty) ...[
            _buildSectionHeader('Risk Alerts', accentColor, textColor),
            _buildRiskyBehaviorOverview(history.riskyBehaviour, context, isDarkMode),
          ],

          if (history.accident.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Accident Details', accentColor, textColor),
            _buildAccidentOverview(history.accident, context, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineTab(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
    bool isDarkMode,
  ) {
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final cardColor = isDarkMode ? AppColors.darkGrey.withValues(alpha: 0.3) : AppColors.white;

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

    return events.isEmpty
        ? Center(
            child: Text(
              'No events recorded for this drive',
              style: TextStyle(color: textColor),
            ),
          )
        : ListView.builder(
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
                            color: AppColors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      if (index != events.length - 1)
                        Container(
                          width: 2,
                          height: 50,
                          color: isDarkMode
                              ? AppColors.greyBlue.withValues(alpha: 0.3)
                              : AppColors.grey.withValues(alpha: 0.3),
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
                            color: type == 'accident' ? Colors.red : textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Card(
                          elevation: isDarkMode ? 0 : 1,
                          color: cardColor,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: isDarkMode
                                ? BorderSide(
                                    color: AppColors.greyBlue.withValues(alpha: 0.2),
                                  )
                                : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: type == 'accident'
                                ? _buildAccidentTimelineItem(
                                    event['data'] as Accident,
                                    textColor,
                                  )
                                : _buildRiskyBehaviorTimelineItem(
                                    event['data'] as RiskyBehaviour,
                                    textColor,
                                    context,
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
    bool isDarkMode,
  ) {
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final cardColor = isDarkMode ? AppColors.darkGrey.withValues(alpha: 0.3) : AppColors.white;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;
    final secondaryTextColor = isDarkMode ? AppColors.greyBlue : AppColors.grey;

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
                color: _getBehaviorTypeColor(entry.key, isDarkMode),
                radius: 60,
                titleStyle: const TextStyle(
                  color: AppColors.white,
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
            _buildSectionHeader('Risk Behavior Distribution', accentColor, textColor),
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
                        color: _getBehaviorTypeColor(entry.key, isDarkMode),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No risk behaviors detected during this drive',
                  style: TextStyle(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 24),

          _buildSectionHeader('Session Metrics', accentColor, textColor),
          Card(
            elevation: isDarkMode ? 0 : 2,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isDarkMode
                  ? BorderSide(color: AppColors.greyBlue.withValues(alpha: 0.2))
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMetricRow(
                    'Duration',
                    viewModel.getFormattedDuration(history),
                    textColor,
                    secondaryTextColor,
                  ),
                  _buildMetricRow(
                    'Risk Alerts',
                    '${history.riskyBehaviour.length}',
                    textColor,
                    secondaryTextColor,
                  ),
                  _buildMetricRow(
                    'Accidents',
                    '${history.accident.length}',
                    textColor,
                    secondaryTextColor,
                  ),
                  _buildMetricRow(
                    'Risk Score',
                    viewModel.calculateRiskScore(history).toString(),
                    textColor,
                    secondaryTextColor,
                  ),
                  _buildMetricRow(
                    'Start Time',
                    viewModel.formatTime(history.startTime),
                    textColor,
                    secondaryTextColor,
                  ),
                  _buildMetricRow(
                    'End Time',
                    viewModel.formatTime(history.endTime),
                    textColor,
                    secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
      ),
    );
  }

  Widget _buildRiskChart(DrivingHistory history, Color textColor, bool isDarkMode) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${_calculateOverallRisk(history)}%',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              sections: [
                PieChartSectionData(
                  value: _calculateOverallRisk(history).toDouble(),
                  color: _getRiskColor(
                    _calculateOverallRisk(history).toDouble(),
                    isDarkMode,
                  ),
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - _calculateOverallRisk(history).toDouble(),
                  color: isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
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

  Color _getRiskColor(double risk, bool isDarkMode) {
    if (risk < 30) return isDarkMode ? Colors.green.shade400 : Colors.green;
    if (risk < 70) return isDarkMode ? Colors.orange.shade300 : Colors.orange;
    return isDarkMode ? Colors.red.shade300 : Colors.red;
  }

  Widget _buildRiskyBehaviorOverview(
    List<RiskyBehaviour> behaviors,
    BuildContext context,
    bool isDarkMode,
  ) {
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final cardColor = isDarkMode ? AppColors.darkGrey.withValues(alpha: 0.3) : AppColors.white;
    final secondaryTextColor = isDarkMode ? AppColors.greyBlue : AppColors.grey;

    return Card(
      elevation: isDarkMode ? 0 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDarkMode
            ? BorderSide(color: AppColors.greyBlue.withValues(alpha: 0.2))
            : BorderSide.none,
      ),
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
                      _getRiskyBehaviorIcon(behavior.behaviourType, isDarkMode),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              behavior.behaviourType,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(behavior.delectedTime),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor,
                                  ),
                            ),
                            Text(
                              'Alert: ${behavior.alertTypeName}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: textColor,
                                  ),
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

  Widget _buildAccidentOverview(
    List<Accident> accidents,
    BuildContext context,
    bool isDarkMode,
  ) {
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final cardColor = isDarkMode ? AppColors.darkGrey.withValues(alpha: 0.3) : AppColors.white;
    final secondaryTextColor = isDarkMode ? AppColors.greyBlue : AppColors.grey;

    return Card(
      elevation: isDarkMode ? 0 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDarkMode
            ? BorderSide(color: AppColors.greyBlue.withValues(alpha: 0.2))
            : BorderSide.none,
      ),
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
                          color: Colors.red.withValues(alpha: 0.1),
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(accident.delectedTime),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Emergency Contact: ${accident.contactNum}',
                              style: TextStyle(color: textColor),
                            ),
                            Text(
                              'Response Time: ${accident.contactTime}',
                              style: TextStyle(color: textColor),
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

  Widget _buildRiskyBehaviorTimelineItem(
    RiskyBehaviour behavior,
    Color textColor,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getRiskyBehaviorIcon(behavior.behaviourType, Theme.of(context).brightness == Brightness.dark),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                behavior.behaviourType,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Alert Type: ${behavior.alertTypeName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccidentTimelineItem(Accident accident, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accident Detected',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text('Location: ${accident.location}', style: TextStyle(color: textColor)),
        Text('Emergency Contact: ${accident.contactNum}', style: TextStyle(color: textColor)),
        Text('Response Time: ${accident.contactTime}', style: TextStyle(color: textColor)),
      ],
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getRiskyBehaviorIcon(String behaviourType, bool isDarkMode) {
    IconData iconData;
    Color iconColor;

    switch (behaviourType.toLowerCase()) {
      case 'drowsiness':
        iconData = Icons.bedtime_outlined;
        iconColor = isDarkMode ? Colors.purple.shade300 : Colors.purple;
        break;
      case 'distraction':
        iconData = Icons.phone_android;
        iconColor = isDarkMode ? Colors.blue.shade300 : Colors.blue;
        break;
      case 'intoxication':
        iconData = Icons.local_bar;
        iconColor = isDarkMode ? Colors.red.shade300 : Colors.red;
        break;
      case 'phone usage':
        iconData = Icons.smartphone;
        iconColor = isDarkMode ? Colors.orange.shade300 : Colors.orange;
        break;
      case 'distress':
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = isDarkMode ? Colors.red.shade300 : Colors.red;
        break;
      default:
        iconData = Icons.warning_amber;
        iconColor = isDarkMode ? Colors.amber.shade300 : Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  Color _getBehaviorTypeColor(String type, bool isDarkMode) {
    switch (type.toLowerCase()) {
      case 'drowsiness':
        return isDarkMode ? Colors.purple.shade300 : Colors.purple;
      case 'distraction':
        return isDarkMode ? Colors.blue.shade300 : Colors.blue;
      case 'intoxication':
        return isDarkMode ? Colors.red.shade300 : Colors.red;
      case 'phone usage':
        return isDarkMode ? Colors.orange.shade300 : Colors.orange;
      case 'distress':
        return isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
      default:
        return isDarkMode ? Colors.amber.shade300 : Colors.amber;
    }
  }
}
