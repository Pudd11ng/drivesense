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
    _tabController = TabController(length: 2, vsync: this); // Changed to 2 tabs
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
              leading: const Icon(Icons.arrow_back),
              onLeadingPressed: () => context.go('/driving_history'),
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
            leading: const Icon(Icons.arrow_back),
            onLeadingPressed: () => context.go('/driving_history'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDrivingSummary(
                context,
                drivingHistory,
                viewModel,
                isDarkMode,
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.black : AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackTransparent.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: accentColor,
                  unselectedLabelColor:
                      isDarkMode ? AppColors.greyBlue : AppColors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  indicator: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: accentColor, width: 3.0),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tabs: [
                    Tab(
                      height: 56,
                      icon: Icon(Icons.dashboard_outlined, size: 20),
                      text: 'OVERVIEW',
                      iconMargin: const EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      height: 56,
                      icon: Icon(Icons.timeline_outlined, size: 20),
                      text: 'TIMELINE',
                      iconMargin: const EdgeInsets.only(bottom: 4),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                      context,
                      drivingHistory,
                      viewModel,
                      isDarkMode,
                    ),
                    _buildTimelineTab(
                      context,
                      drivingHistory,
                      viewModel,
                      isDarkMode,
                    ),
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
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: isDarkMode ? 4 : 6,
      shadowColor: AppColors.blackTransparent.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDarkMode
                    ? [
                      AppColors.darkBlue,
                      AppColors.blue.withValues(alpha: 0.7),
                    ]
                    : [AppColors.darkBlue, AppColors.blue],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: 30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        viewModel.formatDate(history.startTime),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    viewModel.formatTime(history.startTime),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duration',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    viewModel.getFormattedDuration(history),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.flag_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    viewModel.formatTime(history.endTime),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedSummaryItem(
                          context,
                          '${history.riskyBehaviour.length}',
                          'Risk Alerts',
                          Icons.warning_amber,
                          Colors.amber,
                          history.riskyBehaviour.isNotEmpty,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildEnhancedSummaryItem(
                          context,
                          '${history.accident.length}',
                          'Accidents',
                          Icons.car_crash,
                          Colors.redAccent,
                          history.accident.isNotEmpty,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSummaryItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color iconColor,
    bool hasItems,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color:
            hasItems
                ? iconColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hasItems
                  ? iconColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  hasItems
                      ? iconColor.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    DrivingHistory history,
    AnalysisViewModel viewModel,
    bool isDarkMode,
  ) {
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final cardColor =
        isDarkMode
            ? AppColors.darkGrey.withValues(alpha: 0.3)
            : AppColors.white;
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
          _buildSectionHeader('Session Metrics', accentColor, textColor),
          Card(
            elevation: isDarkMode ? 0 : 2,
            color: cardColor,
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side:
                  isDarkMode
                      ? BorderSide(
                        color: AppColors.greyBlue.withValues(alpha: 0.2),
                      )
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

          // Behavior Distribution Chart
          if (behaviorTypeCounts.isNotEmpty) ...[
            _buildSectionHeader(
              'Risk Behavior Distribution',
              accentColor,
              textColor,
            ),
            Card(
              elevation: isDarkMode ? 0 : 2,
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    isDarkMode
                        ? BorderSide(
                          color: AppColors.greyBlue.withValues(alpha: 0.2),
                        )
                        : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
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
                                color: _getBehaviorTypeColor(
                                  entry.key,
                                  isDarkMode,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key}: ${entry.value}',
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Accidents List
          if (history.accident.isNotEmpty) ...[
            _buildSectionHeader('Accident Details', accentColor, textColor),
            Card(
              elevation: isDarkMode ? 0 : 2,
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    isDarkMode
                        ? BorderSide(
                          color: AppColors.greyBlue.withValues(alpha: 0.2),
                        )
                        : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      history.accident.map((accident) {
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
                                child: const Icon(
                                  Icons.car_crash,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Accident at ${accident.location}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'h:mm a',
                                      ).format(accident.detectedTime),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: secondaryTextColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Emergency Contact: ${accident.contactNum}',
                                      style: TextStyle(color: textColor),
                                    ),
                                    Text(
                                      'Response Time: ${viewModel.formatDate(accident.contactTime)}',
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
            ),
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
    final cardColor =
        isDarkMode
            ? AppColors.darkGrey.withValues(alpha: 0.3)
            : AppColors.white;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    final events = <Map<String, dynamic>>[];

    for (var behavior in history.riskyBehaviour) {
      events.add({
        'time': behavior.detectedTime,
        'type': 'behavior',
        'data': behavior,
      });
    }

    for (var accident in history.accident) {
      events.add({
        'time': accident.detectedTime,
        'type': 'accident',
        'data': accident,
      });
    }

    events.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (events.isNotEmpty) ...[
            _buildSectionHeader('Timeline Graph', accentColor, textColor),
            _buildTimelineGraph(history, events, isDarkMode),
            const SizedBox(height: 24),
          ],

          _buildSectionHeader('Event Timeline', accentColor, textColor),
          events.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No events recorded for this drive',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                              color:
                                  type == 'accident'
                                      ? Colors.red
                                      : Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                type == 'accident'
                                    ? Icons.car_crash
                                    : Icons.warning,
                                color: AppColors.white,
                                size: 12,
                              ),
                            ),
                          ),
                          if (index != events.length - 1)
                            Container(
                              width: 2,
                              height: 50,
                              color:
                                  isDarkMode
                                      ? AppColors.greyBlue.withValues(
                                        alpha: 0.3,
                                      )
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
                                color:
                                    type == 'accident' ? Colors.red : textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Card(
                              elevation: isDarkMode ? 0 : 1,
                              color: cardColor,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side:
                                    isDarkMode
                                        ? BorderSide(
                                          color: AppColors.greyBlue.withValues(
                                            alpha: 0.2,
                                          ),
                                        )
                                        : BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child:
                                    type == 'accident'
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
              ),
        ],
      ),
    );
  }

  Widget _buildTimelineGraph(
    DrivingHistory history,
    List<Map<String, dynamic>> events,
    bool isDarkMode,
  ) {
    final cardColor =
        isDarkMode
            ? AppColors.darkGrey.withValues(alpha: 0.3)
            : AppColors.white;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;
    final gridColor =
        isDarkMode
            ? AppColors.greyBlue.withValues(alpha: 0.15)
            : AppColors.grey.withValues(alpha: 0.15);
    final labelColor = isDarkMode ? AppColors.greyBlue : AppColors.grey;

    // Calculate total duration in minutes for the X axis
    final totalDuration =
        history.endTime.difference(history.startTime).inMinutes;

    // Create reference times for the x-axis (actual times)
    final startTimeInMinutes =
        history.startTime.hour * 60 + history.startTime.minute;

    // Group events by actual time and count occurrences
    final Map<int, int> eventCountsByMinute = {};
    int maxCount = 0;

    for (var event in events) {
      final eventTime = event['time'] as DateTime;
      final eventAbsoluteMinute = eventTime.hour * 60 + eventTime.minute;

      // Increment count for this minute
      eventCountsByMinute[eventAbsoluteMinute] =
          (eventCountsByMinute[eventAbsoluteMinute] ?? 0) + 1;

      // Track max count for Y-axis scaling
      if (eventCountsByMinute[eventAbsoluteMinute]! > maxCount) {
        maxCount = eventCountsByMinute[eventAbsoluteMinute]!;
      }
    }

    // Create spots for the chart using actual time values (minutes from midnight)
    final spots =
        eventCountsByMinute.entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.toDouble());
        }).toList();

    // Sort by X value (time)
    spots.sort((a, b) => a.x.compareTo(b.x));

    // Calculate appropriate max Y value
    final maxY = maxCount > 3 ? (maxCount + 1).toDouble() : 3.0;

    // Calculate min and max X values for the chart (in minutes from midnight)
    // Ensure a minimum 10-minute span for the x-axis
    final effectiveDuration = totalDuration < 10 ? 10 : totalDuration;

    // If total duration is less than 10 minutes, center the events in a 10-minute window
    final additionalMinutes = effectiveDuration - totalDuration;
    final minX = (startTimeInMinutes - (5 + additionalMinutes / 2)).toDouble();
    final maxX =
        (startTimeInMinutes + totalDuration + (5 + additionalMinutes / 2))
            .toDouble();

    return Card(
      elevation: isDarkMode ? 0 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isDarkMode
                ? BorderSide(color: AppColors.greyBlue.withValues(alpha: 0.2))
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTimelineLegendItem(
                  'Risk Events',
                  accentColor,
                  isDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final minutesFromMidnight = touchedSpot.x.toInt();
                          final count = touchedSpot.y.toInt();

                          // Convert back to DateTime for display
                          final hour = minutesFromMidnight ~/ 60;
                          final minute = minutesFromMidnight % 60;
                          final time = DateTime(
                            history.startTime.year,
                            history.startTime.month,
                            history.startTime.day,
                            hour,
                            minute,
                          );

                          return LineTooltipItem(
                            '${DateFormat('h:mm a').format(time)}: $count ${count == 1 ? 'event' : 'events'}',
                            TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1, // Every 1 count
                    verticalInterval: 5, // Every 5 minutes
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: gridColor, strokeWidth: 1);
                    },
                    getDrawingVerticalLine: (value) {
                      // Only draw lines at 5-minute intervals
                      if (value % 5 == 0) {
                        return FlLine(color: gridColor, strokeWidth: 1);
                      }
                      return FlLine(color: Colors.transparent);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          // Only show integer values
                          if (value % 1 != 0) return const SizedBox();

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(color: labelColor, fontSize: 10),
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          // Only show at 5-minute intervals
                          if (value % 5 != 0) return const SizedBox();

                          final absoluteMinute = value.toInt();
                          final hour = absoluteMinute ~/ 60;
                          final minute = absoluteMinute % 60;

                          // Create a datetime for formatting
                          final time = DateTime(
                            history.startTime.year,
                            history.startTime.month,
                            history.startTime.day,
                            hour,
                            minute,
                          );

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat('h:mm').format(time),
                              style: TextStyle(fontSize: 10, color: labelColor),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color:
                          isDarkMode
                              ? AppColors.greyBlue.withValues(alpha: 0.2)
                              : AppColors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: accentColor,
                            strokeWidth: 2,
                            strokeColor:
                                isDarkMode ? Colors.black : Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineLegendItem(String label, Color color, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
          ),
        ),
      ],
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

  Widget _buildRiskyBehaviorTimelineItem(
    RiskyBehaviour behavior,
    Color textColor,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getRiskyBehaviorIcon(
          behavior.behaviourType,
          Theme.of(context).brightness == Brightness.dark,
        ),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: textColor),
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 8),
        Text(
          'Location: ${accident.location}',
          style: TextStyle(color: textColor),
        ),
        Text(
          'Emergency Contact: ${accident.contactNum}',
          style: TextStyle(color: textColor),
        ),
        Text(
          'Response Time: ${accident.contactTime}',
          style: TextStyle(color: textColor),
        ),
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
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
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
